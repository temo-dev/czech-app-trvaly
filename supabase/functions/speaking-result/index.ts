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
      .from('ai_speaking_attempts')
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
          message: r['error_message'] as string ?? 'Lỗi chấm điểm bài nói.',
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Map DB columns → Flutter _parseEdgeResponse shape
    const metricsDb = (r['metrics'] as Record<string, number>) ?? {};
    const issues = (r['issues'] as Array<{ word: string; suggestion: string }>) ?? [];
    const strengths = (r['strengths'] as string[]) ?? [];
    const improvements = (r['improvements'] as string[]) ?? [];
    const transcript = (r['transcript'] as string) ?? '';

    // metrics list expected by Flutter: [{ label, score, max_score, feedback? }]
    const metricsList = [
      { label: 'Phát âm', score: metricsDb['pronunciation'] ?? 0, max_score: 100 },
      { label: 'Lưu loát', score: metricsDb['fluency'] ?? 0, max_score: 100 },
      { label: 'Từ vựng', score: metricsDb['vocabulary'] ?? 0, max_score: 100 },
      { label: 'Trả lời đúng đề', score: metricsDb['task_achievement'] ?? 0, max_score: 100 },
    ];

    // Build transcript_words: mark words that appear in issues
    const issueMap = new Map<string, string>();
    for (const issue of issues) {
      issueMap.set(issue.word.toLowerCase(), issue.suggestion);
    }
    const transcriptWords = transcript.split(/\s+/).filter(Boolean).map((word) => {
      const clean = word.replace(/[.,!?;:'"()]/g, '');
      const suggestion = issueMap.get(clean.toLowerCase());
      return suggestion
        ? { word, issue: 'pronunciation', suggestion }
        : { word };
    });

    // overall_feedback built from strengths
    const overallFeedback = strengths.length > 0
      ? `Điểm mạnh: ${strengths.join('; ')}.`
      : improvements.length > 0
        ? `Cần cải thiện: ${improvements[0]}.`
        : 'Tiếp tục luyện tập để cải thiện kỹ năng nói!';

    return new Response(
      JSON.stringify({
        status: 'ready',
        attempt_id: r['id'],
        total_score: r['overall_score'] ?? 0,
        max_score: 100,
        metrics: metricsList,
        transcript,
        transcript_words: transcriptWords,
        corrections: improvements,
        overall_feedback: overallFeedback,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('speaking-result error:', err);
    return new Response(
      JSON.stringify({ status: 'error', message: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
