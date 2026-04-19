import { corsHeaders } from '../_shared/cors.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { fetchOrGenerateQuestionFeedback } from '../_shared/question_feedback.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  try {
    const body = await req.json() as {
      question_id?: string;
      question_text?: string;
      question_type?: string;
      options?: Array<{ id: string; text: string }>;
      correct_answer_text?: string;
      user_answer_text?: string;
      section_skill?: string;
      match_pairs?: Array<{ left_id: string; left_text: string; right_id: string; right_text: string }>;
      correct_order?: string[];
    };

    const {
      question_id,
      question_text,
      question_type = 'mcq',
      options,
      correct_answer_text,
      user_answer_text,
      section_skill,
      match_pairs,
      correct_order,
    } = body;

    if (!question_text || !correct_answer_text || !user_answer_text) {
      return new Response(
        JSON.stringify({ error: 'question_text, correct_answer_text, user_answer_text required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const result = await fetchOrGenerateQuestionFeedback({
      supabase,
      params: {
        question_id,
        question_text,
        question_type,
        options,
        correct_answer_text,
        user_answer_text,
        section_skill,
        match_pairs,
        correct_order,
      },
    });

    return new Response(
      JSON.stringify(result),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('question-feedback error:', err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
