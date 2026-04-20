import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  chatComplete,
  getOpenAIKey,
  getQuestionFeedbackModel,
} from "./openai.ts";
import { VIETNAMESE_FEEDBACK_REQUIREMENT } from "./vietnamese.ts";
import { ensureVietnameseUserFacingJson } from "./vietnamese_guard.ts";

export type QuestionFeedbackType =
  | "mcq"
  | "fill_blank"
  | "matching"
  | "ordering";

export type QuestionFeedbackOption = {
  id: string;
  text: string;
};

export type QuestionFeedbackMatchPair = {
  left_id: string;
  left_text: string;
  right_id: string;
  right_text: string;
};

export type QuestionFeedback = {
  error_analysis: string;
  correct_explanation: string;
  short_tip: string;
  key_concept: string;
  matching_feedback: Array<Record<string, unknown>> | null;
};

export type QuestionFeedbackRequest = {
  question_id?: string;
  question_text: string;
  question_type?: string;
  options?: QuestionFeedbackOption[];
  correct_answer_text: string;
  user_answer_text: string;
  section_skill?: string;
  match_pairs?: QuestionFeedbackMatchPair[];
  correct_order?: string[];
};

export const QUESTION_FEEDBACK_PROMPT = `
Bạn là giáo viên tiếng Séc chuyên giải thích lỗi sai cho học sinh người Việt đang luyện thi A2 Trvalý pobyt.

Nhiệm vụ: Phân tích ngắn gọn tại sao học sinh trả lời sai câu hỏi và đưa ra lời khuyên cụ thể.

Yêu cầu:
- error_analysis: 1-2 câu giải thích CHÍNH XÁC tại sao đáp án học sinh chọn là sai
- correct_explanation: 1-2 câu giải thích tại sao đáp án đúng là đúng
- short_tip: 1 câu lời khuyên ngắn gọn (tối đa 15 từ) để học sinh nhớ quy tắc này
- key_concept: tên khái niệm ngữ pháp/ngôn ngữ cụ thể (ví dụ: "Accusativ", "Giới từ v+", "Chia động từ být", "Từ vựng chủ đề nhà ở")

Ngôn ngữ: Tất cả trả lời bằng tiếng Việt. Có thể trích dẫn từ tiếng Séc.

Trả về JSON:
{
  "error_analysis": "...",
  "correct_explanation": "...",
  "short_tip": "...",
  "key_concept": "..."
}

${VIETNAMESE_FEEDBACK_REQUIREMENT}
`.trim();

export const MATCHING_FEEDBACK_PROMPT = `
Bạn là giáo viên tiếng Séc chuyên giải thích lỗi sai cho học sinh người Việt đang luyện thi A2 Trvalý pobyt.

Nhiệm vụ: Giải thích tại sao học sinh ghép cặp/sắp xếp sai và cách nhớ thứ tự đúng.

Yêu cầu:
- error_analysis: 1-2 câu tổng quát về lỗi sai
- correct_explanation: giải thích thứ tự/cặp ghép đúng và lý do
- short_tip: 1 câu lời khuyên ngắn gọn (tối đa 15 từ)
- key_concept: tên khái niệm liên quan
- matching_feedback: mảng mô tả lỗi từng cặp/vị trí sai (nếu có)

Ngôn ngữ: Tất cả trả lời bằng tiếng Việt.

Trả về JSON:
{
  "error_analysis": "...",
  "correct_explanation": "...",
  "short_tip": "...",
  "key_concept": "...",
  "matching_feedback": [{ "item": "<từ/cụm từ>", "issue": "<lý do sai ngắn gọn>" }]
}

${VIETNAMESE_FEEDBACK_REQUIREMENT}
`.trim();

export function normalizeQuestionFeedbackType(
  questionType?: string,
): QuestionFeedbackType {
  switch (questionType) {
    case "fill_blank":
    case "fillBlank":
      return "fill_blank";
    case "matching":
      return "matching";
    case "ordering":
      return "ordering";
    default:
      return "mcq";
  }
}

export async function computeQuestionFeedbackHash(
  text: string,
): Promise<string> {
  const normalized = text.trim().toLowerCase();
  const buffer = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(normalized),
  );
  return Array.from(new Uint8Array(buffer))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

export async function fetchOrGenerateQuestionFeedback(args: {
  supabase: SupabaseClient;
  params: QuestionFeedbackRequest;
  timeoutMs?: number;
}): Promise<QuestionFeedback & { from_cache: boolean }> {
  const { supabase, params, timeoutMs = 30_000 } = args;
  const questionType = normalizeQuestionFeedbackType(params.question_type);
  const userAnswerHash = await computeQuestionFeedbackHash(
    params.user_answer_text,
  );

  if (params.question_id) {
    const { data: cached } = await supabase
      .from("question_ai_feedback")
      .select("*")
      .eq("question_id", params.question_id)
      .eq("user_answer_hash", userAnswerHash)
      .maybeSingle();

    if (cached) {
      const cachedFeedback = {
        error_analysis: String(cached.error_analysis ?? ""),
        correct_explanation: String(cached.correct_explanation ?? ""),
        short_tip: String(cached.short_tip ?? ""),
        key_concept: String(cached.key_concept ?? ""),
        matching_feedback:
          (cached.matching_feedback as Array<Record<string, unknown>> | null) ??
            null,
      };
      const normalized = await ensureVietnameseUserFacingJson(
        getOpenAIKey(),
        cachedFeedback,
        "question_feedback.cache",
      );

      if (JSON.stringify(normalized) !== JSON.stringify(cachedFeedback)) {
        await supabase
          .from("question_ai_feedback")
          .upsert({
            question_id: params.question_id,
            user_answer_hash: userAnswerHash,
            question_type: questionType,
            ...normalized,
          }, { onConflict: "question_id,user_answer_hash" });
      }

      return {
        ...normalized,
        from_cache: true,
      };
    }
  }

  const apiKey = getOpenAIKey();
  const generated = await generateQuestionFeedback({
    apiKey,
    params: {
      ...params,
      question_type: questionType,
    },
    timeoutMs,
  });
  const result = await ensureVietnameseUserFacingJson(
    apiKey,
    generated,
    "question_feedback.result",
  );

  if (params.question_id) {
    await supabase
      .from("question_ai_feedback")
      .upsert({
        question_id: params.question_id,
        user_answer_hash: userAnswerHash,
        question_type: questionType,
        ...result,
      }, { onConflict: "question_id,user_answer_hash" });
  }

  return {
    ...result,
    from_cache: false,
  };
}

async function generateQuestionFeedback(args: {
  apiKey: string;
  params: QuestionFeedbackRequest;
  timeoutMs: number;
}): Promise<QuestionFeedback> {
  const { apiKey, params, timeoutMs } = args;
  const questionType = normalizeQuestionFeedbackType(params.question_type);
  const isMatchingOrdering = questionType === "matching" ||
    questionType === "ordering";

  let result: Record<string, unknown>;

  if (isMatchingOrdering) {
    const pairsText = params.match_pairs && params.match_pairs.length > 0
      ? `\nCác cặp đúng:\n${
        params.match_pairs.map((pair) =>
          `"${pair.left_text}" ↔ "${pair.right_text}"`
        ).join("\n")
      }`
      : "";
    const orderText = params.correct_order && params.correct_order.length > 0
      ? `\nThứ tự đúng: ${params.correct_order.join(" → ")}`
      : "";

    const userMessage = [
      `Kỹ năng: ${params.section_skill ?? "không rõ"}`,
      `Câu hỏi (${questionType}): "${params.question_text}"`,
      pairsText,
      orderText,
      `Câu trả lời học sinh (JSON): ${params.user_answer_text}`,
      `Đáp án đúng: ${params.correct_answer_text}`,
    ].filter(Boolean).join("\n");

    result = await chatComplete(
      apiKey,
      MATCHING_FEEDBACK_PROMPT,
      userMessage,
      { model: getQuestionFeedbackModel(), timeoutMs },
    );
  } else {
    const optionsText = params.options && params.options.length > 0
      ? `\nCác đáp án:\n${
        params.options.map((option, index) =>
          `${String.fromCharCode(65 + index)}. ${option.text}`
        ).join("\n")
      }`
      : "";

    const userMessage = [
      `Kỹ năng: ${params.section_skill ?? "không rõ"}`,
      `Câu hỏi: "${params.question_text}"`,
      optionsText,
      `Đáp án ĐÚNG: "${params.correct_answer_text}"`,
      `Đáp án học sinh chọn: "${params.user_answer_text}"`,
    ].filter(Boolean).join("\n");

    result = await chatComplete(
      apiKey,
      QUESTION_FEEDBACK_PROMPT,
      userMessage,
      { model: getQuestionFeedbackModel(), timeoutMs },
    );
  }

  return {
    error_analysis: String(result["error_analysis"] ?? ""),
    correct_explanation: String(result["correct_explanation"] ?? ""),
    short_tip: String(result["short_tip"] ?? ""),
    key_concept: String(result["key_concept"] ?? ""),
    matching_feedback: (result["matching_feedback"] as
      | Array<Record<string, unknown>>
      | undefined) ?? null,
  };
}
