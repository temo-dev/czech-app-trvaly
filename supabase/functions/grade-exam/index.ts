import { corsHeaders } from '../_shared/cors.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface QuestionRow {
  id: string;
  type: string;
  skill: string;
  points: number;
  correct_answer: string | null;
  section_id: string;
  order_index: number;
  question_options: Array<{ id: string; is_correct: boolean; order_index: number }>;
}

interface SectionRow {
  id: string;
  skill: string;
  order_index: number;
  question_count: number;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  try {
    const { attempt_id } = await req.json() as { attempt_id: string };

    if (!attempt_id) {
      return new Response(
        JSON.stringify({ error: 'attempt_id required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // 1. Fetch the attempt
    const { data: attempt, error: attemptErr } = await supabase
      .from('exam_attempts')
      .select('id, exam_id, user_id, answers')
      .eq('id', attempt_id)
      .single();

    if (attemptErr || !attempt) {
      return new Response(
        JSON.stringify({ error: 'Attempt not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const a = attempt as Record<string, unknown>;
    const answers = (a['answers'] ?? {}) as Record<string, string>;

    // 2. Fetch exam sections ordered by order_index
    const { data: sectionsRaw } = await supabase
      .from('exam_sections')
      .select('id, skill, order_index, question_count')
      .eq('exam_id', a['exam_id'])
      .order('order_index');

    const sections = (sectionsRaw ?? []) as SectionRow[];

    if (!sections.length) {
      return new Response(
        JSON.stringify({ error: 'No sections found for exam' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const sectionIds = sections.map((s) => s.id);

    // 3. Fetch all questions with options, ordered by order_index within each section
    const { data: questionsRaw } = await supabase
      .from('questions')
      .select('id, type, skill, points, correct_answer, section_id, order_index, question_options(id, is_correct, order_index)')
      .in('section_id', sectionIds)
      .order('order_index');

    const questions = (questionsRaw ?? []) as QuestionRow[];

    // 4. Fetch real AI scores for speaking/writing answers in this exam attempt
    const [speakingRes, writingRes, pendingSpeakingRes, pendingWritingRes] = await Promise.all([
      supabase
        .from('ai_speaking_attempts')
        .select('question_id, overall_score')
        .eq('exam_attempt_id', attempt_id)
        .eq('status', 'ready'),
      supabase
        .from('ai_writing_attempts')
        .select('question_id, overall_score')
        .eq('exam_attempt_id', attempt_id)
        .eq('status', 'ready'),
      supabase
        .from('ai_speaking_attempts')
        .select('id')
        .eq('exam_attempt_id', attempt_id)
        .eq('status', 'processing')
        .limit(1),
      supabase
        .from('ai_writing_attempts')
        .select('id')
        .eq('exam_attempt_id', attempt_id)
        .eq('status', 'processing')
        .limit(1),
    ]);

    const aiGradingPending =
      (pendingSpeakingRes.data?.length ?? 0) > 0 ||
      (pendingWritingRes.data?.length ?? 0) > 0;

    const speakingScoreMap = new Map<string, number>();
    for (const r of speakingRes.data ?? []) {
      if (r.question_id) speakingScoreMap.set(r.question_id, r.overall_score ?? 0);
    }
    const writingScoreMap = new Map<string, number>();
    for (const r of writingRes.data ?? []) {
      if (r.question_id) writingScoreMap.set(r.question_id, r.overall_score ?? 0);
    }

    // 5. Group questions by section, maintaining order
    const bySection = new Map<string, QuestionRow[]>();
    for (const s of sections) bySection.set(s.id, []);
    for (const q of questions) {
      bySection.get(q.section_id)?.push(q);
    }

    // 6. Grade each question
    const sectionScores: Record<string, { score: number; total: number }> = {};
    const weakSkills: string[] = [];
    let globalIdx = 0;
    let totalEarned = 0;
    let totalPossible = 0;

    for (const section of sections) {
      const sectionQs = bySection.get(section.id) ?? [];
      let sectionEarned = 0;
      let sectionPossible = 0;

      for (const q of sectionQs) {
        const answerKey = `q_${globalIdx}`;
        const studentAnswer = answers[answerKey];
        const points = q.points || 1;
        sectionPossible += points;

        let earned = 0;

        if (q.type === 'mcq' || q.type === 'reading_mcq' || q.type === 'listening_mcq') {
          if (studentAnswer) {
            const selectedOption = q.question_options.find((o) => o.id === studentAnswer);
            if (selectedOption?.is_correct) {
              earned = points;
            }
          }
        } else if (q.type === 'fill_blank' || q.type === 'fillBlank') {
          if (
            studentAnswer &&
            q.correct_answer &&
            studentAnswer.trim().toLowerCase() === q.correct_answer.trim().toLowerCase()
          ) {
            earned = points;
          }
        } else if (q.type === 'matching' || q.type === 'ordering') {
          // Proportional credit: compare submitted order against correct order position-by-position
          if (studentAnswer && studentAnswer.length > 0) {
            try {
              const submitted: string[] = JSON.parse(studentAnswer);
              const correctOrder = [...q.question_options]
                .sort((a, b) => a.order_index - b.order_index)
                .map((o) => o.id);
              if (correctOrder.length > 0) {
                const matchCount = submitted.filter((id, i) => id === correctOrder[i]).length;
                earned = Math.round(points * (matchCount / correctOrder.length));
              } else {
                earned = Math.round(points * 0.5);
              }
            } catch {
              earned = Math.round(points * 0.5);
            }
          }
        } else if (q.type === 'speaking') {
          const aiScore = speakingScoreMap.get(q.id);
          if (aiScore !== undefined) {
            earned = Math.round(points * (aiScore / 100));
          } else if (studentAnswer && studentAnswer.length > 0) {
            // AI not yet ready — partial credit placeholder
            earned = Math.round(points * 0.5);
          }
        } else if (q.type === 'writing') {
          const aiScore = writingScoreMap.get(q.id);
          if (aiScore !== undefined) {
            earned = Math.round(points * (aiScore / 100));
          } else if (studentAnswer && studentAnswer.length > 0) {
            earned = Math.round(points * 0.5);
          }
        }

        sectionEarned += earned;
        globalIdx++;
      }

      // Convert to 0–100 scale per section
      const sectionScore = sectionPossible > 0
        ? Math.round((sectionEarned / sectionPossible) * 100)
        : 0;

      sectionScores[section.skill] = { score: sectionScore, total: 100 };
      totalEarned += sectionEarned;
      totalPossible += sectionPossible;

      if (sectionScore < 60) weakSkills.push(section.skill);
    }

    const totalScore = totalPossible > 0
      ? Math.round((totalEarned / totalPossible) * 100)
      : 0;

    // 7. Delete any existing result row, then insert updated result
    await supabase
      .from('exam_results')
      .delete()
      .eq('attempt_id', attempt_id);

    const { error: insertErr } = await supabase
      .from('exam_results')
      .insert({
        attempt_id,
        user_id: a['user_id'] ?? null,
        total_score: totalScore,
        pass_threshold: 60,
        section_scores: sectionScores,
        weak_skills: weakSkills,
        ai_grading_pending: aiGradingPending,
      });

    if (insertErr) {
      throw new Error(`Failed to insert exam result: ${insertErr.message}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        attempt_id,
        total_score: totalScore,
        section_scores: sectionScores,
        weak_skills: weakSkills,
        ai_grading_pending: aiGradingPending,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('grade-exam error:', err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
