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

type ReviewMistakeRecord = {
  title: string;
  explanation: string;
  correction: string;
  tip: string;
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
    mistakes: payload.mistakes,
    suggestions: payload.suggestions,
    corrected_answer: "",
    artifacts: {
      short_tips: payload.artifacts.short_tips,
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
  const isExamLike = source === "mock_test" || source === "simulator";
  const metrics = (row["metrics"] as Record<string, unknown> | null) ?? {};
  const issues = ((row["issues"] as unknown[]) ?? [])
    .map((item) => item as Record<string, unknown>);
  const shortTips = ((metrics["short_tips"] as string[]) ?? []).slice(0, 5);
  const majorIssues = toStringList(metrics["major_issues"], 2);
  const nextStepFocus = String(metrics["next_step_focus"] ?? "");
  const cefrEstimate = String(metrics["cefr_estimate"] ?? "");
  const confidence = String(metrics["confidence"] ?? "");
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
      "Ngữ pháp",
      null,
      100,
      metrics["grammar_feedback"],
      metrics["grammar_tip"],
    ),
    buildCriterion(
      "Đáp ứng yêu cầu",
      metrics["task_achievement"],
      100,
      metrics["content_feedback"] ?? metrics["grammar_feedback"],
      metrics["content_tip"] ?? metrics["grammar_tip"],
    ),
  ].filter(Boolean) as Array<Record<string, unknown>>;

  let mistakes: ReviewMistakeRecord[] = issues
    .slice()
    .sort(compareSpeakingIssues)
    .map((issue) => {
      const issueType = issue["type"] as string | null;
      const criterion = findCriterionForIssue(criteria, issueType);
      const severity = speakingSeverityLabel(
        issue["severity"] as string | null,
      );
      const token = String(issue["word"] ?? issue["token"] ?? "").trim();
      const explanation = String(issue["explanation"] ?? "").trim();

      return {
        title: severity.length > 0
          ? `${speakingIssueTitle(issueType)} (${severity})`
          : speakingIssueTitle(issueType),
        explanation: joinNonEmptyParts([
          explanation,
          token.length > 0 ? `Từ/cụm cần chú ý: "${token}".` : "",
        ]),
        correction: String(issue["suggestion"] ?? ""),
        tip: String(criterion?.["tip"] ?? ""),
      };
    })
    .filter((item) => item.explanation.length > 0);

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

  mistakes = enrichSpeakingMistakes({
    mistakes,
    criteria,
    majorIssues,
  });

  const suggestions = buildSpeakingSuggestions({
    shortTips,
    majorIssues,
    nextStepFocus,
    isExamLike,
  });

  const reinforcement = needsRetry ? "" : buildSpeakingReinforcement({
    criteria,
    majorIssues,
    cefrEstimate,
    confidence,
    isExamLike,
  });

  return {
    review_id: reviewId,
    status: "ready",
    modality: "speaking",
    source,
    verdict: needsRetry ? "needs_retry" : verdictFromScore(score),
    summary,
    reinforcement,
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
    case "pronunciation":
      return "Phát âm";
    case "grammar":
      return "Ngữ pháp khi nói";
    case "vocabulary":
      return "Từ vựng khi nói";
    default:
      return "Phát âm / diễn đạt";
  }
}

function toStringList(value: unknown, limit: number): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => String(item ?? "").trim())
    .filter((item) => item.length > 0)
    .slice(0, limit);
}

function joinNonEmptyParts(parts: string[]): string {
  return parts.map((part) => part.trim()).filter((part) => part.length > 0)
    .join(" ");
}

function speakingSeverityLabel(severity: string | null): string {
  switch (severity) {
    case "high":
      return "cần sửa trước";
    case "medium":
      return "ảnh hưởng rõ";
    case "low":
      return "nên chỉnh thêm";
    default:
      return "";
  }
}

function speakingIssuePriority(severity: string | null): number {
  switch (severity) {
    case "high":
      return 0;
    case "medium":
      return 1;
    case "low":
      return 2;
    default:
      return 3;
  }
}

function compareSpeakingIssues(
  left: Record<string, unknown>,
  right: Record<string, unknown>,
): number {
  return speakingIssuePriority(left["severity"] as string | null) -
    speakingIssuePriority(right["severity"] as string | null);
}

function findCriterionForIssue(
  criteria: Array<Record<string, unknown>>,
  issueType: string | null,
): Record<string, unknown> | null {
  const criterionTitle = issueType === "grammar"
    ? "Ngữ pháp"
    : issueType === "vocabulary"
    ? "Từ vựng"
    : "Phát âm";
  return criteria.find((criterion) => criterion["title"] === criterionTitle) ??
    null;
}

function enrichSpeakingMistakes(args: {
  mistakes: ReviewMistakeRecord[];
  criteria: Array<Record<string, unknown>>;
  majorIssues: string[];
}): ReviewMistakeRecord[] {
  const mistakes = [...args.mistakes];
  const existingExplanations = new Set(
    mistakes.map((mistake) => String(mistake["explanation"] ?? "").trim()),
  );

  const weakestCriteria = args.criteria
    .filter((criterion) =>
      typeof criterion["score"] === "number" &&
      String(criterion["feedback"] ?? "").trim().length > 0
    )
    .sort((left, right) =>
      Number(left["score"] ?? 0) - Number(right["score"] ?? 0)
    );

  for (const criterion of weakestCriteria) {
    if (mistakes.length >= 4) break;
    const explanation = String(criterion["feedback"] ?? "").trim();
    if (!explanation || existingExplanations.has(explanation)) continue;
    mistakes.push({
      title: String(criterion["title"] ?? "Điểm cần sửa"),
      explanation,
      correction: "",
      tip: String(criterion["tip"] ?? ""),
    });
    existingExplanations.add(explanation);
  }

  for (const issue of args.majorIssues) {
    if (mistakes.length >= 5) break;
    if (existingExplanations.has(issue)) continue;
    mistakes.push({
      title: "Vấn đề chính",
      explanation: issue,
      correction: "",
      tip: "",
    });
    existingExplanations.add(issue);
  }

  return mistakes;
}

function buildSpeakingSuggestions(args: {
  shortTips: string[];
  majorIssues: string[];
  nextStepFocus: string;
  isExamLike: boolean;
}): Array<Record<string, string>> {
  const suggestions: Array<Record<string, string>> = [];
  const seen = new Set<string>();

  const pushSuggestion = (title: string, detail: string) => {
    const normalizedDetail = detail.trim();
    if (!normalizedDetail || seen.has(normalizedDetail)) return;
    suggestions.push({ title, detail: normalizedDetail });
    seen.add(normalizedDetail);
  };

  if (args.nextStepFocus.trim().length > 0) {
    pushSuggestion(
      args.isExamLike ? "Trọng tâm lần sau" : "Trọng tâm luyện tập",
      args.nextStepFocus,
    );
  }

  for (const issue of args.majorIssues) {
    pushSuggestion("Ưu tiên sửa", issue);
  }

  for (const tip of args.shortTips) {
    pushSuggestion(
      `${args.isExamLike ? "Lưu ý" : "Gợi ý luyện"} ${suggestions.length + 1}`,
      tip,
    );
  }

  return suggestions;
}

function buildSpeakingReinforcement(args: {
  criteria: Array<Record<string, unknown>>;
  majorIssues: string[];
  cefrEstimate: string;
  confidence: string;
  isExamLike: boolean;
}): string {
  const strongestCriteria = args.criteria
    .filter((criterion) => typeof criterion["score"] === "number")
    .sort((left, right) =>
      Number(right["score"] ?? 0) - Number(left["score"] ?? 0)
    )
    .filter((criterion) => Number(criterion["score"] ?? 0) >= 65)
    .slice(0, 2)
    .map((criterion) => String(criterion["title"] ?? "").trim())
    .filter((title) => title.length > 0);

  const levelHint = args.cefrEstimate === "above_a2"
    ? "Bài nói hiện đã vượt mức tối thiểu A2."
    : args.cefrEstimate === "a2"
    ? "Bài nói đang ở quanh mức A2."
    : "";

  if (strongestCriteria.length > 0) {
    return joinNonEmptyParts([
      levelHint,
      args.isExamLike
        ? `Điểm làm tốt hơn cả hiện tại là ${strongestCriteria.join(" và ")}.`
        : `Bạn đang làm khá tốt ở ${strongestCriteria.join(" và ")}.`,
    ]);
  }

  if (
    levelHint.length > 0 && args.majorIssues.length <= 1 &&
    args.confidence !== "low"
  ) {
    return levelHint;
  }

  return "";
}
