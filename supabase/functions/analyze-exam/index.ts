import {
  createClient,
  type SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";
import {
  buildSpeakingReviewPayload,
  buildWritingReviewPayload,
} from "../_shared/ai_teacher.ts";
import { corsHeaders } from "../_shared/cors.ts";
import {
  chatComplete,
  getExamSynthesisModel,
  getOpenAIKey,
} from "../_shared/openai.ts";
import { VIETNAMESE_FEEDBACK_REQUIREMENT } from "../_shared/vietnamese.ts";
import { ensureVietnameseUserFacingJson } from "../_shared/vietnamese_guard.ts";
import {
  fetchOrGenerateQuestionFeedback,
  normalizeQuestionFeedbackType,
  type QuestionFeedbackRequest,
} from "../_shared/question_feedback.ts";
import { assertCanAccessExamAttempt } from "../_shared/guest_access.ts";

type JsonRecord = Record<string, unknown>;

interface SectionRow {
  id: string;
  skill: string;
  label: string;
  order_index: number;
}

interface QuestionOptionRow {
  id: string;
  text: string;
  is_correct: boolean;
  order_index: number;
}

interface QuestionRow {
  id: string;
  type: string;
  skill: string;
  prompt: string;
  explanation: string | null;
  correct_answer: string | null;
  section_id: string;
  order_index: number;
  question_options: QuestionOptionRow[];
}

interface StoredAnswer {
  question_id?: string;
  selected_option_id?: string | null;
  written_answer?: string | null;
  ai_attempt_id?: string | null;
}

interface ExamResultRow {
  total_score?: number | null;
  section_scores?: Record<string, unknown> | null;
  weak_skills?: string[] | null;
}

interface AnalysisQuestionContext {
  question: QuestionRow;
  section: SectionRow | null;
  number: number;
  storedAnswer: StoredAnswer | null;
}

interface AiAttemptRow {
  id: string;
  question_id: string | null;
  status: string | null;
  error_message?: string | null;
  overall_score?: number | null;
  metrics?: Record<string, unknown> | null;
  grammar_notes?: unknown[] | null;
  issues?: unknown[] | null;
  corrected_essay?: string | null;
  corrected_answer?: string | null;
  transcript?: string | null;
}

const SUBJECTIVE_WAIT_RETRIES = 10;
const SUBJECTIVE_WAIT_INTERVAL = 3_000;
const OBJECTIVE_CONCURRENCY = 5;
const OBJECTIVE_TIMEOUT_MS = 15_000;
const SYNTHESIS_TIMEOUT_MS = 20_000;
const SYNTHESIS_PROMPT = `
Bạn là AI Teacher tổng hợp kết quả bài thi tiếng Séc cho học viên người Việt đang luyện thi A2 Trvalý pobyt.

Nhiệm vụ:
1. Tóm tắt ngắn gọn điểm mạnh / điểm yếu theo từng kỹ năng có trong bài thi.
2. Đưa ra 3-5 gợi ý hành động cụ thể, ưu tiên việc học thực tế và dễ làm ngay.

Yêu cầu:
- Viết hoàn toàn bằng tiếng Việt.
- Dựa sát vào section_scores và feedback từng câu, không bịa chi tiết.
- "summary" mỗi kỹ năng: 1-2 câu.
- "main_issue": 1 câu, nêu vấn đề chính cần cải thiện nhất.
- "overall_recommendations": 3-5 mục, ngắn gọn nhưng cụ thể.

Trả về JSON:
{
  "skill_insights": {
    "reading": { "summary": "...", "main_issue": "..." },
    "listening": { "summary": "...", "main_issue": "..." },
    "writing": { "summary": "...", "main_issue": "..." },
    "speaking": { "summary": "...", "main_issue": "..." }
  },
  "overall_recommendations": [
    { "title": "...", "detail": "..." }
  ]
}

${VIETNAMESE_FEEDBACK_REQUIREMENT}
`.trim();

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  let attemptId: string | null = null;
  let userId: string | null = null;
  let guestToken: string | null = null;

  try {
    const body = await req.json() as { attempt_id?: string };
    attemptId = normalizeString(body.attempt_id);

    if (!attemptId) {
      return jsonResponse({ error: "attempt_id required" }, 400);
    }

    const accessAttempt = await assertCanAccessExamAttempt({
      supabase,
      req,
      attemptId,
    });
    guestToken = normalizeString(accessAttempt["guest_token"]);

    await supabase
      .from("exam_analysis")
      .upsert({
        attempt_id: attemptId,
        guest_token: guestToken,
        status: "processing",
        error_message: null,
      }, { onConflict: "attempt_id" });

    const { data: attempt, error: attemptError } = await supabase
      .from("exam_attempts")
      .select("id, exam_id, user_id, guest_token, answers")
      .eq("id", attemptId)
      .single();

    if (attemptError || !attempt) {
      throw new Error("Attempt not found");
    }

    const attemptRecord = attempt as JsonRecord;
    userId = normalizeString(attemptRecord["user_id"]);
    guestToken = normalizeString(attemptRecord["guest_token"]);
    const answers = (attemptRecord["answers"] as JsonRecord | null) ?? {};
    const hasLegacyAnswerKeys = Object.keys(answers).some((key) =>
      key.startsWith("q_")
    );

    await supabase
      .from("exam_analysis")
      .update({ user_id: userId, guest_token: guestToken })
      .eq("attempt_id", attemptId);

    const [{ data: sectionsRaw }, { data: examResultRaw }] = await Promise.all([
      supabase
        .from("exam_sections")
        .select("id, skill, label, order_index")
        .eq("exam_id", attemptRecord["exam_id"])
        .order("order_index"),
      supabase
        .from("exam_results")
        .select("total_score, section_scores, weak_skills")
        .eq("attempt_id", attemptId)
        .maybeSingle(),
    ]);

    const sections = ((sectionsRaw ?? []) as SectionRow[])
      .sort((left, right) => left.order_index - right.order_index);
    const examResult = (examResultRaw ?? {}) as ExamResultRow;
    if (sections.length === 0) {
      throw new Error("No sections found for exam");
    }

    const sectionIds = sections.map((section) => section.id);
    const { data: questionsRaw } = await supabase
      .from("questions")
      .select(
        "id, type, skill, prompt, explanation, correct_answer, section_id, order_index, question_options(id, text, is_correct, order_index)",
      )
      .in("section_id", sectionIds)
      .order("order_index");

    const questions = ((questionsRaw ?? []) as QuestionRow[])
      .map((question) => ({
        ...question,
        question_options: [...(question.question_options ?? [])]
          .sort((left, right) => left.order_index - right.order_index),
      }));

    const storedAttemptIds = Object.values(answers)
      .filter((value): value is StoredAnswer =>
        typeof value === "object" && value !== null
      )
      .map((value) => normalizeString(value.ai_attempt_id))
      .filter((value): value is string => value !== null);

    const subjectiveContexts = questions
      .map((question, index) => ({
        question,
        storedAnswer: getStoredAnswer({
          answers,
          question,
          globalIdx: index,
          hasLegacyAnswerKeys,
        }),
      }))
      .filter(({ question }) =>
        question.type === "speaking" || question.type === "writing"
      )
      .filter(({ storedAnswer }) => isStoredAnswerAnswered(storedAnswer));

    const subjectiveAttempts = await waitForSubjectiveAttempts({
      supabase,
      attemptId,
      storedAttemptIds,
      contexts: subjectiveContexts,
    });

    const sectionById = new Map(
      sections.map((section) => [section.id, section]),
    );
    const analysisQuestions = questions.map((question, index) => ({
      question,
      section: sectionById.get(question.section_id) ?? null,
      number: index + 1,
      storedAnswer: getStoredAnswer({
        answers,
        question,
        globalIdx: index,
        hasLegacyAnswerKeys,
      }),
    }));

    const feedbackEntries = await mapWithConcurrency(
      analysisQuestions,
      OBJECTIVE_CONCURRENCY,
      async (context) =>
        [
          context.question.id,
          await buildQuestionFeedback({
            supabase,
            attemptId: attemptId!,
            context,
            subjectiveAttempts,
          }),
        ] as const,
    );

    const questionFeedbacks = Object.fromEntries(feedbackEntries);

    const synthesis = await buildExamSynthesis({
      examResult,
      sections,
      questions: analysisQuestions,
      questionFeedbacks,
    });

    const { error: updateError } = await supabase
      .from("exam_analysis")
      .update({
        user_id: userId,
        guest_token: guestToken,
        status: "ready",
        question_feedbacks: questionFeedbacks,
        skill_insights: synthesis.skillInsights,
        overall_recommendations: synthesis.overallRecommendations,
        error_message: null,
      })
      .eq("attempt_id", attemptId);

    if (updateError) {
      throw new Error(
        `Failed to persist exam analysis: ${updateError.message}`,
      );
    }

    return jsonResponse({
      success: true,
      attempt_id: attemptId,
      status: "ready",
    }, 200);
  } catch (error) {
    console.error("analyze-exam error:", error);

    if (attemptId) {
      await supabase
        .from("exam_analysis")
        .upsert({
          attempt_id: attemptId,
          user_id: userId,
          guest_token: guestToken,
          status: "error",
          error_message: String(error),
        }, { onConflict: "attempt_id" });
    }

    return jsonResponse({ error: String(error) }, 500);
  }
});

async function buildQuestionFeedback(args: {
  supabase: SupabaseClient;
  attemptId: string;
  context: AnalysisQuestionContext;
  subjectiveAttempts: SubjectiveAttempts;
}): Promise<Record<string, unknown>> {
  const { supabase, attemptId, context, subjectiveAttempts } = args;
  const { question } = context;

  if (question.type === "speaking") {
    return buildSpeakingQuestionFeedback({
      attemptId,
      context,
      subjectiveAttempts,
    });
  }

  if (question.type === "writing") {
    return buildWritingQuestionFeedback({
      attemptId,
      context,
      subjectiveAttempts,
    });
  }

  return buildObjectiveQuestionFeedback({
    supabase,
    context,
  });
}

async function buildObjectiveQuestionFeedback(args: {
  supabase: SupabaseClient;
  context: AnalysisQuestionContext;
}): Promise<Record<string, unknown>> {
  const { supabase, context } = args;
  const { question, storedAnswer } = context;
  const normalizedType = normalizeQuestionFeedbackType(question.type);
  const correctOption = question.question_options.find((option) =>
    option.is_correct
  );
  const selectedOption = question.question_options.find(
    (option) => option.id === normalizeString(storedAnswer?.selected_option_id),
  );

  const correctAnswerText = buildCorrectAnswerText(question, correctOption);
  const fallbackExplanation = buildCorrectExplanationFallback(
    question,
    correctAnswerText,
  );
  const commonPayload = {
    skipped: false,
  };

  switch (normalizedType) {
    case "mcq": {
      const isAnswered = selectedOption != null;
      const isCorrect = selectedOption?.is_correct ?? false;
      if (!isAnswered) {
        return {
          ...commonPayload,
          verdict: "incorrect",
          error_analysis: "Bạn đã bỏ trống câu này nên mất điểm.",
          correct_explanation: fallbackExplanation,
          short_tip: "Đọc kỹ từ khóa trước khi chọn đáp án.",
          key_concept: skillConceptLabel(question.skill),
          matching_feedback: null,
        };
      }

      if (isCorrect) {
        return {
          ...commonPayload,
          verdict: "correct",
          error_analysis: "",
          correct_explanation: fallbackExplanation,
          short_tip: "",
          key_concept: skillConceptLabel(question.skill),
          matching_feedback: null,
        };
      }

      return fetchObjectiveFeedbackFromAi({
        supabase,
        question,
        userAnswerText: selectedOption?.text ?? "",
        correctAnswerText,
      });
    }
    case "fill_blank": {
      const userAnswerText = normalizeString(storedAnswer?.written_answer) ??
        "";
      const isAnswered = userAnswerText.length > 0;
      const isCorrect = userAnswerText.toLowerCase() ===
        (question.correct_answer ?? "").trim().toLowerCase();

      if (!isAnswered) {
        return {
          ...commonPayload,
          verdict: "incorrect",
          error_analysis: "Bạn chưa điền đáp án nên câu này bị tính sai.",
          correct_explanation: fallbackExplanation,
          short_tip: "Kiểm tra dạng từ và chính tả.",
          key_concept: skillConceptLabel(question.skill),
          matching_feedback: null,
        };
      }

      if (isCorrect) {
        return {
          ...commonPayload,
          verdict: "correct",
          error_analysis: "",
          correct_explanation: fallbackExplanation,
          short_tip: "",
          key_concept: skillConceptLabel(question.skill),
          matching_feedback: null,
        };
      }

      return fetchObjectiveFeedbackFromAi({
        supabase,
        question,
        userAnswerText,
        correctAnswerText,
      });
    }
    case "matching":
    case "ordering": {
      const userAnswerText = normalizeString(storedAnswer?.written_answer) ??
        "";
      const isAnswered = userAnswerText.length > 0;
      const isCorrect = normalizedType === "ordering"
        ? isOrderingCorrect(question, userAnswerText)
        : isMatchingCorrect(question, userAnswerText);

      if (!isAnswered) {
        return {
          ...commonPayload,
          verdict: "incorrect",
          error_analysis: "Bạn chưa hoàn thành câu ghép/sắp xếp này.",
          correct_explanation: fallbackExplanation,
          short_tip: "Đối chiếu từng vị trí trước khi nộp.",
          key_concept: skillConceptLabel(question.skill),
          matching_feedback: [],
        };
      }

      if (isCorrect) {
        return {
          ...commonPayload,
          verdict: "correct",
          error_analysis: "",
          correct_explanation: fallbackExplanation,
          short_tip: "",
          key_concept: skillConceptLabel(question.skill),
          matching_feedback: [],
        };
      }

      return fetchObjectiveFeedbackFromAi({
        supabase,
        question,
        userAnswerText,
        correctAnswerText,
      });
    }
  }
}

async function fetchObjectiveFeedbackFromAi(args: {
  supabase: SupabaseClient;
  question: QuestionRow;
  userAnswerText: string;
  correctAnswerText: string;
}): Promise<Record<string, unknown>> {
  const { supabase, question, userAnswerText, correctAnswerText } = args;
  const request: QuestionFeedbackRequest = {
    question_id: question.id,
    question_text: question.prompt,
    question_type: question.type,
    options: question.question_options.map((option) => ({
      id: option.id,
      text: option.text,
    })),
    correct_answer_text: correctAnswerText,
    user_answer_text: userAnswerText,
    section_skill: question.skill,
    correct_order: buildCorrectOrder(question),
    match_pairs: question.type === "matching"
      ? buildMatchPairs(question)
      : undefined,
  };

  try {
    const feedback = await fetchOrGenerateQuestionFeedback({
      supabase,
      params: request,
      timeoutMs: OBJECTIVE_TIMEOUT_MS,
    });

    return {
      verdict: "incorrect",
      error_analysis: feedback.error_analysis,
      correct_explanation: feedback.correct_explanation,
      short_tip: feedback.short_tip,
      key_concept: feedback.key_concept,
      matching_feedback: feedback.matching_feedback,
      skipped: false,
    };
  } catch (error) {
    console.warn("objective feedback skipped:", question.id, error);
    return {
      verdict: "incorrect",
      error_analysis: "",
      correct_explanation: buildCorrectExplanationFallback(
        question,
        correctAnswerText,
      ),
      short_tip: "",
      key_concept: skillConceptLabel(question.skill),
      matching_feedback: null,
      skipped: true,
    };
  }
}

async function buildSpeakingQuestionFeedback(args: {
  attemptId: string;
  context: AnalysisQuestionContext;
  subjectiveAttempts: SubjectiveAttempts;
}): Promise<Record<string, unknown>> {
  const { attemptId, context, subjectiveAttempts } = args;
  const row = findSubjectiveAttemptRow(
    subjectiveAttempts.speaking,
    context.question.id,
    normalizeString(context.storedAnswer?.ai_attempt_id),
  );

  if (!isStoredAnswerAnswered(context.storedAnswer)) {
    return {
      verdict: "incorrect",
      summary: "Bạn chưa nộp bài nói cho câu này.",
      criteria: [],
      short_tips: ["Ghi âm đầy đủ để nhận nhận xét chi tiết."],
      skipped: false,
    };
  }

  if (!row || row.status === "processing") {
    return {
      verdict: "incorrect",
      summary: "AI chưa kịp hoàn tất phân tích cho bài nói này.",
      criteria: [],
      short_tips: [],
      skipped: true,
    };
  }

  if (row.status === "error") {
    return {
      verdict: "incorrect",
      summary: normalizeSpeakingAnalysisError(
        row.error_message ?? "Không thể phân tích bài nói này.",
      ),
      criteria: [],
      short_tips: [],
      skipped: true,
    };
  }

  const payload = await ensureVietnameseUserFacingJson(
    getOpenAIKey(),
    buildSpeakingReviewPayload({
      reviewId: `exam-analysis:${attemptId}:${context.question.id}`,
      source: "mock_test",
      row: row as unknown as Record<string, unknown>,
    }),
    "exam_analysis.speaking_review_payload",
  );

  return {
    verdict: payload.verdict,
    summary: payload.summary,
    criteria: payload.criteria.map((criterion) => ({
      label: String(criterion["title"] ?? ""),
      score: toNullableNumber(criterion["score"]),
      max_score: toNullableNumber(criterion["max_score"]),
      feedback: String(criterion["feedback"] ?? ""),
      tip: String(criterion["tip"] ?? ""),
    })),
    short_tips: payload.artifacts.short_tips ?? [],
    skipped: false,
  };
}

function normalizeSpeakingAnalysisError(message: string): string {
  if (
    message.includes("response_format") ||
    message.includes("OpenAI audio chat error 400")
  ) {
    return "Bài nói này đã nộp nhưng bước chấm audio bị lỗi kỹ thuật, nên chưa tạo được đánh giá.";
  }

  return message;
}

async function buildWritingQuestionFeedback(args: {
  attemptId: string;
  context: AnalysisQuestionContext;
  subjectiveAttempts: SubjectiveAttempts;
}): Promise<Record<string, unknown>> {
  const { attemptId, context, subjectiveAttempts } = args;
  const row = findSubjectiveAttemptRow(
    subjectiveAttempts.writing,
    context.question.id,
    normalizeString(context.storedAnswer?.ai_attempt_id),
  );

  if (!isStoredAnswerAnswered(context.storedAnswer)) {
    return {
      verdict: "incorrect",
      summary: "Bạn chưa nộp bài viết cho câu này.",
      criteria: [],
      short_tips: ["Hoàn thành bài viết để nhận nhận xét AI."],
      skipped: false,
    };
  }

  if (!row || row.status === "processing") {
    return {
      verdict: "incorrect",
      summary: "AI chưa kịp hoàn tất phân tích cho bài viết này.",
      criteria: [],
      short_tips: [],
      skipped: true,
    };
  }

  if (row.status === "error") {
    return {
      verdict: "incorrect",
      summary: String(row.error_message ?? "Không thể phân tích bài viết này."),
      criteria: [],
      short_tips: [],
      skipped: true,
    };
  }

  const payload = await ensureVietnameseUserFacingJson(
    getOpenAIKey(),
    buildWritingReviewPayload({
      reviewId: `exam-analysis:${attemptId}:${context.question.id}`,
      source: "mock_test",
      row: row as unknown as Record<string, unknown>,
    }),
    "exam_analysis.writing_review_payload",
  );

  return {
    verdict: payload.verdict,
    summary: payload.summary,
    criteria: payload.criteria.map((criterion) => ({
      label: String(criterion["title"] ?? ""),
      score: toNullableNumber(criterion["score"]),
      max_score: toNullableNumber(criterion["max_score"]),
      feedback: String(criterion["feedback"] ?? ""),
      tip: String(criterion["tip"] ?? ""),
    })),
    short_tips: payload.artifacts.short_tips ?? [],
    skipped: false,
  };
}

async function buildExamSynthesis(args: {
  examResult: ExamResultRow;
  sections: SectionRow[];
  questions: AnalysisQuestionContext[];
  questionFeedbacks: Record<string, Record<string, unknown>>;
}): Promise<{
  skillInsights: Record<string, Record<string, string>>;
  overallRecommendations: Array<Record<string, string>>;
}> {
  const { examResult, sections, questions, questionFeedbacks } = args;
  const fallback = buildFallbackSynthesis(args);

  try {
    const apiKey = getOpenAIKey();
    const userMessage = JSON.stringify({
      total_score: examResult.total_score ?? null,
      section_scores: examResult.section_scores ?? {},
      weak_skills: examResult.weak_skills ?? [],
      sections: sections.map((section) => ({
        skill: section.skill,
        label: section.label,
      })),
      question_summaries: questions.map((context) => {
        const feedback = questionFeedbacks[context.question.id] ?? {};
        return {
          number: context.number,
          skill: context.section?.skill ?? context.question.skill,
          type: context.question.type,
          verdict: String(feedback["verdict"] ?? "incorrect"),
          skipped: feedback["skipped"] === true,
          key_concept: String(feedback["key_concept"] ?? ""),
          short_tip: String(feedback["short_tip"] ?? ""),
          summary: String(feedback["summary"] ?? ""),
        };
      }),
    });

    const rawResult = await chatComplete(
      apiKey,
      SYNTHESIS_PROMPT,
      userMessage,
      { model: getExamSynthesisModel(), timeoutMs: SYNTHESIS_TIMEOUT_MS },
    );
    const result = await ensureVietnameseUserFacingJson(
      apiKey,
      rawResult,
      "exam_analysis.synthesis_payload",
    );
    const rawInsights = isRecord(result["skill_insights"])
      ? result["skill_insights"]
      : {};
    const allowedSkills = new Set(sections.map((section) => section.skill));

    const skillInsights: Record<string, Record<string, string>> = {};
    for (const skill of allowedSkills) {
      const raw = rawInsights[skill];
      if (!isRecord(raw)) continue;
      skillInsights[skill] = {
        "summary": String(raw["summary"] ?? ""),
        "main_issue": String(raw["main_issue"] ?? ""),
      };
    }

    const rawRecommendations =
      ((result["overall_recommendations"] as unknown[] | undefined) ?? [])
        .filter(isRecord)
        .map((item) => ({
          "title": String(item["title"] ?? ""),
          "detail": String(item["detail"] ?? ""),
        }))
        .filter((item) =>
          item["title"].length > 0 || item["detail"].length > 0
        );

    return {
      skillInsights: Object.keys(skillInsights).length > 0
        ? skillInsights
        : fallback.skillInsights,
      overallRecommendations: rawRecommendations.length > 0
        ? rawRecommendations
        : fallback.overallRecommendations,
    };
  } catch (error) {
    console.warn("synthesis fallback:", error);
    return fallback;
  }
}

function buildFallbackSynthesis(args: {
  examResult: ExamResultRow;
  sections: SectionRow[];
  questions: AnalysisQuestionContext[];
  questionFeedbacks: Record<string, Record<string, unknown>>;
}): {
  skillInsights: Record<string, Record<string, string>>;
  overallRecommendations: Array<Record<string, string>>;
} {
  const { examResult, sections, questions, questionFeedbacks } = args;
  const grouped = new Map<string, Array<Record<string, unknown>>>();

  for (const context of questions) {
    const skill = context.section?.skill ?? context.question.skill;
    if (!grouped.has(skill)) grouped.set(skill, []);
    grouped.get(skill)!.push(questionFeedbacks[context.question.id] ?? {});
  }

  const skillInsights = Object.fromEntries(
    sections.map((section) => {
      const entries = grouped.get(section.skill) ?? [];
      const sectionScoreEntry =
        (examResult.section_scores ?? {})[section.skill];
      const sectionScore = isRecord(sectionScoreEntry)
        ? toNullableNumber(sectionScoreEntry["score"])
        : null;
      const weakCount = entries.filter((entry) => {
        const verdict = String(entry["verdict"] ?? "");
        return verdict === "incorrect" || verdict === "partial";
      }).length;
      const skippedCount = entries.filter((entry) =>
        entry["skipped"] === true
      ).length;
      const concepts = entries
        .map((entry) => String(entry["key_concept"] ?? ""))
        .filter((value) => value.length > 0);

      return [
        section.skill,
        {
          "summary": sectionScore != null
            ? `Bạn đang ở mức ${sectionScore}/100 cho phần ${section.label}. ${
              weakCount === 0
                ? "Nền tảng đang khá ổn."
                : "Vẫn còn vài điểm cần rà lại."
            }`
            : `Phần ${section.label} đã được phân tích từ toàn bộ câu trả lời.`,
          "main_issue": skippedCount > 0
            ? "Một số câu chưa có đủ dữ liệu AI nên nên xem lại phần trả lời gốc."
            : concepts.length > 0
            ? `Chủ điểm cần ưu tiên là ${concepts[0]}.`
            : "Cần luyện thêm độ chính xác và cách áp dụng mẫu câu.",
        },
      ];
    }),
  );

  const weakSkills = examResult.weak_skills ?? [];
  const focusSkills = weakSkills.length > 0
    ? weakSkills
    : sections.slice(0, 2).map((section) => section.skill);

  const overallRecommendations = focusSkills.slice(0, 3).map((skill) => ({
    "title": `Ôn lại ${skillConceptLabel(skill)}`,
    "detail": `Làm lại các câu ${
      skillLabel(skill).toLowerCase()
    } sai và ghi chú quy tắc chính vào sổ tay.`,
  }));

  if (overallRecommendations.length < 3) {
    overallRecommendations.push(
      {
        "title": "Làm lại bài thi sau khi ôn",
        "detail":
          "Thử làm lại một mock test ngắn sau khi xem hết feedback để kiểm tra tiến bộ.",
      },
      {
        "title": "Tập trung vào câu bỏ trống",
        "detail":
          "Ưu tiên hoàn thành đủ tất cả câu trước, sau đó mới quay lại chỉnh các câu khó.",
      },
    );
  }

  return {
    skillInsights,
    overallRecommendations: overallRecommendations.slice(0, 5),
  };
}

async function waitForSubjectiveAttempts(args: {
  supabase: SupabaseClient;
  attemptId: string;
  storedAttemptIds: string[];
  contexts: Array<{ question: QuestionRow; storedAnswer: StoredAnswer | null }>;
}): Promise<SubjectiveAttempts> {
  const { supabase, attemptId, storedAttemptIds, contexts } = args;

  for (let index = 0; index < SUBJECTIVE_WAIT_RETRIES; index++) {
    const attempts = await fetchSubjectiveAttempts({
      supabase,
      attemptId,
      storedAttemptIds,
    });
    const unresolved = contexts.some(({ question, storedAnswer }) => {
      const row = question.type === "speaking"
        ? findSubjectiveAttemptRow(
          attempts.speaking,
          question.id,
          normalizeString(storedAnswer?.ai_attempt_id),
        )
        : findSubjectiveAttemptRow(
          attempts.writing,
          question.id,
          normalizeString(storedAnswer?.ai_attempt_id),
        );
      return !row || row.status === "processing";
    });

    if (!unresolved) return attempts;
    if (index < SUBJECTIVE_WAIT_RETRIES - 1) {
      await delay(SUBJECTIVE_WAIT_INTERVAL);
    }
  }

  return fetchSubjectiveAttempts({ supabase, attemptId, storedAttemptIds });
}

interface SubjectiveAttempts {
  speaking: AiAttemptRow[];
  writing: AiAttemptRow[];
}

async function fetchSubjectiveAttempts(args: {
  supabase: SupabaseClient;
  attemptId: string;
  storedAttemptIds: string[];
}): Promise<SubjectiveAttempts> {
  const { supabase, attemptId, storedAttemptIds } = args;

  const [
    speakingByExam,
    writingByExam,
    speakingByIds,
    writingByIds,
  ] = await Promise.all([
    supabase
      .from("ai_speaking_attempts")
      .select(
        "id, question_id, status, error_message, overall_score, metrics, issues, corrected_answer, transcript",
      )
      .eq("exam_attempt_id", attemptId),
    supabase
      .from("ai_writing_attempts")
      .select(
        "id, question_id, status, error_message, overall_score, metrics, grammar_notes, corrected_essay",
      )
      .eq("exam_attempt_id", attemptId),
    storedAttemptIds.length > 0
      ? supabase
        .from("ai_speaking_attempts")
        .select(
          "id, question_id, status, error_message, overall_score, metrics, issues, corrected_answer, transcript",
        )
        .in("id", storedAttemptIds)
      : Promise.resolve({ data: [] as AiAttemptRow[] }),
    storedAttemptIds.length > 0
      ? supabase
        .from("ai_writing_attempts")
        .select(
          "id, question_id, status, error_message, overall_score, metrics, grammar_notes, corrected_essay",
        )
        .in("id", storedAttemptIds)
      : Promise.resolve({ data: [] as AiAttemptRow[] }),
  ]);

  return {
    speaking: mergeAttemptRows([
      (speakingByExam.data ?? []) as AiAttemptRow[],
      (speakingByIds.data ?? []) as AiAttemptRow[],
    ]),
    writing: mergeAttemptRows([
      (writingByExam.data ?? []) as AiAttemptRow[],
      (writingByIds.data ?? []) as AiAttemptRow[],
    ]),
  };
}

function mergeAttemptRows(groups: AiAttemptRow[][]): AiAttemptRow[] {
  const map = new Map<string, AiAttemptRow>();
  for (const group of groups) {
    for (const row of group) {
      map.set(row.id, row);
    }
  }
  return [...map.values()];
}

function findSubjectiveAttemptRow(
  rows: AiAttemptRow[],
  questionId: string,
  aiAttemptId: string | null,
): AiAttemptRow | null {
  if (aiAttemptId) {
    const byId = rows.find((row) => row.id === aiAttemptId);
    if (byId) return byId;
  }
  return rows.find((row) => row.question_id === questionId) ?? null;
}

function getStoredAnswer(args: {
  answers: JsonRecord;
  question: QuestionRow;
  globalIdx: number;
  hasLegacyAnswerKeys: boolean;
}): StoredAnswer | null {
  const { answers, question, globalIdx, hasLegacyAnswerKeys } = args;
  if (hasLegacyAnswerKeys) {
    const legacyValue = normalizeString(answers[`q_${globalIdx}`]);
    if (!legacyValue) return null;
    if (
      question.type === "mcq" || question.type === "reading_mcq" ||
      question.type === "listening_mcq"
    ) {
      return { selected_option_id: legacyValue };
    }
    if (question.type === "speaking") {
      return { ai_attempt_id: legacyValue };
    }
    return { written_answer: legacyValue };
  }

  const rawAnswer = answers[question.id];
  if (!rawAnswer || typeof rawAnswer !== "object") return null;
  return rawAnswer as StoredAnswer;
}

function isStoredAnswerAnswered(answer: StoredAnswer | null): boolean {
  return normalizeString(answer?.selected_option_id) != null ||
    normalizeString(answer?.written_answer) != null ||
    normalizeString(answer?.ai_attempt_id) != null;
}

function buildCorrectAnswerText(
  question: QuestionRow,
  correctOption: QuestionOptionRow | undefined,
): string {
  if (
    question.type === "mcq" || question.type === "reading_mcq" ||
    question.type === "listening_mcq"
  ) {
    return correctOption?.text ?? question.correct_answer ?? "";
  }

  if (question.type === "ordering") {
    return buildCorrectOrder(question).join(" → ");
  }

  if (question.type === "matching") {
    return formatMatchingAnswer(question.correct_answer ?? "", question);
  }

  return question.correct_answer ?? "";
}

function buildCorrectExplanationFallback(
  question: QuestionRow,
  correctAnswerText: string,
): string {
  const explanation = normalizeString(question.explanation);
  if (explanation) return explanation;
  if (correctAnswerText.length > 0) {
    return `Đáp án đúng là "${correctAnswerText}". Hãy ghi nhớ mẫu này để áp dụng cho câu tương tự.`;
  }
  return "Đây là đáp án đúng của câu hỏi này. Hãy xem lại từ khóa và quy tắc chính của câu.";
}

function buildCorrectOrder(question: QuestionRow): string[] {
  return [...question.question_options]
    .sort((left, right) => left.order_index - right.order_index)
    .map((option) => option.text);
}

function isOrderingCorrect(question: QuestionRow, rawAnswer: string): boolean {
  const submitted = parseJsonValue(rawAnswer);
  if (!Array.isArray(submitted)) return false;
  const expectedIds = [...question.question_options]
    .sort((left, right) => left.order_index - right.order_index)
    .map((option) => option.id);
  if (submitted.length !== expectedIds.length) return false;
  return submitted.every((value, index) =>
    String(value) === expectedIds[index]
  );
}

function isMatchingCorrect(question: QuestionRow, rawAnswer: string): boolean {
  const submittedPairs = parseMatchingPairs(rawAnswer);
  const correctPairs = parseMatchingPairs(question.correct_answer ?? "");
  const correctKeys = Object.keys(correctPairs);
  return correctKeys.length > 0 &&
    correctKeys.every((leftId) =>
      submittedPairs[leftId] === correctPairs[leftId]
    );
}

function parseJsonValue(raw: string): unknown {
  try {
    return JSON.parse(raw);
  } catch (_) {
    return null;
  }
}

function parseMatchingPairs(raw: string): Record<string, string> {
  const parsed = parseJsonValue(raw);
  if (typeof parsed !== "object" || parsed == null || Array.isArray(parsed)) {
    return {};
  }

  return Object.fromEntries(
    Object.entries(parsed)
      .map(([leftId, rightId]) => [String(leftId), String(rightId ?? "")])
      .filter(([, rightId]) => rightId.length > 0),
  );
}

function buildMatchPairs(question: QuestionRow): Array<{
  left_id: string;
  left_text: string;
  right_id: string;
  right_text: string;
}> {
  const optionTextById = Object.fromEntries(
    question.question_options.map((option) => [option.id, option.text]),
  );

  return Object.entries(parseMatchingPairs(question.correct_answer ?? ""))
    .map(([leftId, rightId]) => ({
      left_id: leftId,
      left_text: leftId,
      right_id: rightId,
      right_text: optionTextById[rightId] ?? rightId,
    }));
}

function formatMatchingAnswer(raw: string, question: QuestionRow): string {
  const optionTextById = Object.fromEntries(
    question.question_options.map((option) => [option.id, option.text]),
  );
  const pairs = Object.entries(parseMatchingPairs(raw));
  if (pairs.length === 0) return raw;

  return pairs
    .map(([leftId, rightId]) =>
      `${leftId} -> ${optionTextById[rightId] ?? rightId}`
    )
    .join(" | ");
}

function normalizeString(value: unknown): string | null {
  if (value == null) return null;
  const text = String(value).trim();
  return text.length === 0 ? null : text;
}

function skillLabel(skill: string): string {
  switch (skill) {
    case "listening":
      return "Nghe hiểu";
    case "writing":
      return "Viết";
    case "speaking":
      return "Nói";
    case "grammar":
      return "Ngữ pháp";
    case "vocabulary":
      return "Từ vựng";
    default:
      return "Đọc hiểu";
  }
}

function skillConceptLabel(skill: string): string {
  switch (skill) {
    case "listening":
      return "Nghe ý chính và từ khóa";
    case "writing":
      return "Viết đúng ý và đúng mẫu câu";
    case "speaking":
      return "Phát âm và diễn đạt rõ ràng";
    case "grammar":
      return "Ngữ pháp trọng tâm";
    case "vocabulary":
      return "Từ vựng theo chủ đề";
    default:
      return "Đọc ý chính và từ khóa";
  }
}

function toNullableNumber(value: unknown): number | null {
  const numeric = Number(value ?? NaN);
  return Number.isFinite(numeric) ? numeric : null;
}

function isRecord(value: unknown): value is JsonRecord {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

async function mapWithConcurrency<T, U>(
  items: T[],
  concurrency: number,
  mapper: (item: T, index: number) => Promise<U>,
): Promise<U[]> {
  if (items.length === 0) return [];

  const results = new Array<U>(items.length);
  let nextIndex = 0;

  async function worker() {
    while (nextIndex < items.length) {
      const currentIndex = nextIndex++;
      results[currentIndex] = await mapper(items[currentIndex], currentIndex);
    }
  }

  await Promise.all(
    Array.from({ length: Math.min(concurrency, items.length) }, () => worker()),
  );

  return results;
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
