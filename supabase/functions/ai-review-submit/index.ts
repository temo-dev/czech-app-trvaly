import {
  createClient,
  type SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import {
  chatComplete,
  getObjectiveReviewModel,
  getOpenAIKey,
} from "../_shared/openai.ts";
import { VIETNAMESE_FEEDBACK_REQUIREMENT } from "../_shared/vietnamese.ts";
import {
  buildSpeakingReviewPayload,
  buildWritingReviewPayload,
  getRequesterContext,
  type ReviewPayload,
} from "../_shared/ai_teacher.ts";
import {
  assertCanAccessExamAttempt,
  assertCanAccessOwnedRow,
} from "../_shared/guest_access.ts";
import { ensureVietnameseUserFacingJson } from "../_shared/vietnamese_guard.ts";

const OBJECTIVE_REVIEW_PROMPT = `
Bạn là giáo viên tiếng Séc cho người học Việt Nam đang luyện thi Trvalý pobyt A2.

Nhiệm vụ:
- Nếu học viên làm đúng: củng cố ngắn gọn vì sao đúng và mẹo nhớ.
- Nếu học viên làm sai: chỉ ra chính xác vì sao sai, sửa như thế nào, và nên luyện gì tiếp theo.

Trả về JSON đúng định dạng:
{
  "summary": "<Nhận xét tổng quan 1-2 câu bằng tiếng Việt>",
  "reinforcement": "<Nếu làm đúng: 1 câu củng cố ngắn. Nếu sai: để trống>",
  "criteria": [
    { "title": "Độ chính xác", "score": <0-100>, "max_score": 100, "feedback": "<giải thích ngắn>", "tip": "<mẹo ngắn>" }
  ],
  "mistakes": [
    { "title": "<tên lỗi>", "explanation": "<vì sao sai>", "correction": "<cách sửa>", "tip": "<mẹo tránh lặp lại>" }
  ],
  "suggestions": [
    { "title": "<ngắn gọn>", "detail": "<gợi ý luyện tiếp>" }
  ],
  "corrected_answer": "<đáp án/cách diễn đạt đúng gọn gàng>"
}

Yêu cầu:
- Tất cả bằng tiếng Việt, có thể trích tiếng Séc khi cần.
- Không dùng lời khen sáo rỗng.
- Nếu làm đúng, mistakes có thể là [].
- Nếu làm sai, reinforcement phải để trống.

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

  try {
    const body = await req.json() as {
      source?: string;
      question_id?: string;
      exercise_id?: string;
      lesson_id?: string;
      exam_attempt_id?: string;
      selected_option_id?: string;
      written_answer?: string;
      ai_attempt_id?: string;
    };

    const source = body.source ?? "practice";
    const rawQuestionId = body.question_id;
    if (!rawQuestionId && !body.exercise_id) {
      return jsonResponse({ error: "question_id is required" }, 400);
    }

    const requester = await getRequesterContext(supabase, req);
    if (requester.userId == null && requester.guestToken == null) {
      return jsonResponse({ error: "Missing guest access token" }, 403);
    }
    if (body.exam_attempt_id) {
      await assertCanAccessExamAttempt({
        supabase,
        req,
        attemptId: body.exam_attempt_id,
      });
    }

    // Validate that question_id actually exists in the questions table.
    // Clients from the exercise flow pass the exercise UUID as question_id.
    let validQuestionId: string | null = null;
    let validExerciseId: string | null = body.exercise_id ?? null;
    if (rawQuestionId) {
      const { data: qRow } = await supabase
        .from("questions")
        .select("id")
        .eq("id", rawQuestionId)
        .maybeSingle();
      if (qRow) {
        validQuestionId = rawQuestionId;
      } else {
        // rawQuestionId is an exercise ID sent by older client code
        validExerciseId = validExerciseId ?? rawQuestionId;
      }
    }
    // questionId used for access checks and request key (raw client value for idempotency)
    const questionId = rawQuestionId ?? body.exercise_id!;

    const requestKey = JSON.stringify({
      requester_id: requester.userId ?? "anon",
      guest_token: requester.userId == null ? requester.guestToken : null,
      source,
      question_id: questionId,
      exercise_id: body.exercise_id ?? null,
      lesson_id: body.lesson_id ?? null,
      exam_attempt_id: body.exam_attempt_id ?? null,
      selected_option_id: body.selected_option_id ?? null,
      written_answer: body.written_answer ?? null,
      ai_attempt_id: body.ai_attempt_id ?? null,
    });

    const { data: existing } = await supabase
      .from("ai_teacher_reviews")
      .select("id, status")
      .eq("request_key", requestKey)
      .maybeSingle();

    if (existing) {
      const existingRow = existing as Record<string, unknown>;
      if (existingRow["status"] !== "error") {
        return jsonResponse({ review_id: existingRow["id"] }, 200);
      }
      // Delete the errored row so we can re-create it below.
      await supabase
        .from("ai_teacher_reviews")
        .delete()
        .eq("id", existingRow["id"]);
    }

    if (body.ai_attempt_id) {
      const subjective = await createSubjectiveReview({
        supabase,
        requestKey,
        requester,
        body,
        source,
        validQuestionId,
        validExerciseId,
      });
      return jsonResponse(subjective, 200);
    }

    const { data: question } = await supabase
      .from("questions")
      .select(
        "id, type, skill, prompt, explanation, correct_answer, accepted_answers, question_options(id, text, is_correct, order_index)",
      )
      .eq("id", validQuestionId ?? questionId)
      .single();

    const questionRow = question as Record<string, unknown>;
    const payload = await buildObjectiveReviewPayload({
      source,
      question: questionRow,
      selectedOptionId: body.selected_option_id ?? null,
      writtenAnswer: body.written_answer ?? null,
    });

    // Insert as "processing" first so the row never exists in a ready+null-payload state.
    const inserted = await insertReviewRow({
      supabase,
      requestKey,
      requester,
      source,
      questionId,
      exerciseId: body.exercise_id ?? null,
      lessonId: body.lesson_id ?? null,
      examAttemptId: body.exam_attempt_id ?? null,
      modality: "objective",
      status: "processing",
      verdict: null,
      resultPayload: null,
      inputPayload: {
        selected_option_id: body.selected_option_id ?? null,
        written_answer: body.written_answer ?? null,
      },
    });

    const finalPayload = {
      ...payload,
      review_id: inserted.id,
      source,
    };
    const { error: updateError } = await supabase
      .from("ai_teacher_reviews")
      .update({
        status: "ready",
        verdict: payload.verdict,
        result_payload: finalPayload,
        updated_at: new Date().toISOString(),
      })
      .eq("id", inserted.id);

    if (updateError) {
      throw new Error(`Failed to finalize review: ${updateError.message}`);
    }

    return jsonResponse({ review_id: inserted.id }, 200);
  } catch (err) {
    console.error("ai-review-submit error:", err);
    return jsonResponse({ error: String(err) }, 500);
  }
});

async function createSubjectiveReview(args: {
  supabase: SupabaseClient;
  requestKey: string;
  requester: {
    userId: string | null;
    guestToken: string | null;
    accessLevel: "basic" | "premium";
  };
  body: {
    exercise_id?: string;
    lesson_id?: string;
    exam_attempt_id?: string;
    ai_attempt_id?: string;
  };
  source: string;
  validQuestionId: string | null;
  validExerciseId: string | null;
}): Promise<{ review_id: string }> {
  const {
    supabase,
    requestKey,
    requester,
    body,
    source,
    validQuestionId,
    validExerciseId,
  } = args;
  const attemptId = body.ai_attempt_id!;
  const apiKey = getOpenAIKey();

  let writingPayload: ReviewPayload | null = null;
  const { data: writingAttempt } = await supabase
    .from("ai_writing_attempts")
    .select("*")
    .eq("id", attemptId)
    .maybeSingle();

  if (writingAttempt) {
    const row = writingAttempt as Record<string, unknown>;
    await ensureRequesterCanAccessSubjectiveAttempt({
      supabase,
      requester,
      row,
      questionId: validQuestionId,
      requestExamAttemptId: body.exam_attempt_id ?? null,
    });
    const resolvedRefs = await normalizeReviewReferences(supabase, {
      questionId: normalizeString(row["question_id"]) ?? validQuestionId,
      exerciseId: normalizeString(row["exercise_id"]) ??
        validExerciseId ??
        body.exercise_id ??
        null,
    });
    if (row["status"] === "ready") {
      writingPayload = await ensureVietnameseUserFacingJson(
        apiKey,
        buildWritingReviewPayload({
          reviewId: "",
          source,
          row,
        }),
        "writing.teacher_review_subjective",
      );
    }
    const inserted = await insertReviewRow({
      supabase,
      requestKey,
      requester,
      source,
      questionId: resolvedRefs.questionId,
      exerciseId: resolvedRefs.exerciseId,
      lessonId: body.lesson_id ?? null,
      examAttemptId: (row["exam_attempt_id"] as string | null) ??
        body.exam_attempt_id ?? null,
      modality: "writing",
      status: row["status"] === "ready"
        ? "ready"
        : row["status"] === "error"
          ? "error"
          : "processing",
      verdict: writingPayload?.verdict ?? null,
      resultPayload: writingPayload,
      inputPayload: { ai_attempt_id: attemptId },
      writingAttemptId: attemptId,
      errorMessage: row["status"] === "error"
        ? String(row["error_message"] ?? "Không thể tạo teacher review.")
        : null,
    });
    if (row["status"] === "ready") {
      const payload = await ensureVietnameseUserFacingJson(
        apiKey,
        buildWritingReviewPayload({
          reviewId: inserted.id,
          source,
          row,
        }),
        "writing.teacher_review_subjective",
      );
      await supabase
        .from("ai_teacher_reviews")
        .update({
          result_payload: payload,
          verdict: payload.verdict,
          updated_at: new Date().toISOString(),
        })
        .eq("id", inserted.id);
    }
    return { review_id: inserted.id };
  }

  const { data: speakingAttempt } = await supabase
    .from("ai_speaking_attempts")
    .select("*")
    .eq("id", attemptId)
    .maybeSingle();

  if (!speakingAttempt) {
    throw new Error("AI attempt not found");
  }

  const row = speakingAttempt as Record<string, unknown>;
  await ensureRequesterCanAccessSubjectiveAttempt({
    supabase,
    requester,
    row,
    questionId: validQuestionId,
    requestExamAttemptId: body.exam_attempt_id ?? null,
  });
  const resolvedRefs = await normalizeReviewReferences(supabase, {
    questionId: normalizeString(row["question_id"]) ?? validQuestionId,
    exerciseId: normalizeString(row["exercise_id"]) ??
      validExerciseId ??
      body.exercise_id ??
      null,
  });
  let speakingPayload: ReviewPayload | null = null;
  if (row["status"] === "ready") {
    speakingPayload = await ensureVietnameseUserFacingJson(
      apiKey,
      buildSpeakingReviewPayload({
        reviewId: "",
        source,
        row,
      }),
      "speaking.teacher_review_subjective",
    );
  }
  const inserted = await insertReviewRow({
    supabase,
    requestKey,
    requester,
    source,
    questionId: resolvedRefs.questionId,
    exerciseId: resolvedRefs.exerciseId,
    lessonId: body.lesson_id ?? null,
    examAttemptId: (row["exam_attempt_id"] as string | null) ??
      body.exam_attempt_id ?? null,
    modality: "speaking",
    status: row["status"] === "ready"
      ? "ready"
      : row["status"] === "error"
        ? "error"
        : "processing",
    verdict: speakingPayload?.verdict ?? null,
    resultPayload: speakingPayload,
    inputPayload: { ai_attempt_id: attemptId },
    speakingAttemptId: attemptId,
    errorMessage: row["status"] === "error"
      ? String(row["error_message"] ?? "Không thể tạo teacher review.")
      : null,
  });

  if (row["status"] === "ready") {
    const payload = await ensureVietnameseUserFacingJson(
      apiKey,
      buildSpeakingReviewPayload({
        reviewId: inserted.id,
        source,
        row,
      }),
      "speaking.teacher_review_subjective",
    );
    await supabase
      .from("ai_teacher_reviews")
      .update({
        result_payload: payload,
        verdict: payload.verdict,
        updated_at: new Date().toISOString(),
      })
      .eq("id", inserted.id);
  }

  return { review_id: inserted.id };
}

async function buildObjectiveReviewPayload(args: {
  source: string;
  question: Record<string, unknown>;
  selectedOptionId: string | null;
  writtenAnswer: string | null;
}): Promise<ReviewPayload> {
  const { source, question, selectedOptionId, writtenAnswer } = args;
  const type = String(question["type"] ?? "mcq");
  const options = ((question["question_options"] as unknown[]) ?? [])
    .map((item) => item as Record<string, unknown>)
    .sort((a, b) =>
      Number(a["order_index"] ?? 0) - Number(b["order_index"] ?? 0)
    );
  const correctOption = options.find((option) => option["is_correct"] === true);
  const selectedOption = options.find((option) =>
    option["id"] === selectedOptionId
  );
  const userAnswerText = formatUserAnswer({
    type,
    selectedOption,
    writtenAnswer,
    options,
  });
  const correctAnswerText = formatCorrectAnswer({
    type,
    question,
    correctOption,
    options,
  });
  const correctness = computeObjectiveCorrectness({
    type,
    question,
    selectedOptionId,
    writtenAnswer,
    correctOption,
    options,
  });

  const apiKey = getOpenAIKey();
  const result = await chatComplete(
    apiKey,
    OBJECTIVE_REVIEW_PROMPT,
    [
      `Loại câu hỏi: ${type}`,
      `Kỹ năng: ${String(question["skill"] ?? "reading")}`,
      `Câu hỏi: "${String(question["prompt"] ?? "")}"`,
      `Giải thích sẵn có: "${String(question["explanation"] ?? "")}"`,
      `Đáp án đúng: "${correctAnswerText}"`,
      `Câu trả lời của học viên: "${userAnswerText}"`,
      `Mức độ đúng: ${correctness.verdict}`,
      options.length > 0
        ? `Các lựa chọn: ${options.map((option) => `${option["id"]}: ${option["text"]}`).join(
          " | ",
        )
        }`
        : "",
    ].filter((line) => line.length > 0).join("\n"),
    { model: getObjectiveReviewModel(), timeoutMs: 30_000 },
  );

  return await ensureVietnameseUserFacingJson(
    apiKey,
    {
      review_id: "",
      status: "ready",
      modality: "objective",
      source,
      verdict: correctness.verdict,
      summary: String(result["summary"] ?? ""),
      reinforcement: String(result["reinforcement"] ?? ""),
      criteria: ((result["criteria"] as unknown[]) ?? []).map((item, index) =>
        normalizeObjectiveCriterion(item, index)
      ),
      mistakes: ((result["mistakes"] as unknown[]) ?? []).map((item, index) =>
        normalizeObjectiveMistake(item, index)
      ),
      suggestions: ((result["suggestions"] as unknown[]) ?? []).map((
        item,
        index,
      ) => normalizeObjectiveSuggestion(item, index)),
      corrected_answer: String(result["corrected_answer"] ?? correctAnswerText),
      artifacts: {
        short_tips: ((result["suggestions"] as unknown[]) ?? [])
          .map((item) => item as Record<string, unknown>)
          .map((item) => String(item["detail"] ?? ""))
          .filter((item) => item.length > 0)
          .slice(0, 3),
      },
    },
    "objective_review.teacher_review_payload",
  );
}

function normalizeObjectiveCriterion(
  item: unknown,
  index: number,
): Record<string, unknown> {
  const criterion = (item as Record<string, unknown> | null) ?? {};
  return {
    title: normalizeTitle(
      criterion["title"],
      index == 0 ? "Độ chính xác" : `Tiêu chí ${index + 1}`,
    ),
    score: criterion["score"] ?? null,
    max_score: criterion["max_score"] ?? null,
    feedback: String(criterion["feedback"] ?? ""),
    tip: String(criterion["tip"] ?? ""),
  };
}

function normalizeObjectiveMistake(
  item: unknown,
  index: number,
): Record<string, unknown> {
  const mistake = (item as Record<string, unknown> | null) ?? {};
  return {
    title: normalizeTitle(mistake["title"], `Lỗi ${index + 1}`),
    explanation: String(mistake["explanation"] ?? ""),
    correction: String(mistake["correction"] ?? ""),
    tip: String(mistake["tip"] ?? ""),
  };
}

function normalizeObjectiveSuggestion(
  item: unknown,
  index: number,
): Record<string, unknown> {
  const suggestion = (item as Record<string, unknown> | null) ?? {};
  return {
    title: normalizeTitle(suggestion["title"], `Gợi ý ${index + 1}`),
    detail: String(suggestion["detail"] ?? ""),
  };
}

function normalizeTitle(value: unknown, fallback: string): string {
  const text = String(value ?? "").trim();
  return text.length > 0 ? text : fallback;
}

function computeObjectiveCorrectness(args: {
  type: string;
  question: Record<string, unknown>;
  selectedOptionId: string | null;
  writtenAnswer: string | null;
  correctOption: Record<string, unknown> | undefined;
  options: Array<Record<string, unknown>>;
}): { verdict: ReviewPayload["verdict"]; ratio: number } {
  const {
    type,
    question,
    selectedOptionId,
    writtenAnswer,
    correctOption,
    options,
  } = args;

  if (type === "mcq" || type === "reading_mcq" || type === "listening_mcq") {
    const isCorrect = selectedOptionId != null &&
      correctOption != null &&
      String(correctOption["id"]) === selectedOptionId;
    return {
      verdict: isCorrect ? "correct" : "incorrect",
      ratio: isCorrect ? 1 : 0,
    };
  }

  if (type === "fill_blank" || type === "fillBlank") {
    const submitted = String(writtenAnswer ?? "").trim().toLowerCase();
    const acceptedAnswers = [
      question["correct_answer"],
      ...(((question["accepted_answers"] as unknown[]) ?? [])),
    ]
      .map((value) => String(value ?? "").trim().toLowerCase())
      .filter((value) => value.length > 0);
    const isCorrect = submitted.length > 0 &&
      acceptedAnswers.includes(submitted);
    return {
      verdict: isCorrect ? "correct" : "incorrect",
      ratio: isCorrect ? 1 : 0,
    };
  }

  if ((type === "ordering" || type === "matching") && writtenAnswer) {
    if (type === "ordering") {
      try {
        const submitted = JSON.parse(writtenAnswer) as string[];
        const correctOrder = options.map((option) => String(option["id"]));
        const matchCount = submitted.filter((value, index) =>
          value === correctOrder[index]
        ).length;
        const ratio = correctOrder.length > 0
          ? matchCount / correctOrder.length
          : 0;
        return {
          verdict: ratio >= 1 ? "correct" : ratio > 0 ? "partial" : "incorrect",
          ratio,
        };
      } catch (_) {
        return { verdict: "incorrect", ratio: 0 };
      }
    }

    const submittedPairs = parseMatchingPairs(writtenAnswer);
    const correctPairs = parseMatchingPairs(
      String(question["correct_answer"] ?? ""),
    );
    const ratio = compareMatchingPairs(submittedPairs, correctPairs);
    return {
      verdict: ratio >= 1 ? "correct" : ratio > 0 ? "partial" : "incorrect",
      ratio,
    };
  }

  return { verdict: "incorrect", ratio: 0 };
}

function formatUserAnswer(args: {
  type: string;
  selectedOption?: Record<string, unknown>;
  writtenAnswer: string | null;
  options: Array<Record<string, unknown>>;
}): string {
  const { type, selectedOption, writtenAnswer, options } = args;
  if (selectedOption) {
    return String(selectedOption["text"] ?? "");
  }
  if (type === "ordering" && writtenAnswer) {
    try {
      const submitted = JSON.parse(writtenAnswer) as string[];
      return submitted
        .map((value, index) => {
          const option = options.find((item) => String(item["id"]) === value);
          return option
            ? `${index + 1}. ${String(option["text"] ?? option["id"])}`
            : `${index + 1}. ${value}`;
        })
        .join(" -> ");
    } catch (_) {
      return writtenAnswer;
    }
  }
  if (type === "matching" && writtenAnswer) {
    return formatMatchingPairs(writtenAnswer, options);
  }
  return writtenAnswer?.trim().length ?? 0 > 0
    ? writtenAnswer!
    : "(chưa trả lời)";
}

function formatCorrectAnswer(args: {
  type: string;
  question: Record<string, unknown>;
  correctOption?: Record<string, unknown>;
  options: Array<Record<string, unknown>>;
}): string {
  const { type, question, correctOption, options } = args;
  if (correctOption) {
    return String(correctOption["text"] ?? "");
  }
  if (type === "ordering") {
    return options.map((option, index) =>
      `${index + 1}. ${String(option["text"] ?? option["id"])}`
    ).join(" -> ");
  }
  if (type === "matching") {
    return formatMatchingPairs(
      String(question["correct_answer"] ?? ""),
      options,
    );
  }
  return String(question["correct_answer"] ?? "");
}

async function ensureRequesterCanAccessSubjectiveAttempt(args: {
  supabase: SupabaseClient;
  requester: {
    userId: string | null;
    guestToken: string | null;
    accessLevel: "basic" | "premium";
  };
  row: Record<string, unknown>;
  questionId: string | null;
  requestExamAttemptId: string | null;
}): Promise<void> {
  const { supabase, requester, row, questionId, requestExamAttemptId } = args;
  const rowQuestionId = normalizeString(row["question_id"]);
  if (
    rowQuestionId != null && questionId != null && rowQuestionId !== questionId
  ) {
    throw new Error("Forbidden");
  }

  try {
    assertCanAccessOwnedRow({
      req: new Request("http://local", {
        headers: requester.guestToken == null
          ? undefined
          : { "x-guest-token": requester.guestToken },
      }),
      row,
      requesterUserId: requester.userId,
    });
    return;
  } catch (_) {
    // Fall back to exam_attempt ownership checks for legacy rows that do not
    // have guest_token populated yet.
  }

  const rowExamAttemptId = normalizeString(row["exam_attempt_id"]);
  if (
    rowExamAttemptId != null && requestExamAttemptId != null &&
    rowExamAttemptId !== requestExamAttemptId
  ) {
    throw new Error("Forbidden");
  }

  if (requester.userId == null) {
    throw new Error("Forbidden");
  }

  if (rowExamAttemptId == null) {
    throw new Error("Forbidden");
  }

  const { data: attempt } = await supabase
    .from("exam_attempts")
    .select("user_id")
    .eq("id", rowExamAttemptId)
    .maybeSingle();

  const attemptOwnerId = normalizeString(
    (attempt as Record<string, unknown> | null)?.["user_id"],
  );
  if (attemptOwnerId !== requester.userId) {
    throw new Error("Forbidden");
  }
}

function parseMatchingPairs(raw: string): Record<string, string> {
  try {
    const parsed = JSON.parse(raw) as Record<string, unknown>;
    return Object.fromEntries(
      Object.entries(parsed)
        .map(([leftId, rightId]) => [String(leftId), String(rightId ?? "")])
        .filter(([, rightId]) => rightId.length > 0),
    );
  } catch (_) {
    return {};
  }
}

function compareMatchingPairs(
  submittedPairs: Record<string, string>,
  correctPairs: Record<string, string>,
): number {
  const correctKeys = Object.keys(correctPairs);
  if (correctKeys.length === 0) return 0;
  const matchCount = correctKeys
    .filter((leftId) => submittedPairs[leftId] === correctPairs[leftId])
    .length;
  return matchCount / correctKeys.length;
}

function formatMatchingPairs(
  raw: string,
  options: Array<Record<string, unknown>>,
): string {
  const pairs = parseMatchingPairs(raw);
  const optionTextById = Object.fromEntries(
    options.map((option) => [
      String(option["id"]),
      String(option["text"] ?? option["id"]),
    ]),
  );

  const entries = Object.entries(pairs);
  if (entries.length === 0) return raw;

  return entries
    .map(([leftId, rightId]) =>
      `${leftId} -> ${optionTextById[rightId] ?? rightId}`
    )
    .join(" | ");
}

function normalizeString(value: unknown): string | null {
  if (value == null) return null;
  const text = String(value).trim();
  return text.length > 0 ? text : null;
}

async function normalizeReviewReferences(
  supabase: SupabaseClient,
  refs: {
    questionId: string | null;
    exerciseId: string | null;
  },
): Promise<{ questionId: string | null; exerciseId: string | null }> {
  const rawQuestionId = normalizeString(refs.questionId);
  const rawExerciseId = normalizeString(refs.exerciseId);

  let resolvedQuestionId: string | null = null;
  let resolvedExerciseId: string | null = null;

  if (rawQuestionId) {
    const { data: questionRow } = await supabase
      .from("questions")
      .select("id")
      .eq("id", rawQuestionId)
      .maybeSingle();

    if (questionRow) {
      resolvedQuestionId = rawQuestionId;
    } else {
      const { data: exerciseRow } = await supabase
        .from("exercises")
        .select("id")
        .eq("id", rawQuestionId)
        .maybeSingle();

      if (exerciseRow) {
        resolvedExerciseId = rawQuestionId;
      }
    }
  }

  if (rawExerciseId) {
    const { data: exerciseRow } = await supabase
      .from("exercises")
      .select("id")
      .eq("id", rawExerciseId)
      .maybeSingle();

    if (exerciseRow) {
      resolvedExerciseId = rawExerciseId;
    }
  }

  return {
    questionId: resolvedQuestionId,
    exerciseId: resolvedExerciseId,
  };
}

async function insertReviewRow(args: {
  supabase: SupabaseClient;
  requestKey: string;
  requester: {
    userId: string | null;
    guestToken: string | null;
    accessLevel: "basic" | "premium";
  };
  source: string;
  questionId: string | null;
  exerciseId: string | null;
  lessonId: string | null;
  examAttemptId: string | null;
  modality: "objective" | "writing" | "speaking";
  status: "processing" | "ready" | "error";
  verdict: ReviewPayload["verdict"] | null;
  resultPayload: ReviewPayload | null;
  inputPayload: Record<string, unknown>;
  writingAttemptId?: string;
  speakingAttemptId?: string;
  errorMessage?: string | null;
}): Promise<{ id: string }> {
  const {
    supabase,
    requestKey,
    requester,
    source,
    questionId,
    exerciseId,
    lessonId,
    examAttemptId,
    modality,
    status,
    verdict,
    resultPayload,
    inputPayload,
    writingAttemptId,
    speakingAttemptId,
    errorMessage,
  } = args;
  const { data, error } = await supabase
    .from("ai_teacher_reviews")
    .insert({
      request_key: requestKey,
      user_id: requester.userId,
      guest_token: requester.userId == null ? requester.guestToken : null,
      source,
      modality,
      question_id: questionId,
      exercise_id: exerciseId,
      lesson_id: lessonId,
      exam_attempt_id: examAttemptId,
      writing_attempt_id: writingAttemptId ?? null,
      speaking_attempt_id: speakingAttemptId ?? null,
      access_level: requester.accessLevel,
      status,
      verdict,
      input_payload: inputPayload,
      result_payload: resultPayload,
      error_message: errorMessage ?? null,
    })
    .select("id")
    .single();

  if (error || !data) {
    throw new Error(`Failed to insert ai_teacher_review: ${error?.message}`);
  }

  return { id: String((data as Record<string, unknown>)["id"]) };
}

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
