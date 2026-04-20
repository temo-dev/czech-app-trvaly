import { corsHeaders } from "../_shared/cors.ts";
import {
  chatComplete,
  chatCompleteWithAudio,
  getOpenAIKey,
  getSpeakingAudioModel,
  getSpeakingScoringModel,
  getSpeakingTranscriptionModel,
  transcribeAudio,
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

function buildSpeakingSystemPrompt(
  reviewMode: "exam" | "exercise",
  scoringMode: "audio_native" | "transcript_fallback",
): string {
  const toneInstruction = reviewMode === "exam"
    ? "Giữ giọng nhận xét nghiêm túc, ngắn gọn, giống review bài thi. Không coaching trong lúc làm bài."
    : "Giữ giọng nhận xét mang tính hướng dẫn học tập hơn, giải thích rõ lỗi và cách sửa.";
  const evidenceInstruction = scoringMode === "audio_native"
    ? "Bạn PHẢI nghe audio để chấm pronunciation và fluency. Transcript chỉ dùng để hiển thị lại cho học viên và hỗ trợ phân tích nội dung. Nếu audio và transcript mâu thuẫn, ưu tiên audio."
    : "Bạn đang ở chế độ fallback không có audio trực tiếp. Hãy chấm thận trọng hơn và ghi nhận nội dung transcript làm tín hiệu chính, nhưng vẫn cố giữ rubric speaking nhất quán.";

  return `
Bạn là giám khảo chấm điểm bài thi nói tiếng Séc cho người học người Việt Nam.
Người học đang luyện thi kỳ thi trình độ A2 để xin trạng thái Trvalý pobyt (cư trú lâu dài) tại Cộng hòa Séc.

${toneInstruction}
${evidenceInstruction}

⚠️ QUY TẮC QUAN TRỌNG NHẤT: Bài thi YÊU CẦU trả lời bằng TIẾNG SÉC.
- Nếu bài nói KHÔNG phải tiếng Séc (tiếng Anh, tiếng Việt, hoặc ngôn ngữ khác), hãy cho điểm 0 tất cả các tiêu chí và giải thích rõ lý do bằng tiếng Việt.
- Chỉ chấm điểm bình thường khi bài nói thực sự là tiếng Séc.

Tiêu chí chấm (chỉ áp dụng khi bài nói là tiếng Séc):
- pronunciation (phát âm): 0–100 — độ rõ ràng, chính xác và mức tự nhiên của âm thanh tiếng Séc
- fluency (độ lưu loát): 0–100 — nhịp nói, ngắt câu tự nhiên, tốc độ nói, độ ngập ngừng
- vocabulary (từ vựng): 0–100 — sử dụng từ phù hợp, đa dạng, đúng ngữ cảnh
- task_achievement (trả lời đúng câu hỏi): 0–100 — câu trả lời có liên quan và đáp ứng đúng yêu cầu của câu hỏi không

Lưu ý với bài tiếng Séc: Người học nói tiếng Việt là tiếng mẹ đẻ, những lỗi điển hình bao gồm:
dấu thanh tiếng Séc (háček), phụ âm đặc biệt (ř, č, ž, š), trật tự từ, giới từ, và các đuôi danh từ biến cách.

Hãy trả về JSON theo đúng định dạng sau (không có văn bản nào khác):
{
  "detected_language": "<ISO-639-1 hoặc tên ngôn ngữ dễ hiểu, ví dụ cs / vi / en / czech>",
  "is_czech": <true nếu bài nói là tiếng Séc, false nếu không phải>,
  "overall_score": <int 0-100, bắt buộc là 0 nếu is_czech = false>,
  "pronunciation": <int 0-100, bắt buộc là 0 nếu is_czech = false>,
  "fluency": <int 0-100, bắt buộc là 0 nếu is_czech = false>,
  "vocabulary": <int 0-100, bắt buộc là 0 nếu is_czech = false>,
  "task_achievement": <int 0-100, bắt buộc là 0 nếu is_czech = false>,
  "transcript_issues": [
    {
      "word": "<1 từ/cụm ngắn có mặt trong transcript>",
      "type": "<pronunciation|grammar|vocabulary>",
      "suggestion": "<cách sửa ngắn gọn>",
      "explanation": "<vì sao đây là lỗi, bằng tiếng Việt>"
    }
  ],
  "pronunciation_feedback": {
    "detail": "<Nếu không phải tiếng Séc: để trống. Nếu tiếng Séc: nhận xét CHI TIẾT về phát âm, liệt kê lỗi cụ thể.>",
    "tip": "<Lời khuyên ngắn 1 câu, actionable: cách luyện phát âm đúng. Để trống nếu không phải tiếng Séc.>"
  },
  "grammar_feedback": {
    "detail": "<Nếu không phải tiếng Séc: để trống. Nếu tiếng Séc: nhận xét CHI TIẾT về ngữ pháp.>",
    "tip": "<Lời khuyên ngắn 1 câu về ngữ pháp. Để trống nếu không phải tiếng Séc.>"
  },
  "vocabulary_feedback": {
    "detail": "<Nếu không phải tiếng Séc: để trống. Nếu tiếng Séc: nhận xét CHI TIẾT về từ vựng.>",
    "tip": "<Lời khuyên ngắn 1 câu về từ vựng. Để trống nếu không phải tiếng Séc.>"
  },
  "fluency_feedback": {
    "detail": "<Nếu không phải tiếng Séc: để trống. Nếu tiếng Séc: nhận xét CHI TIẾT về độ lưu loát: nhịp nói, ngắt câu, ngập ngừng.>",
    "tip": "<Lời khuyên ngắn 1 câu về cách nói lưu loát hơn. Để trống nếu không phải tiếng Séc.>"
  },
  "content_feedback": {
    "detail": "<Nếu không phải tiếng Séc: để trống. Nếu tiếng Séc: nhận xét về nội dung và mức độ trả lời đúng câu hỏi.>",
    "tip": "<Lời khuyên ngắn 1 câu về nội dung/cách trả lời. Để trống nếu không phải tiếng Séc.>"
  },
  "short_tips": ["<tip1 ngắn gọn>", "<tip2 ngắn gọn>", "<tip3 ngắn gọn>"],
  "overall_feedback": "<Nếu không phải tiếng Séc: giải thích rõ bằng tiếng Việt rằng bài thi yêu cầu trả lời bằng tiếng Séc, không chấp nhận ngôn ngữ khác. Nếu tiếng Séc: nhận xét tổng quan 2-3 câu.>",
  "corrected_answer": "<Nếu không phải tiếng Séc: để trống hoặc đưa 1 mẫu ngắn phù hợp. Nếu tiếng Séc: câu trả lời đã sửa hoàn chỉnh bằng tiếng Séc.>"
}

Lưu ý: short_tips là tối đa 3 lời khuyên ngắn gọn, mỗi tip tối đa 15 từ, ưu tiên lỗi cần sửa nhất. Để trống array [] nếu không phải tiếng Séc.

${VIETNAMESE_FEEDBACK_REQUIREMENT}
`.trim();
}

type SpeakingUploadBody = {
  lesson_id?: string;
  question_id?: string;
  exercise_id?: string;
  audio_b64?: string;
  audio_format?: string;
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
    const body = await req.json() as SpeakingUploadBody;
    const {
      question_id,
      exercise_id: bodyExerciseId,
      audio_b64,
      audio_format,
      exam_attempt_id,
    } = body;

    if (!question_id && !bodyExerciseId) {
      return jsonResponse({ error: "question_id is required" }, 400);
    }

    const userId = await getAuthUserId(supabase, req);
    const guestToken = getGuestToken(req);
    if (userId == null && guestToken == null) {
      return jsonResponse({ error: "Missing guest access token" }, 403);
    }
    if (exam_attempt_id) {
      await assertCanAccessExamAttempt({
        supabase,
        req,
        attemptId: exam_attempt_id,
      });
    }

    const refs = await normalizeSpeakingRefs(supabase, {
      questionId: question_id ?? null,
      exerciseId: bodyExerciseId ?? null,
    });
    const questionPrompt = await fetchQuestionPrompt(supabase, refs);

    const { data: attempt, error: insertErr } = await supabase
      .from("ai_speaking_attempts")
      .insert({
        user_id: userId,
        guest_token: userId == null ? guestToken : null,
        exercise_id: refs.exerciseId,
        question_id: refs.questionId,
        exam_attempt_id: exam_attempt_id ?? null,
        audio_key: null,
        status: "processing",
      })
      .select("id")
      .single();

    if (insertErr || !attempt) {
      throw new Error(`Failed to create attempt: ${insertErr?.message}`);
    }

    attemptId = String((attempt as Record<string, unknown>)["id"]);

    if (!audio_b64 || audio_b64.length === 0) {
      await markAttemptError(
        supabase,
        attemptId,
        "No audio data provided",
      );
      return jsonResponse(
        { attempt_id: attemptId, error: "No audio data" },
        200,
      );
    }

    const audioBytes = Uint8Array.from(atob(audio_b64), (c) => c.charCodeAt(0));
    const apiKey = getOpenAIKey();

    EdgeRuntime.waitUntil(processSpeakingAttempt({
      supabase,
      attemptId,
      apiKey,
      audioBytes,
      audioFormat: normalizeAudioFormat(audio_format),
      questionPrompt,
      reviewMode: exam_attempt_id ? "exam" : "exercise",
    }));

    return jsonResponse({ attempt_id: attemptId }, 200);
  } catch (err) {
    console.error("speaking-upload error:", err);
    if (attemptId) {
      await markAttemptError(supabase, attemptId, String(err));
    }
    return jsonResponse({ error: String(err) }, 500);
  }
});

async function processSpeakingAttempt(args: {
  supabase: SupabaseClient;
  attemptId: string;
  apiKey: string;
  audioBytes: Uint8Array;
  audioFormat: string | null;
  questionPrompt: string;
  reviewMode: "exam" | "exercise";
}) {
  const {
    supabase,
    attemptId,
    apiKey,
    audioBytes,
    audioFormat,
    questionPrompt,
    reviewMode,
  } = args;

  try {
    const transcriptionFilename = `audio_${attemptId}.${audioFormat ?? "m4a"}`;
    const { text: transcript } = await transcribeAudio(
      apiKey,
      audioBytes,
      transcriptionFilename,
      { model: getSpeakingTranscriptionModel() },
    );

    const scored = await scoreSpeakingAttempt({
      apiKey,
      audioBytes,
      audioFormat,
      questionPrompt,
      reviewMode,
      transcript,
      attemptId,
    });
    const detectedLanguage = String(scored["detected_language"] ?? "unknown");
    const isCzech = scored["is_czech"] === true;
    const overallScore = isCzech ? Number(scored["overall_score"] ?? 0) : 0;
    const scoringMode = String(
      scored["scoring_mode"] ??
        (audioFormat === "wav" || audioFormat === "mp3"
          ? "audio_native"
          : "transcript_fallback"),
    );
    const nonCzechFeedback = isCzech ? "" : String(
      scored["overall_feedback"] ??
        `Bài thi yêu cầu trả lời bằng tiếng Séc. Ngôn ngữ phát hiện: "${detectedLanguage}". Vui lòng thử lại bằng tiếng Séc.`,
    );

    const metrics = {
      pronunciation: isCzech ? Number(scored["pronunciation"] ?? 0) : 0,
      pronunciation_feedback: isCzech
        ? getFeedbackDetail(scored["pronunciation_feedback"])
        : "",
      pronunciation_tip: isCzech
        ? getFeedbackTip(scored["pronunciation_feedback"])
        : "",
      fluency: isCzech ? Number(scored["fluency"] ?? 0) : 0,
      fluency_feedback: isCzech
        ? getFeedbackDetail(scored["fluency_feedback"])
        : "",
      fluency_tip: isCzech ? getFeedbackTip(scored["fluency_feedback"]) : "",
      vocabulary: isCzech ? Number(scored["vocabulary"] ?? 0) : 0,
      vocabulary_feedback: isCzech
        ? getFeedbackDetail(scored["vocabulary_feedback"])
        : "",
      vocabulary_tip: isCzech
        ? getFeedbackTip(scored["vocabulary_feedback"])
        : "",
      task_achievement: isCzech ? Number(scored["task_achievement"] ?? 0) : 0,
      content_feedback: isCzech
        ? getFeedbackDetail(scored["content_feedback"])
        : "",
      content_tip: isCzech ? getFeedbackTip(scored["content_feedback"]) : "",
      grammar_feedback: isCzech
        ? getFeedbackDetail(scored["grammar_feedback"])
        : "",
      grammar_tip: isCzech ? getFeedbackTip(scored["grammar_feedback"]) : "",
      overall_feedback: isCzech
        ? String(scored["overall_feedback"] ?? "")
        : nonCzechFeedback,
      short_tips: isCzech ? normalizeTips(scored["short_tips"]) : [],
      detected_language: detectedLanguage,
      review_mode: reviewMode,
      scoring_mode: scoringMode,
    };
    const issues = (scored["transcript_issues"] as Array<
      {
        word: string;
        type?: string;
        suggestion?: string;
        explanation?: string;
      }
    >) ?? [];
    const correctedAnswer = String(scored["corrected_answer"] ?? "");

    await supabase
      .from("ai_speaking_attempts")
      .update({
        status: "ready",
        transcript,
        overall_score: overallScore,
        metrics,
        issues,
        strengths: [],
        improvements: [],
        corrected_answer: correctedAnswer,
        updated_at: new Date().toISOString(),
      })
      .eq("id", attemptId);
  } catch (error) {
    console.error("speaking background processing error:", error);
    await markAttemptError(supabase, attemptId, String(error));
  }
}

async function scoreSpeakingAttempt(args: {
  apiKey: string;
  audioBytes: Uint8Array;
  audioFormat: string | null;
  questionPrompt: string;
  reviewMode: "exam" | "exercise";
  transcript: string;
  attemptId: string;
}): Promise<Record<string, unknown>> {
  const {
    apiKey,
    audioBytes,
    audioFormat,
    questionPrompt,
    reviewMode,
    transcript,
    attemptId,
  } = args;

  const transcriptPrompt = buildSpeakingUserPrompt({
    questionPrompt,
    transcript,
    reviewMode,
  });

  if (audioFormat === "wav" || audioFormat === "mp3") {
    try {
      const rawScored = await chatCompleteWithAudio(
        apiKey,
        buildSpeakingSystemPrompt(reviewMode, "audio_native"),
        transcriptPrompt,
        audioBytes,
        audioFormat,
        { model: getSpeakingAudioModel(), timeoutMs: 60_000 },
      );
      const scored = await ensureVietnameseUserFacingJson(
        apiKey,
        rawScored,
        "speaking.scoring_payload",
      );
      return { ...scored, scoring_mode: "audio_native" };
    } catch (error) {
      console.warn(
        `speaking audio-native scoring fallback for ${attemptId}:`,
        error,
      );
    }
  }

  const rawScored = await chatComplete(
    apiKey,
    buildSpeakingSystemPrompt(reviewMode, "transcript_fallback"),
    transcriptPrompt,
    { model: getSpeakingScoringModel(), timeoutMs: 45_000 },
  );
  const scored = await ensureVietnameseUserFacingJson(
    apiKey,
    rawScored,
    "speaking.scoring_payload",
  );
  return { ...scored, scoring_mode: "transcript_fallback" };
}

function buildSpeakingUserPrompt(args: {
  questionPrompt: string;
  transcript: string;
  reviewMode: "exam" | "exercise";
}): string {
  const { questionPrompt, transcript, reviewMode } = args;
  const contextLabel = reviewMode === "exam"
    ? "mock test / exam speaking review"
    : "lesson / practice speaking review";

  return [
    `Ngữ cảnh: ${contextLabel}.`,
    `Câu hỏi thi: "${questionPrompt}"`,
    "Transcript bài nói của học viên (để hiển thị lại trong review):",
    `"${transcript}"`,
    "Nếu transcript và audio không khớp hoàn toàn, hãy chấm pronunciation/fluency theo audio, và dùng transcript để map lỗi + corrected answer.",
  ].join("\n\n");
}

async function normalizeSpeakingRefs(
  supabase: SupabaseClient,
  refs: { questionId: string | null; exerciseId: string | null },
): Promise<{ questionId: string | null; exerciseId: string | null }> {
  let validQuestionId = refs.questionId;
  let validExerciseId = refs.exerciseId;

  if (refs.questionId) {
    const { data: questionRow } = await supabase
      .from("questions")
      .select("id")
      .eq("id", refs.questionId)
      .maybeSingle();

    if (!questionRow) {
      validExerciseId = validExerciseId ?? refs.questionId;
      validQuestionId = null;
    } else if (validExerciseId === refs.questionId) {
      validExerciseId = null;
    }
  }

  return {
    questionId: validQuestionId,
    exerciseId: validExerciseId,
  };
}

async function fetchQuestionPrompt(
  supabase: SupabaseClient,
  refs: { questionId: string | null; exerciseId: string | null },
): Promise<string> {
  if (refs.questionId) {
    const { data: question } = await supabase
      .from("questions")
      .select("prompt")
      .eq("id", refs.questionId)
      .maybeSingle();
    return (question as Record<string, unknown> | null)?.["prompt"] as string ??
      "";
  }

  if (refs.exerciseId) {
    const { data: exercise } = await supabase
      .from("exercises")
      .select("content_json")
      .eq("id", refs.exerciseId)
      .maybeSingle();
    const contentJson = (exercise as Record<string, unknown> | null)
      ?.["content_json"] as
        | Record<string, unknown>
        | null;
    return (contentJson?.["prompt"] as string) ?? "";
  }

  return "";
}

async function markAttemptError(
  supabase: SupabaseClient,
  attemptId: string,
  message: string,
) {
  try {
    await supabase
      .from("ai_speaking_attempts")
      .update({
        status: "error",
        error_message: message,
        updated_at: new Date().toISOString(),
      })
      .eq("id", attemptId);
  } catch (_) {
    // best-effort only
  }
}

function getFeedbackDetail(val: unknown): string {
  if (typeof val === "string") return val;
  if (val && typeof val === "object") {
    return String((val as Record<string, unknown>)["detail"] ?? "");
  }
  return "";
}

function getFeedbackTip(val: unknown): string {
  if (val && typeof val === "object") {
    return String((val as Record<string, unknown>)["tip"] ?? "");
  }
  return "";
}

function normalizeTips(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => String(item ?? "").trim())
    .filter((item) => item.length > 0)
    .slice(0, 3);
}

function normalizeAudioFormat(value: unknown): string | null {
  const format = String(value ?? "").trim().toLowerCase();
  if (!format) return null;
  if (format === "wav" || format === "mp3" || format === "m4a") {
    return format;
  }
  return null;
}

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
