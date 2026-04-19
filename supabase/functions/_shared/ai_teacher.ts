import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getAuthUserId, getGuestToken } from "./guest_access.ts";

export type AccessLevel = "basic" | "premium";

export type ReviewPayload = {
  review_id: string;
  status: "ready";
  modality: "objective" | "writing" | "speaking";
  source: string;
  verdict: "correct" | "incorrect" | "needs_retry" | "partial";
  summary: string;
  reinforcement: string;
  criteria: Array<Record<string, unknown>>;
  mistakes: Array<Record<string, unknown>>;
  suggestions: Array<Record<string, unknown>>;
  corrected_answer: string;
  artifacts: {
    transcript?: string;
    annotated_spans?: Array<Record<string, unknown>>;
    transcript_issues?: Array<Record<string, unknown>>;
    short_tips?: string[];
  };
};

export async function getRequesterContext(
  supabase: SupabaseClient,
  req: Request,
): Promise<
  { userId: string | null; guestToken: string | null; accessLevel: AccessLevel }
> {
  const userId = await getAuthUserId(supabase, req);
  const guestToken = getGuestToken(req);
  if (!userId) {
    return { userId: null, guestToken, accessLevel: "basic" };
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("subscription_tier, subscription_expires_at")
    .eq("id", userId)
    .maybeSingle();

  const tier =
    ((profile as Record<string, unknown> | null)?.["subscription_tier"] as
      | string
      | null) ?? "free";
  const expiresAt = (profile as Record<string, unknown> | null)
    ?.["subscription_expires_at"] as string | null;
  const isPremium = tier === "premium" &&
    (!expiresAt || new Date(expiresAt).getTime() > Date.now());

  return {
    userId,
    guestToken,
    accessLevel: isPremium ? "premium" : "basic",
  };
}

export function filterReviewPayload(
  payload: ReviewPayload,
  accessLevel: AccessLevel,
): Record<string, unknown> {
  if (accessLevel === "premium") {
    return {
      ...payload,
      is_premium: true,
    };
  }

  return {
    review_id: payload.review_id,
    status: payload.status,
    modality: payload.modality,
    source: payload.source,
    verdict: payload.verdict,
    summary: payload.summary,
    reinforcement: payload.reinforcement,
    criteria: [],
    mistakes: payload.mistakes.slice(0, 2),
    suggestions: payload.suggestions.slice(0, 2),
    corrected_answer: "",
    artifacts: {
      short_tips: (payload.artifacts.short_tips ?? []).slice(0, 2),
      transcript: "",
      annotated_spans: [],
      transcript_issues: [],
    },
    is_premium: false,
  };
}

export function buildWritingReviewPayload(args: {
  reviewId: string;
  source: string;
  row: Record<string, unknown>;
}): ReviewPayload {
  const { reviewId, source, row } = args;
  const metrics = (row["metrics"] as Record<string, unknown> | null) ?? {};
  const spans = ((row["grammar_notes"] as unknown[]) ?? [])
    .map((item) => item as Record<string, unknown>);
  const shortTips = ((metrics["short_tips"] as string[]) ?? []).slice(0, 5);
  const score = Number(row["overall_score"] ?? 0);

  const criteria = [
    buildCriterion(
      "Ngữ pháp",
      metrics["grammar"],
      100,
      metrics["grammar_feedback"],
    ),
    buildCriterion(
      "Từ vựng",
      metrics["vocabulary"],
      100,
      metrics["vocabulary_feedback"],
    ),
    buildCriterion(
      "Mạch lạc & hình thức",
      metrics["coherence"],
      100,
      metrics["format_feedback"],
    ),
    buildCriterion(
      "Nội dung",
      metrics["task_achievement"],
      100,
      metrics["content_feedback"],
    ),
  ].filter(Boolean) as Array<Record<string, unknown>>;

  const mistakes = spans
    .filter((span) => span["issue_type"])
    .map((span) => ({
      title: writingIssueTitle(span["issue_type"] as string | null),
      explanation: String(span["explanation"] ?? ""),
      correction: String(span["correction"] ?? ""),
      tip: String(span["tip"] ?? ""),
    }))
    .filter((item) => item.explanation.length > 0);

  const suggestions = shortTips.map((tip, index) => ({
    title: `Gợi ý ${index + 1}`,
    detail: tip,
  }));

  return {
    review_id: reviewId,
    status: "ready",
    modality: "writing",
    source,
    verdict: verdictFromScore(score),
    summary: String(metrics["overall_feedback"] ?? ""),
    reinforcement: "",
    criteria,
    mistakes,
    suggestions,
    corrected_answer: String(row["corrected_essay"] ?? ""),
    artifacts: {
      annotated_spans: spans,
      short_tips: shortTips,
    },
  };
}

export function buildSpeakingReviewPayload(args: {
  reviewId: string;
  source: string;
  row: Record<string, unknown>;
}): ReviewPayload {
  const { reviewId, source, row } = args;
  const metrics = (row["metrics"] as Record<string, unknown> | null) ?? {};
  const issues = ((row["issues"] as unknown[]) ?? [])
    .map((item) => item as Record<string, unknown>);
  const shortTips = ((metrics["short_tips"] as string[]) ?? []).slice(0, 5);
  const score = Number(row["overall_score"] ?? 0);
  const summary = String(metrics["overall_feedback"] ?? "");
  const needsRetry = score == 0 && summary.toLowerCase().includes("tiếng séc");

  const criteria = [
    buildCriterion(
      "Phát âm",
      metrics["pronunciation"],
      100,
      metrics["pronunciation_feedback"],
      metrics["pronunciation_tip"],
    ),
    buildCriterion(
      "Lưu loát",
      metrics["fluency"],
      100,
      metrics["fluency_feedback"],
      metrics["fluency_tip"],
    ),
    buildCriterion(
      "Từ vựng",
      metrics["vocabulary"],
      100,
      metrics["vocabulary_feedback"],
      metrics["vocabulary_tip"],
    ),
    buildCriterion(
      "Nội dung & ngữ pháp",
      metrics["task_achievement"],
      100,
      metrics["content_feedback"] ?? metrics["grammar_feedback"],
      metrics["content_tip"] ?? metrics["grammar_tip"],
    ),
  ].filter(Boolean) as Array<Record<string, unknown>>;

  let mistakes = issues.map((issue) => ({
    title: speakingIssueTitle(issue["type"] as string | null),
    explanation: String(issue["word"] ?? issue["token"] ?? ""),
    correction: String(issue["suggestion"] ?? ""),
    tip: "",
  })).filter((item) => item.explanation.length > 0);

  if (mistakes.length === 0) {
    mistakes = criteria
      .map((criterion) => ({
        title: String(criterion["title"] ?? ""),
        explanation: String(criterion["feedback"] ?? ""),
        correction: "",
        tip: String(criterion["tip"] ?? ""),
      }))
      .filter((item) => item.explanation.length > 0);
  }

  const suggestions = shortTips.map((tip, index) => ({
    title: `Gợi ý ${index + 1}`,
    detail: tip,
  }));

  return {
    review_id: reviewId,
    status: "ready",
    modality: "speaking",
    source,
    verdict: needsRetry ? "needs_retry" : verdictFromScore(score),
    summary,
    reinforcement: "",
    criteria: needsRetry ? [] : criteria,
    mistakes,
    suggestions,
    corrected_answer: String(row["corrected_answer"] ?? ""),
    artifacts: {
      transcript: String(row["transcript"] ?? ""),
      transcript_issues: issues.map((issue) => ({
        token: String(issue["word"] ?? ""),
        issue: String(issue["type"] ?? "pronunciation"),
        suggestion: String(issue["suggestion"] ?? ""),
      })),
      short_tips: shortTips,
    },
  };
}

function buildCriterion(
  title: string,
  score: unknown,
  maxScore: number,
  feedback: unknown,
  tip?: unknown,
): Record<string, unknown> | null {
  const numeric = Number(score ?? NaN);
  const feedbackText = String(feedback ?? "");
  const tipText = String(tip ?? "");
  if (
    !Number.isFinite(numeric) && feedbackText.length === 0 &&
    tipText.length === 0
  ) {
    return null;
  }

  return {
    "title": title,
    "score": Number.isFinite(numeric) ? numeric : null,
    "max_score": Number.isFinite(numeric) ? maxScore : null,
    "feedback": feedbackText,
    "tip": tipText,
  };
}

function verdictFromScore(score: number): ReviewPayload["verdict"] {
  if (score >= 70) return "correct";
  if (score >= 40) return "partial";
  return "incorrect";
}

function writingIssueTitle(issueType: string | null): string {
  switch (issueType) {
    case "grammar":
      return "Lỗi ngữ pháp";
    case "vocabulary":
      return "Lỗi từ vựng";
    case "spelling":
      return "Lỗi chính tả";
    default:
      return "Điểm cần sửa";
  }
}

function speakingIssueTitle(issueType: string | null): string {
  switch (issueType) {
    case "grammar":
      return "Ngữ pháp khi nói";
    case "vocabulary":
      return "Từ vựng khi nói";
    default:
      return "Phát âm / diễn đạt";
  }
}
