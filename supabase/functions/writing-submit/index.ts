import { corsHeaders } from "../_shared/cors.ts";
import {
  chatComplete,
  getOpenAIKey,
  getWritingScoringModel,
} from "../_shared/openai.ts";
import { VIETNAMESE_FEEDBACK_REQUIREMENT } from "../_shared/vietnamese.ts";
import { ensureVietnameseUserFacingJson } from "../_shared/vietnamese_guard.ts";
import {
  createClient,
  type SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";
import {
  assertCanAccessExamAttempt,
  getAuthUserId,
  getGuestToken,
} from "../_shared/guest_access.ts";

declare const EdgeRuntime: {
  waitUntil(promise: Promise<unknown>): void;
};

const WRITING_SYSTEM_PROMPT = `
Bạn là giáo viên chấm bài viết tiếng Séc cho người học người Việt Nam.
Người học đang luyện thi kỳ thi trình độ A2 để xin Trvalý pobyt (cư trú lâu dài) tại Cộng hòa Séc.
Nhiệm vụ là chấm điểm và nhận xét CHI TIẾT từng loại lỗi.

Tiêu chí chấm:
- grammar (ngữ pháp): 0–100 — độ chính xác về biến cách, chia động từ, trật tự từ
- vocabulary (từ vựng): 0–100 — sự đa dạng và phù hợp của từ ngữ
- coherence (mạch lạc): 0–100 — sự liên kết, cấu trúc đoạn văn
- task_achievement (hoàn thành nhiệm vụ): 0–100 — đáp ứng đúng yêu cầu của đề bài

Lưu ý lỗi thường gặp với người học tiếng Việt: lỗi biến cách danh từ và tính từ,
sử dụng sai giới từ, thiếu mạo từ, dịch sát từ tiếng Việt làm câu nghe kỳ lạ.

Trả về JSON chính xác theo định dạng sau (không có văn bản nào khác):
{
  "overall_score": <int 0-100>,
  "grammar": <int 0-100>,
  "vocabulary": <int 0-100>,
  "coherence": <int 0-100>,
  "task_achievement": <int 0-100>,
  "annotated_spans": [
    { "text": "<đoạn văn không có lỗi>", "issue_type": null },
    { "text": "<từ hoặc cụm từ có lỗi>", "issue_type": "grammar|vocabulary|spelling", "correction": "<sửa đúng>", "explanation": "<giải thích rõ tại sao sai và cách sửa>", "tip": "<Lời khuyên ngắn 1 câu tối đa 15 từ để tránh lỗi này lần sau>" }
  ],
  "grammar_feedback": "<Nhận xét CHI TIẾT ngữ pháp: liệt kê lỗi biến cách (pád mấy bị sai), lỗi chia động từ nào, lỗi trật tự từ. Trích dẫn câu/cụm từ cụ thể và cách sửa.>",
  "vocabulary_feedback": "<Nhận xét CHI TIẾT từ vựng: từ nào dùng sai nghĩa hoặc không phù hợp văn cảnh, gợi ý thay thế. Nếu tốt thì nêu điểm hay.>",
  "content_feedback": "<Nhận xét về nội dung: bài có đáp ứng đúng yêu cầu đề bài không, thiếu ý gì, có ý thừa không.>",
  "format_feedback": "<Nhận xét về hình thức: cấu trúc bài (mở/thân/kết), độ dài, văn phong có phù hợp thể loại (thư/đơn/bài luận) không.>",
  "short_tips": ["<tip1 ngắn gọn, tối đa 15 từ>", "<tip2>", "<tip3>"],
  "corrected_essay": "<Toàn bộ bài viết đã được sửa hoàn chỉnh, đúng ngữ pháp tiếng Séc>",
  "overall_feedback": "<Nhận xét tổng quan 2-3 câu bằng tiếng Việt, tóm tắt điểm mạnh và lỗi cần ưu tiên sửa nhất.>"
}

Lưu ý quan trọng về annotated_spans:
- Phải bao phủ TOÀN BỘ văn bản gốc theo thứ tự
- Các đoạn không có lỗi dùng issue_type = null và KHÔNG có trường tip
- issue_type có thể là: "grammar", "vocabulary", "spelling"
- explanation phải giải thích RÕ RÀNG tại sao sai và cách sửa đúng
- tip là lời khuyên ngắn gọn để học sinh nhớ quy tắc, tối đa 15 từ

short_tips là tối đa 3 lời khuyên quan trọng nhất từ toàn bộ bài, mỗi tip tối đa 15 từ tiếng Việt.

${VIETNAMESE_FEEDBACK_REQUIREMENT}
`.trim();

type WritingSubmitBody = {
  text?: string;
  question_id?: string;
  exercise_id?: string;
  lesson_id?: string;
  exam_attempt_id?: string;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  let attemptId: string | null = null;

  try {
    const body = await req.json() as WritingSubmitBody;
    const text = normalizeString(body.text);
    const questionId = normalizeString(body.question_id);
    const exerciseId = normalizeString(body.exercise_id);
    const examAttemptId = normalizeString(body.exam_attempt_id);

    if (!text || (!questionId && !exerciseId)) {
      return jsonResponse(
        { error: "text and question_id or exercise_id are required" },
        400,
      );
    }

    const userId = await getAuthUserId(supabase, req);
    const guestToken = getGuestToken(req);
    if (userId == null && guestToken == null) {
      return jsonResponse({ error: "Missing guest access token" }, 403);
    }
    if (examAttemptId) {
      await assertCanAccessExamAttempt({
        supabase,
        req,
        attemptId: examAttemptId,
      });
    }

    const refs = await normalizeWritingRefs(supabase, {
      questionId,
      exerciseId,
    });
    const promptText = await fetchWritingPrompt(supabase, refs);
    const rubricType = detectRubricType(promptText);

    const { data: attempt, error: insertErr } = await supabase
      .from("ai_writing_attempts")
      .insert({
        user_id: userId,
        guest_token: userId == null ? guestToken : null,
        exercise_id: refs.exerciseId,
        question_id: refs.questionId,
        exam_attempt_id: examAttemptId,
        prompt_text: promptText,
        answer_text: text,
        rubric_type: rubricType,
        status: "processing",
      })
      .select("id")
      .single();

    if (insertErr || !attempt) {
      throw new Error(
        `Failed to create writing attempt: ${insertErr?.message}`,
      );
    }

    attemptId = String((attempt as Record<string, unknown>)["id"]);
    const apiKey = getOpenAIKey();

    EdgeRuntime.waitUntil(processWritingAttempt({
      supabase,
      attemptId,
      apiKey,
      promptText,
      text,
    }));

    return jsonResponse({ attempt_id: attemptId }, 200);
  } catch (err) {
    console.error("writing-submit error:", err);
    if (attemptId) {
      await markAttemptError(supabase, attemptId, String(err));
    }
    return jsonResponse({ error: String(err) }, 500);
  }
});

async function processWritingAttempt(args: {
  supabase: SupabaseClient;
  attemptId: string;
  apiKey: string;
  promptText: string;
  text: string;
}) {
  const { supabase, attemptId, apiKey, promptText, text } = args;

  try {
    const userMessage =
      `Đề bài: "${promptText}"\n\nBài viết của học viên:\n"${text}"`;
    const rawScored = await chatComplete(
      apiKey,
      WRITING_SYSTEM_PROMPT,
      userMessage,
      { model: getWritingScoringModel(), timeoutMs: 60_000 },
    );
    const scored = await ensureVietnameseUserFacingJson(
      apiKey,
      rawScored,
      "writing.scoring_payload",
    );

    const overallScore = Number(scored["overall_score"] ?? 0);
    const metrics = {
      grammar: Number(scored["grammar"] ?? 0),
      grammar_feedback: String(scored["grammar_feedback"] ?? ""),
      vocabulary: Number(scored["vocabulary"] ?? 0),
      vocabulary_feedback: String(scored["vocabulary_feedback"] ?? ""),
      coherence: Number(scored["coherence"] ?? 0),
      format_feedback: String(scored["format_feedback"] ?? ""),
      task_achievement: Number(scored["task_achievement"] ?? 0),
      content_feedback: String(scored["content_feedback"] ?? ""),
      overall_feedback: String(scored["overall_feedback"] ?? ""),
      short_tips: normalizeTips(scored["short_tips"]),
    };

    const annotatedSpans = normalizeAnnotatedSpans(
      scored["annotated_spans"],
      text,
    );
    const correctedEssay = String(scored["corrected_essay"] ?? "");

    const { error: updateError } = await supabase
      .from("ai_writing_attempts")
      .update({
        status: "ready",
        overall_score: overallScore,
        metrics,
        grammar_notes: annotatedSpans,
        vocabulary_notes: [{ overall_feedback: metrics.overall_feedback }],
        corrected_essay: correctedEssay,
        error_message: null,
        updated_at: new Date().toISOString(),
      })
      .eq("id", attemptId);

    if (updateError) {
      throw new Error(
        `Failed to update writing attempt: ${updateError.message}`,
      );
    }
  } catch (err) {
    console.error("writing-submit background error:", err);
    await markAttemptError(supabase, attemptId, String(err));
  }
}

async function normalizeWritingRefs(
  supabase: SupabaseClient,
  refs: { questionId: string | null; exerciseId: string | null },
): Promise<{ questionId: string | null; exerciseId: string | null }> {
  let questionId = refs.questionId;
  let exerciseId = refs.exerciseId;

  if (!questionId) {
    return { questionId: null, exerciseId };
  }

  const { data: questionRow } = await supabase
    .from("questions")
    .select("id")
    .eq("id", questionId)
    .maybeSingle();

  if (!questionRow) {
    return { questionId: null, exerciseId: exerciseId ?? questionId };
  }

  if (exerciseId === questionId) {
    exerciseId = null;
  }

  return { questionId, exerciseId };
}

async function fetchWritingPrompt(
  supabase: SupabaseClient,
  refs: { questionId: string | null; exerciseId: string | null },
): Promise<string> {
  if (refs.questionId) {
    const { data: question } = await supabase
      .from("questions")
      .select("prompt")
      .eq("id", refs.questionId)
      .maybeSingle();

    return String(
      (question as Record<string, unknown> | null)?.["prompt"] ?? "",
    );
  }

  if (refs.exerciseId) {
    const { data: exercise } = await supabase
      .from("exercises")
      .select("content_json")
      .eq("id", refs.exerciseId)
      .maybeSingle();
    const contentJson = (exercise as Record<string, unknown> | null)
      ?.["content_json"] as Record<string, unknown> | null;
    return String(contentJson?.["prompt"] ?? "");
  }

  return "";
}

async function markAttemptError(
  supabase: SupabaseClient,
  attemptId: string,
  message: string,
) {
  await supabase
    .from("ai_writing_attempts")
    .update({
      status: "error",
      error_message: message,
      updated_at: new Date().toISOString(),
    })
    .eq("id", attemptId);
}

function normalizeAnnotatedSpans(value: unknown, originalText: string) {
  if (!Array.isArray(value) || value.length === 0) {
    return [{ text: originalText, issue_type: null }];
  }

  return value
    .filter((item): item is Record<string, unknown> =>
      typeof item === "object" && item !== null
    )
    .map((item) => {
      const span: Record<string, unknown> = {
        text: String(item["text"] ?? ""),
        issue_type: item["issue_type"] == null
          ? null
          : String(item["issue_type"]),
      };

      if (item["correction"] != null) {
        span["correction"] = String(item["correction"]);
      }
      if (item["explanation"] != null) {
        span["explanation"] = String(item["explanation"]);
      }
      if (item["tip"] != null) {
        span["tip"] = String(item["tip"]);
      }

      return span;
    });
}

function normalizeTips(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((item) => String(item ?? "").trim())
    .filter((item) => item.length > 0)
    .slice(0, 3);
}

function normalizeString(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const normalized = value.trim();
  return normalized.length > 0 ? normalized : null;
}

function jsonResponse(body: unknown, status: number) {
  return new Response(
    JSON.stringify(body),
    {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
}

function detectRubricType(prompt: string): "letter" | "essay" | "form" {
  const p = prompt.toLowerCase();
  if (p.includes("dopis") || p.includes("email") || p.includes("napište")) {
    return "letter";
  }
  if (p.includes("formulář") || p.includes("form")) return "form";
  return "essay";
}
