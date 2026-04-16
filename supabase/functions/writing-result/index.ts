import { corsHeaders } from '../_shared/cors.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

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
        JSON.stringify({ status: 'error', message: 'attempt_id required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const { data: row, error } = await supabase
      .from('ai_writing_attempts')
      .select('*')
      .eq('id', attempt_id)
      .maybeSingle();

    if (error || !row) {
      return new Response(
        JSON.stringify({ status: 'error', message: 'Attempt not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const r = row as Record<string, unknown>;

    if (r['status'] === 'processing') {
      return new Response(
        JSON.stringify({ status: 'pending' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (r['status'] === 'error') {
      return new Response(
        JSON.stringify({
          status: 'error',
          message: r['error_message'] as string ?? 'Lỗi chấm điểm bài viết.',
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const metricsDb = (r['metrics'] as Record<string, number>) ?? {};

    // metrics list expected by Flutter: [{ label, score, max_score, feedback? }]
    const metricsList = [
      { label: 'Ngữ pháp', score: metricsDb['grammar'] ?? 0, max_score: 100 },
      { label: 'Từ vựng', score: metricsDb['vocabulary'] ?? 0, max_score: 100 },
      { label: 'Mạch lạc', score: metricsDb['coherence'] ?? 0, max_score: 100 },
      { label: 'Hoàn thành đề', score: metricsDb['task_achievement'] ?? 0, max_score: 100 },
    ];

    // annotated_spans were stored in grammar_notes column
    const annotatedSpans = (r['grammar_notes'] as unknown[]) ?? [
      { text: r['answer_text'] as string ?? '', issue_type: null },
    ];

    // overall_feedback was stored in vocabulary_notes as [{ overall_feedback: "..." }]
    const vocabNotes = (r['vocabulary_notes'] as Array<Record<string, string>>) ?? [];
    const overallFeedback = vocabNotes[0]?.['overall_feedback']
      ?? buildOverallFeedback(metricsDb);

    return new Response(
      JSON.stringify({
        status: 'ready',
        attempt_id: r['id'],
        total_score: r['overall_score'] ?? 0,
        max_score: 100,
        metrics: metricsList,
        annotated_spans: annotatedSpans,
        corrected_version: r['corrected_essay'] ?? '',
        overall_feedback: overallFeedback,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('writing-result error:', err);
    return new Response(
      JSON.stringify({ status: 'error', message: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});

function buildOverallFeedback(metrics: Record<string, number>): string {
  const values = Object.values(metrics);
  if (values.length === 0) return 'Tiếp tục luyện tập để cải thiện kỹ năng viết!';
  const avg = values.reduce((a, b) => a + b, 0) / values.length;
  if (avg >= 80) return 'Bài viết rất tốt! Ngữ pháp và từ vựng phong phú.';
  if (avg >= 60) return 'Bài viết khá tốt. Chú ý thêm về biến cách danh từ và cấu trúc câu.';
  return 'Cần luyện tập thêm. Hãy chú trọng ngữ pháp cơ bản và từ vựng chủ đề thi.';
}
