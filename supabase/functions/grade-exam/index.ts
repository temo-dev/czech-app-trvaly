import { corsHeaders } from "../_shared/cors.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { assertCanAccessExamAttempt } from "../_shared/guest_access.ts";

interface QuestionRow {
  id: string;
  type: string;
  skill: string;
  points: number;
  correct_answer: string | null;
  accepted_answers: string[] | null;
  section_id: string;
  order_index: number;
  question_options: Array<
    { id: string; is_correct: boolean; order_index: number }
  >;
}

interface SectionRow {
  id: string;
  skill: string;
  order_index: number;
  question_count: number;
}

interface StoredAnswer {
  question_id?: string;
  selected_option_id?: string | null;
  written_answer?: string | null;
  ai_attempt_id?: string | null;
}

interface AiAttemptScoreRow {
  id: string;
  question_id: string | null;
  overall_score: number | null;
}

interface AiAttemptPendingRow {
  id: string;
  question_id: string | null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  try {
    const { attempt_id } = await req.json() as { attempt_id: string };

    if (!attempt_id) {
      return new Response(
        JSON.stringify({ error: "attempt_id required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const accessAttempt = await assertCanAccessExamAttempt({
      supabase,
      req,
      attemptId: attempt_id,
    });

    const { data: attempt, error: attemptErr } = await supabase
      .from("exam_attempts")
      .select("id, exam_id, user_id, guest_token, answers")
      .eq("id", attempt_id)
      .single();

    if (attemptErr || !attempt) {
      return new Response(
        JSON.stringify({ error: "Attempt not found" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const attemptRecord = attempt as Record<string, unknown>;
    const answers = (attemptRecord["answers"] ?? {}) as Record<string, unknown>;
    const hasLegacyAnswerKeys = Object.keys(answers).some((key) =>
      key.startsWith("q_")
    );

    const { data: sectionsRaw } = await supabase
      .from("exam_sections")
      .select("id, skill, order_index, question_count")
      .eq("exam_id", attemptRecord["exam_id"])
      .order("order_index");

    const sections = (sectionsRaw ?? []) as SectionRow[];
    if (!sections.length) {
      return new Response(
        JSON.stringify({ error: "No sections found for exam" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const sectionIds = sections.map((section) => section.id);

    const { data: questionsRaw } = await supabase
      .from("questions")
      .select(
        "id, type, skill, points, correct_answer, accepted_answers, section_id, order_index, question_options(id, is_correct, order_index)",
      )
      .in("section_id", sectionIds)
      .order("order_index");

    const questions = (questionsRaw ?? []) as QuestionRow[];
    const storedAttemptIds = Object.values(answers)
      .filter((value): value is StoredAnswer =>
        typeof value === "object" && value !== null
      )
      .map((value) => value.ai_attempt_id)
      .filter((value): value is string =>
        typeof value === "string" && value.length > 0
      );

    const [
      speakingReadyRes,
      writingReadyRes,
      speakingPendingRes,
      writingPendingRes,
      speakingByIdReadyRes,
      writingByIdReadyRes,
      speakingByIdPendingRes,
      writingByIdPendingRes,
    ] = await Promise.all([
      supabase
        .from("ai_speaking_attempts")
        .select("question_id, overall_score")
        .eq("exam_attempt_id", attempt_id)
        .eq("status", "ready"),
      supabase
        .from("ai_writing_attempts")
        .select("question_id, overall_score")
        .eq("exam_attempt_id", attempt_id)
        .eq("status", "ready"),
      supabase
        .from("ai_speaking_attempts")
        .select("question_id")
        .eq("exam_attempt_id", attempt_id)
        .eq("status", "processing"),
      supabase
        .from("ai_writing_attempts")
        .select("question_id")
        .eq("exam_attempt_id", attempt_id)
        .eq("status", "processing"),
      storedAttemptIds.length
        ? supabase
          .from("ai_speaking_attempts")
          .select("id, question_id, overall_score")
          .in("id", storedAttemptIds)
          .eq("status", "ready")
        : Promise.resolve({ data: [] as AiAttemptScoreRow[] }),
      storedAttemptIds.length
        ? supabase
          .from("ai_writing_attempts")
          .select("id, question_id, overall_score")
          .in("id", storedAttemptIds)
          .eq("status", "ready")
        : Promise.resolve({ data: [] as AiAttemptScoreRow[] }),
      storedAttemptIds.length
        ? supabase
          .from("ai_speaking_attempts")
          .select("id, question_id")
          .in("id", storedAttemptIds)
          .eq("status", "processing")
        : Promise.resolve({ data: [] as AiAttemptPendingRow[] }),
      storedAttemptIds.length
        ? supabase
          .from("ai_writing_attempts")
          .select("id, question_id")
          .in("id", storedAttemptIds)
          .eq("status", "processing")
        : Promise.resolve({ data: [] as AiAttemptPendingRow[] }),
    ]);

    const speakingScoreMap = new Map<string, number>();
    for (const row of speakingReadyRes.data ?? []) {
      if (row.question_id) {
        speakingScoreMap.set(row.question_id, row.overall_score ?? 0);
      }
    }

    const writingScoreMap = new Map<string, number>();
    for (const row of writingReadyRes.data ?? []) {
      if (row.question_id) {
        writingScoreMap.set(row.question_id, row.overall_score ?? 0);
      }
    }

    const pendingSpeakingQuestions = new Set<string>();
    for (const row of speakingPendingRes.data ?? []) {
      if (row.question_id) pendingSpeakingQuestions.add(row.question_id);
    }

    const pendingWritingQuestions = new Set<string>();
    for (const row of writingPendingRes.data ?? []) {
      if (row.question_id) pendingWritingQuestions.add(row.question_id);
    }

    const speakingScoreByAttemptId = new Map<string, number>();
    for (
      const row of (speakingByIdReadyRes.data ?? []) as AiAttemptScoreRow[]
    ) {
      if (row.id) {
        speakingScoreByAttemptId.set(row.id, row.overall_score ?? 0);
      }
    }

    const writingScoreByAttemptId = new Map<string, number>();
    for (const row of (writingByIdReadyRes.data ?? []) as AiAttemptScoreRow[]) {
      if (row.id) {
        writingScoreByAttemptId.set(row.id, row.overall_score ?? 0);
      }
    }

    const pendingSpeakingAttemptIds = new Set<string>();
    for (
      const row of (speakingByIdPendingRes.data ?? []) as AiAttemptPendingRow[]
    ) {
      if (row.id) pendingSpeakingAttemptIds.add(row.id);
    }

    const pendingWritingAttemptIds = new Set<string>();
    for (
      const row of (writingByIdPendingRes.data ?? []) as AiAttemptPendingRow[]
    ) {
      if (row.id) pendingWritingAttemptIds.add(row.id);
    }

    const bySection = new Map<string, QuestionRow[]>();
    for (const section of sections) bySection.set(section.id, []);
    for (const question of questions) {
      bySection.get(question.section_id)?.push(question);
    }

    const sectionScores: Record<string, { score: number; total: number }> = {};
    const weakSkills: string[] = [];
    let totalEarned = 0;
    let totalPossible = 0;
    let writtenEarned = 0;
    let writtenPossible = 0;
    let speakingEarned = 0;
    let speakingPossible = 0;
    let aiGradingPending = false;
    let globalIdx = 0;

    for (const section of sections) {
      const sectionQuestions = bySection.get(section.id) ?? [];
      let sectionEarned = 0;
      let sectionPossible = 0;

      for (const question of sectionQuestions) {
        const storedAnswer = getStoredAnswer({
          answers,
          question,
          globalIdx,
          hasLegacyAnswerKeys,
        });

        const selectedOptionId = normalizeString(
          storedAnswer?.selected_option_id ??
            (question.type === "mcq"
              ? (storedAnswer?.written_answer ?? null)
              : null),
        );
        const writtenAnswer = normalizeString(storedAnswer?.written_answer);
        const points = question.points || 1;
        let earned = 0;

        sectionPossible += points;

        if (
          question.type === "mcq" ||
          question.type === "reading_mcq" ||
          question.type === "listening_mcq"
        ) {
          if (selectedOptionId) {
            const selectedOption = question.question_options.find(
              (option) => option.id === selectedOptionId,
            );
            if (selectedOption?.is_correct) {
              earned = points;
            }
          }
        } else if (
          question.type === "fill_blank" || question.type === "fillBlank"
        ) {
          if (matchesAcceptedAnswer(writtenAnswer, question)) {
            earned = points;
          }
        } else if (
          question.type === "matching" || question.type === "ordering"
        ) {
          if (writtenAnswer && writtenAnswer.length > 0) {
            if (question.type === "ordering") {
              try {
                const submitted: string[] = JSON.parse(writtenAnswer);
                const correctOrder = [...question.question_options]
                  .sort((a, b) => a.order_index - b.order_index)
                  .map((option) => option.id);
                if (correctOrder.length > 0) {
                  const matchCount = submitted.filter(
                    (optionId, idx) => optionId === correctOrder[idx],
                  ).length;
                  earned = Math.round(
                    points * (matchCount / correctOrder.length),
                  );
                }
              } catch {
                earned = 0;
              }
            } else {
              const submittedPairs = parseMatchingPairs(writtenAnswer);
              const correctPairs = parseMatchingPairs(question.correct_answer);
              const correctKeys = Object.keys(correctPairs);
              if (correctKeys.length > 0) {
                const matchCount = correctKeys.filter(
                  (leftId) => submittedPairs[leftId] === correctPairs[leftId],
                ).length;
                earned = Math.round(points * (matchCount / correctKeys.length));
              }
            }
          }
        } else if (question.type === "speaking") {
          const aiAttemptId = normalizeString(storedAnswer?.ai_attempt_id);
          const aiScore = aiAttemptId
            ? speakingScoreByAttemptId.get(aiAttemptId)
            : speakingScoreMap.get(question.id);
          if (aiScore !== undefined) {
            earned = Math.round(points * (aiScore / 100));
          } else if (
            (aiAttemptId && pendingSpeakingAttemptIds.has(aiAttemptId)) ||
            pendingSpeakingQuestions.has(question.id)
          ) {
            aiGradingPending = true;
          }
        } else if (question.type === "writing") {
          const aiAttemptId = normalizeString(storedAnswer?.ai_attempt_id);
          const aiScore = aiAttemptId
            ? writingScoreByAttemptId.get(aiAttemptId)
            : writingScoreMap.get(question.id);
          if (aiScore !== undefined) {
            earned = Math.round(points * (aiScore / 100));
          } else if (
            (aiAttemptId && pendingWritingAttemptIds.has(aiAttemptId)) ||
            pendingWritingQuestions.has(question.id)
          ) {
            aiGradingPending = true;
          }
        }

        sectionEarned += earned;
        totalEarned += earned;
        totalPossible += points;
        if (question.skill === "speaking") {
          speakingEarned += earned;
          speakingPossible += points;
        } else {
          writtenEarned += earned;
          writtenPossible += points;
        }
        globalIdx++;
      }

      sectionScores[section.skill] = { score: sectionEarned, total: sectionPossible };
      const sectionPercent = sectionPossible > 0
        ? Math.round((sectionEarned / sectionPossible) * 100)
        : 0;
      if (sectionPercent < 60) weakSkills.push(section.skill);
    }

    const totalScore = totalPossible > 0
      ? Math.round((totalEarned / totalPossible) * 100)
      : 0;
    const writtenPassThreshold = Math.ceil(writtenPossible * 0.6);
    const speakingPassThreshold = Math.ceil(speakingPossible * 0.6);
    const passed = writtenEarned >= writtenPassThreshold &&
      speakingEarned >= speakingPassThreshold;

    await supabase.from("exam_results").delete().eq("attempt_id", attempt_id);

    const { error: insertErr } = await supabase
      .from("exam_results")
      .insert({
        attempt_id,
        user_id: attemptRecord["user_id"] ?? null,
        guest_token: accessAttempt["guest_token"] ?? null,
        total_score: totalScore,
        pass_threshold: 60,
        passed,
        section_scores: sectionScores,
        weak_skills: weakSkills,
        written_score: writtenEarned,
        written_total: writtenPossible,
        written_pass_threshold: writtenPassThreshold,
        speaking_score: speakingEarned,
        speaking_total: speakingPossible,
        speaking_pass_threshold: speakingPassThreshold,
        ai_grading_pending: aiGradingPending,
      });

    if (insertErr) {
      throw new Error(`Failed to insert exam result: ${insertErr.message}`);
    }

    supabase.functions
      .invoke("analyze-exam", { body: { attempt_id } })
      .catch((error) => {
        console.warn("analyze-exam trigger failed:", error);
      });

    return new Response(
      JSON.stringify({
        success: true,
        attempt_id,
        total_score: totalScore,
        passed,
        section_scores: sectionScores,
        weak_skills: weakSkills,
        written_score: writtenEarned,
        written_total: writtenPossible,
        written_pass_threshold: writtenPassThreshold,
        speaking_score: speakingEarned,
        speaking_total: speakingPossible,
        speaking_pass_threshold: speakingPassThreshold,
        ai_grading_pending: aiGradingPending,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (err) {
    console.error("grade-exam error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

function getStoredAnswer({
  answers,
  question,
  globalIdx,
  hasLegacyAnswerKeys,
}: {
  answers: Record<string, unknown>;
  question: QuestionRow;
  globalIdx: number;
  hasLegacyAnswerKeys: boolean;
}): StoredAnswer | null {
  if (hasLegacyAnswerKeys) {
    const legacyValue = normalizeString(answers[`q_${globalIdx}`]);
    if (!legacyValue) return null;
    if (
      question.type === "mcq" ||
      question.type === "reading_mcq" ||
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

function normalizeString(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  const text = String(value).trim();
  return text.length > 0 ? text : null;
}

function parseMatchingPairs(raw: string | null): Record<string, string> {
  if (!raw) return {};
  try {
    const parsed = JSON.parse(raw) as Record<string, unknown>;
    return Object.fromEntries(
      Object.entries(parsed)
        .map(([leftId, rightId]) => [String(leftId), String(rightId ?? "")])
        .filter(([, rightId]) => rightId.length > 0),
    );
  } catch {
    return {};
  }
}

function matchesAcceptedAnswer(
  writtenAnswer: string | null,
  question: QuestionRow,
): boolean {
  const submitted = normalizeString(writtenAnswer)?.toLowerCase();
  if (!submitted) return false;
  const accepted = new Set<string>(
    [
      normalizeString(question.correct_answer),
      ...((question.accepted_answers ?? []).map((value) => normalizeString(value))),
    ]
      .filter((value): value is string => value !== null)
      .map((value) => value.toLowerCase()),
  );
  return accepted.has(submitted);
}
