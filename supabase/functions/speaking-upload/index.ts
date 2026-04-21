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
import {
  ensureVietnameseUserFacingJson,
  inspectUserFacingEnglish,
} from "../_shared/vietnamese_guard.ts";
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
    ? [
      "Giữ giọng nhận xét nghiêm túc, khách quan, ngắn gọn như giám khảo chấm thi.",
      "Không dùng giọng cổ vũ quá mức.",
      "Không coaching trực tiếp trong khi chấm; chỉ nêu lỗi và gợi ý sau đánh giá.",
    ].join(" ")
    : [
      "Giữ giọng nhận xét như giáo viên hướng dẫn: rõ ràng, cụ thể, dễ hiểu.",
      "Ưu tiên lỗi quan trọng nhất và cách sửa thực tế.",
    ].join(" ");

  const evidenceInstruction = scoringMode === "audio_native"
    ? [
      "PHẢI ưu tiên audio làm nguồn chính để chấm pronunciation và fluency.",
      "Transcript chỉ để tham chiếu nội dung.",
      "Nếu audio và transcript mâu thuẫn, ưu tiên audio.",
      "Không suy đoán nếu audio không rõ.",
    ].join(" ")
    : [
      "Chế độ fallback: không có audio trực tiếp.",
      "Dùng transcript làm nguồn chính.",
      "Không được giả định chi tiết phát âm.",
      "Nếu không chắc chắn, phải thể hiện mức độ không chắc.",
    ].join(" ");

  return `
Bạn là giám khảo AI chấm bài nói tiếng Séc cho người Việt luyện thi A2 (Trvalý pobyt).

Mục tiêu:
- chấm công bằng, nhất quán
- chỉ nêu lỗi có cơ sở
- feedback dễ hiểu cho người Việt

${toneInstruction}
${evidenceInstruction}

QUY TẮC NGÔN NGỮ:
- Bài phải bằng TIẾNG SÉC.
- Nếu không phải tiếng Séc:
  - is_czech = false
  - tất cả điểm = 0
  - giải thích bằng tiếng Việt
- Nếu trộn ngôn ngữ:
  - phần lớn là Séc → chấm nhưng trừ điểm
  - không phải Séc → 0 điểm

THANG ĐIỂM:
- 90-100: rất tốt
- 75-89: tốt
- 60-74: đạt
- 40-59: yếu
- 1-39: rất yếu
- 0: sai ngôn ngữ

NGUYÊN TẮC CHẤM:
- grammar: ngữ pháp, trật tự, biến cách, chia động từ, agreement, giới từ
- pronunciation: âm, rõ ràng, âm đặc trưng
- fluency: nhịp nói, ngắt câu tự nhiên, tốc độ nói, độ ngập ngừng
- vocabulary: sử dụng từ phù hợp, đa dạng, đúng ngữ cảnh, tự nhiên
- task_achievement: câu trả lời có liên quan và đáp ứng đúng yêu cầu của câu hỏi không

QUY TẮC overall_score:
- phản ánh khả năng giao tiếp tổng thể
- task_achievement có trọng số cao
- lỗi nặng kéo điểm xuống mạnh
- không lấy trung bình máy móc

PHÂN TÍCH LỖI:
- tối đa 8 lỗi quan trọng
- ưu tiên các lỗi liên quan đến ngữ pháp, từ vựng
- nếu đã có transcript thì lỗi phải map đúng vào transcript
- nếu transcript chưa sẵn sàng thì transcript_issues có thể là []
- không bịa lỗi
- nếu không chắc → nói rõ

FEEDBACK:
- viết bằng tiếng Việt
- corrected_answer bằng tiếng Séc, ngắn, chuẩn A2
- tip ngắn, actionable

OUTPUT JSON (CHỈ JSON):
{
  "detected_language": "<cs|vi|en|...>",
  "is_czech": <boolean>,
  "confidence": "<low|medium|high>",

  "cefr_estimate": "<below_a2|a2|above_a2>",
  "major_issues": ["<vấn đề 1>", "<vấn đề 2>"],
  "next_step_focus": "<1 trọng tâm luyện tập duy nhất cho lần sau>",

  "overall_score": <0-100>,
  "grammar": <0-100>,
  "pronunciation": <0-100>,
  "fluency": <0-100>,
  "vocabulary": <0-100>,
  "task_achievement": <0-100>,

  "transcript_issues": [
    {
      "word": "<từ/cụm>",
      "type": "<pronunciation|grammar|vocabulary>",
      "severity": "<low|medium|high>",
      "suggestion": "<cách sửa>",
      "explanation": "<giải thích tiếng Việt>"
    }
  ],

  "pronunciation_feedback": {
    "detail": "<...>",
    "tip": "<...>"
  },
  "grammar_feedback": {
    "detail": "<...>",
    "tip": "<...>"
  },
  "vocabulary_feedback": {
    "detail": "<...>",
    "tip": "<...>"
  },
  "fluency_feedback": {
    "detail": "<...>",
    "tip": "<...>"
  },
  "content_feedback": {
    "detail": "<...>",
    "tip": "<...>"
  },

  "short_tips": ["<tip1>", "<tip2>", "<tip3>"],

  "overall_feedback": "<nhận xét tổng quan>",
  "corrected_answer": "<câu sửa chuẩn>"
}

RÀNG BUỘC:
- Nếu is_czech = false → tất cả điểm = 0
- transcript_issues ≤ 5
- short_tips ≤ 3
- mỗi tip ≤ 15 từ
- major_issues đúng 1–2 vấn đề quan trọng nhất
- next_step_focus chỉ 1 hành động cụ thể
- không thêm text ngoài JSON
- không bịa lỗi

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

type ScoringMode = "audio_native" | "transcript_fallback";

type ScoringResult = {
  payload: Record<string, unknown>;
  scoringMode: ScoringMode;
  scoringMs: number;
  guardMs: number;
  guardTriggered: boolean;
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
      examAttemptId: exam_attempt_id ?? null,
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
  examAttemptId: string | null;
  apiKey: string;
  audioBytes: Uint8Array;
  audioFormat: string | null;
  questionPrompt: string;
  reviewMode: "exam" | "exercise";
}) {
  const {
    supabase,
    attemptId,
    examAttemptId,
    apiKey,
    audioBytes,
    audioFormat,
    questionPrompt,
    reviewMode,
  } = args;

  const processingStartedAt = Date.now();
  let transcriptionMs: number | null = null;
  let scoringMs: number | null = null;
  let guardMs = 0;
  let guardTriggered = false;
  let scoringMode: ScoringMode = audioFormat === "wav" || audioFormat === "mp3"
    ? "audio_native"
    : "transcript_fallback";

  try {
    const transcriptionFilename = `audio_${attemptId}.${audioFormat ?? "m4a"}`;
    const transcriptionStartedAt = Date.now();
    const transcriptionPromise = transcribeAudio(
      apiKey,
      audioBytes,
      transcriptionFilename,
      { model: getSpeakingTranscriptionModel(), language: "cs" },
    );

    const audioNativePromise = audioFormat === "wav" || audioFormat === "mp3"
      ? scoreSpeakingAudioNative({
        apiKey,
        audioBytes,
        audioFormat: audioFormat as "wav" | "mp3",
        questionPrompt,
        reviewMode,
      }).then((result) => ({ ok: true as const, result })).catch((error) => ({
        ok: false as const,
        error,
      }))
      : null;

    const { text: transcript } = await transcriptionPromise;
    transcriptionMs = Date.now() - transcriptionStartedAt;

    await supabase
      .from("ai_speaking_attempts")
      .update({
        transcript,
        updated_at: new Date().toISOString(),
      })
      .eq("id", attemptId);

    let scoredResult: ScoringResult;
    if (audioNativePromise) {
      const nativeResult = await audioNativePromise;
      if (nativeResult.ok) {
        scoredResult = nativeResult.result;
      } else {
        console.warn(
          `speaking audio-native scoring fallback for ${attemptId}:`,
          nativeResult.error,
        );
        scoredResult = await scoreSpeakingTranscriptFallback({
          apiKey,
          questionPrompt,
          reviewMode,
          transcript,
        });
      }
    } else {
      scoredResult = await scoreSpeakingTranscriptFallback({
        apiKey,
        questionPrompt,
        reviewMode,
        transcript,
      });
    }

    scoringMode = scoredResult.scoringMode;
    scoringMs = scoredResult.scoringMs;
    guardMs = scoredResult.guardMs;
    guardTriggered = scoredResult.guardTriggered;

    const scored = scoredResult.payload;
    const detectedLanguage = String(scored["detected_language"] ?? "unknown");
    const isCzech = scored["is_czech"] === true;
    const overallScore = isCzech ? Number(scored["overall_score"] ?? 0) : 0;
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

    logSpeakingLatency({
      attemptId,
      reviewMode,
      audioFormat,
      scoringMode,
      transcriptionMs,
      scoringMs,
      guardMs,
      guardTriggered,
      totalMs: Date.now() - processingStartedAt,
      status: "ready",
    });

    if (examAttemptId) {
      await regradeExamAttempt(supabase, examAttemptId);
    }
  } catch (error) {
    console.error("speaking background processing error:", error);
    logSpeakingLatency({
      attemptId,
      reviewMode,
      audioFormat,
      scoringMode,
      transcriptionMs,
      scoringMs,
      guardMs,
      guardTriggered,
      totalMs: Date.now() - processingStartedAt,
      status: "error",
      error: String(error),
    });
    await markAttemptError(supabase, attemptId, String(error));
    if (examAttemptId) {
      await regradeExamAttempt(supabase, examAttemptId);
    }
  }
}

async function scoreSpeakingAudioNative(args: {
  apiKey: string;
  audioBytes: Uint8Array;
  audioFormat: "wav" | "mp3";
  questionPrompt: string;
  reviewMode: "exam" | "exercise";
}): Promise<ScoringResult> {
  const {
    apiKey,
    audioBytes,
    audioFormat,
    questionPrompt,
    reviewMode,
  } = args;

  const scoringStartedAt = Date.now();
  const audioPrompt = buildSpeakingUserPrompt({
    questionPrompt,
    reviewMode,
    transcript: null,
  });

  const rawScored = await chatCompleteWithAudio(
    apiKey,
    buildSpeakingSystemPrompt(reviewMode, "audio_native"),
    audioPrompt,
    audioBytes,
    audioFormat,
    { model: getSpeakingAudioModel(), timeoutMs: 60_000 },
  );
  const normalized = await normalizeSpeakingScoringPayload(apiKey, rawScored);
  return {
    payload: { ...normalized.payload, scoring_mode: "audio_native" },
    scoringMode: "audio_native",
    scoringMs: Date.now() - scoringStartedAt,
    guardMs: normalized.guardMs,
    guardTriggered: normalized.guardTriggered,
  };
}

async function scoreSpeakingTranscriptFallback(args: {
  apiKey: string;
  questionPrompt: string;
  reviewMode: "exam" | "exercise";
  transcript: string;
}): Promise<ScoringResult> {
  const { apiKey, questionPrompt, reviewMode, transcript } = args;
  const scoringStartedAt = Date.now();
  const transcriptPrompt = buildSpeakingUserPrompt({
    questionPrompt,
    reviewMode,
    transcript,
  });

  const rawScored = await chatComplete(
    apiKey,
    buildSpeakingSystemPrompt(reviewMode, "transcript_fallback"),
    transcriptPrompt,
    { model: getSpeakingScoringModel(), timeoutMs: 45_000 },
  );
  const normalized = await normalizeSpeakingScoringPayload(apiKey, rawScored);
  return {
    payload: { ...normalized.payload, scoring_mode: "transcript_fallback" },
    scoringMode: "transcript_fallback",
    scoringMs: Date.now() - scoringStartedAt,
    guardMs: normalized.guardMs,
    guardTriggered: normalized.guardTriggered,
  };
}

async function normalizeSpeakingScoringPayload(
  apiKey: string,
  payload: Record<string, unknown>,
): Promise<{
  payload: Record<string, unknown>;
  guardMs: number;
  guardTriggered: boolean;
}> {
  const inspection = inspectUserFacingEnglish(payload);
  const guardTriggered = inspection.suspiciousCount > 0;
  const guardStartedAt = Date.now();
  const normalized = await ensureVietnameseUserFacingJson(
    apiKey,
    payload,
    "speaking.scoring_payload",
  );
  return {
    payload: normalized,
    guardMs: Date.now() - guardStartedAt,
    guardTriggered,
  };
}

function buildSpeakingUserPrompt(args: {
  questionPrompt: string;
  reviewMode: "exam" | "exercise";
  transcript: string | null;
}): string {
  const { questionPrompt, transcript, reviewMode } = args;
  const contextLabel = reviewMode === "exam"
    ? "mock test / exam speaking review"
    : "lesson / practice speaking review";

  const lines = [
    `Ngữ cảnh: ${contextLabel}.`,
    `Câu hỏi thi: "${questionPrompt}"`,
  ];

  if (transcript != null) {
    lines.push(
      "Transcript bài nói của học viên (để hiển thị lại trong review):",
      `"${transcript}"`,
      "Nếu transcript và audio không khớp hoàn toàn, hãy chấm pronunciation/fluency theo audio, và dùng transcript để map lỗi + corrected answer.",
    );
  } else {
    lines.push(
      "Transcript chưa sẵn sàng ở bước chấm audio-native song song.",
      "Hãy chấm các tiêu chí dựa trên audio và câu hỏi.",
      "Nếu chưa có transcript thì transcript_issues có thể là [] và không được bịa lỗi theo từng token.",
    );
  }

  return lines.join("\n\n");
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

async function regradeExamAttempt(
  supabase: SupabaseClient,
  examAttemptId: string,
) {
  try {
    await supabase.functions.invoke("grade-exam", {
      body: { attempt_id: examAttemptId },
    });
  } catch (error) {
    console.warn("speaking-upload regrade trigger failed:", error);
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

function logSpeakingLatency(args: {
  attemptId: string;
  reviewMode: "exam" | "exercise";
  audioFormat: string | null;
  scoringMode: ScoringMode;
  transcriptionMs: number | null;
  scoringMs: number | null;
  guardMs: number;
  guardTriggered: boolean;
  totalMs: number;
  status: "ready" | "error";
  error?: string;
}) {
  const payload: Record<string, unknown> = {
    event: "speaking_processing_latency",
    attempt_id: args.attemptId,
    review_mode: args.reviewMode,
    audio_format: args.audioFormat,
    scoring_mode: args.scoringMode,
    transcription_ms: args.transcriptionMs,
    scoring_ms: args.scoringMs,
    guard_ms: args.guardMs,
    guard_triggered: args.guardTriggered,
    total_ms: args.totalMs,
    status: args.status,
  };

  if (args.error) {
    payload.error = args.error.slice(0, 300);
  }

  console.log(JSON.stringify(payload));
}

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
