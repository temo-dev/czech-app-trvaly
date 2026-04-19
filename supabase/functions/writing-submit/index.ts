import { corsHeaders } from "../_shared/cors.ts";
import { chatComplete, getOpenAIKey } from "../_shared/openai.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  assertCanAccessExamAttempt,
  getAuthUserId,
  getGuestToken,
} from "../_shared/guest_access.ts";

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

  try {
    const body = await req.json() as {
      text?: string;
      question_id?: string;
      lesson_id?: string;
      exam_attempt_id?: string;
    };

    const { text, question_id, exam_attempt_id } = body;

    if (!text || !question_id) {
      return new Response(
        JSON.stringify({ error: "text and question_id are required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const userId = await getAuthUserId(supabase, req);
    const guestToken = getGuestToken(req);
    if (userId == null && guestToken == null) {
      return new Response(
        JSON.stringify({ error: "Missing guest access token" }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }
    if (exam_attempt_id) {
      await assertCanAccessExamAttempt({
        supabase,
        req,
        attemptId: exam_attempt_id,
      });
    }

    // Fetch question prompt
    const { data: question } = await supabase
      .from("questions")
      .select("prompt")
      .eq("id", question_id)
      .maybeSingle();

    const promptText =
      (question as Record<string, unknown> | null)?.["prompt"] as string ?? "";
    const rubricType = detectRubricType(promptText);

    // Insert attempt row
    const { data: attempt, error: insertErr } = await supabase
      .from("ai_writing_attempts")
      .insert({
        user_id: userId,
        guest_token: userId == null ? guestToken : null,
        exercise_id: null,
        question_id: question_id ?? null,
        exam_attempt_id: exam_attempt_id ?? null,
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

    attemptId = (attempt as Record<string, unknown>)["id"] as string;
    const apiKey = getOpenAIKey();

    // Score with GPT-4o-mini
    const userMessage =
      `Đề bài: "${promptText}"\n\nBài viết của học viên:\n"${text}"`;
    const scored = await chatComplete(
      apiKey,
      WRITING_SYSTEM_PROMPT,
      userMessage,
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
      short_tips: (scored["short_tips"] as string[]) ?? [],
    };

    const annotatedSpans = (scored["annotated_spans"] as unknown[]) ??
      [{ text, issue_type: null }];
    const correctedEssay = String(scored["corrected_essay"] ?? "");

    await supabase
      .from("ai_writing_attempts")
      .update({
        status: "ready",
        overall_score: overallScore,
        metrics,
        grammar_notes: annotatedSpans,
        vocabulary_notes: [{ overall_feedback: metrics.overall_feedback }],
        corrected_essay: correctedEssay,
        updated_at: new Date().toISOString(),
      })
      .eq("id", attemptId);

    return new Response(
      JSON.stringify({ attempt_id: attemptId }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (err) {
    console.error("writing-submit error:", err);
    if (attemptId) {
      try {
        await supabase
          .from("ai_writing_attempts")
          .update({
            status: "error",
            error_message: String(err),
            updated_at: new Date().toISOString(),
          })
          .eq("id", attemptId);
      } catch (_) { /* best-effort */ }
    }
    return new Response(
      JSON.stringify({ error: String(err) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

function detectRubricType(prompt: string): "letter" | "essay" | "form" {
  const p = prompt.toLowerCase();
  if (p.includes("dopis") || p.includes("email") || p.includes("napište")) {
    return "letter";
  }
  if (p.includes("formulář") || p.includes("form")) return "form";
  return "essay";
}
