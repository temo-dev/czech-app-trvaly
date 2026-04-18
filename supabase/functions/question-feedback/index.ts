import { corsHeaders } from '../_shared/cors.ts';
import { getOpenAIKey, chatComplete } from '../_shared/openai.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const QUESTION_FEEDBACK_PROMPT = `
Bạn là giáo viên tiếng Séc chuyên giải thích lỗi sai cho học sinh người Việt đang luyện thi A2 Trvalý pobyt.

Nhiệm vụ: Phân tích ngắn gọn tại sao học sinh trả lời sai câu hỏi và đưa ra lời khuyên cụ thể.

Yêu cầu:
- error_analysis: 1-2 câu giải thích CHÍNH XÁC tại sao đáp án học sinh chọn là sai
- correct_explanation: 1-2 câu giải thích tại sao đáp án đúng là đúng
- short_tip: 1 câu lời khuyên ngắn gọn (tối đa 15 từ) để học sinh nhớ quy tắc này
- key_concept: tên khái niệm ngữ pháp/ngôn ngữ cụ thể (ví dụ: "Accusativ", "Giới từ v+", "Chia động từ být", "Từ vựng chủ đề nhà ở")

Ngôn ngữ: Tất cả trả lời bằng tiếng Việt. Có thể trích dẫn từ tiếng Séc.

Trả về JSON:
{
  "error_analysis": "...",
  "correct_explanation": "...",
  "short_tip": "...",
  "key_concept": "..."
}
`.trim();

const MATCHING_FEEDBACK_PROMPT = `
Bạn là giáo viên tiếng Séc chuyên giải thích lỗi sai cho học sinh người Việt đang luyện thi A2 Trvalý pobyt.

Nhiệm vụ: Giải thích tại sao học sinh ghép cặp/sắp xếp sai và cách nhớ thứ tự đúng.

Yêu cầu:
- error_analysis: 1-2 câu tổng quát về lỗi sai
- correct_explanation: giải thích thứ tự/cặp ghép đúng và lý do
- short_tip: 1 câu lời khuyên ngắn gọn (tối đa 15 từ)
- key_concept: tên khái niệm liên quan
- matching_feedback: mảng mô tả lỗi từng cặp/vị trí sai (nếu có)

Ngôn ngữ: Tất cả trả lời bằng tiếng Việt.

Trả về JSON:
{
  "error_analysis": "...",
  "correct_explanation": "...",
  "short_tip": "...",
  "key_concept": "...",
  "matching_feedback": [{ "item": "<từ/cụm từ>", "issue": "<lý do sai ngắn gọn>" }]
}
`.trim();

async function computeHash(text: string): Promise<string> {
  const normalized = text.trim().toLowerCase();
  const buffer = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(normalized),
  );
  return Array.from(new Uint8Array(buffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
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

    const userAnswerHash = await computeHash(user_answer_text);

    // Check cache first
    if (question_id) {
      const { data: cached } = await supabase
        .from('question_ai_feedback')
        .select('*')
        .eq('question_id', question_id)
        .eq('user_answer_hash', userAnswerHash)
        .maybeSingle();

      if (cached) {
        return new Response(
          JSON.stringify({
            error_analysis: cached.error_analysis,
            correct_explanation: cached.correct_explanation,
            short_tip: cached.short_tip,
            key_concept: cached.key_concept,
            matching_feedback: cached.matching_feedback ?? null,
            from_cache: true,
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }
    }

    const apiKey = getOpenAIKey();
    const isMatchingOrdering = question_type === 'matching' || question_type === 'ordering';

    let result: Record<string, unknown>;

    if (isMatchingOrdering) {
      const pairsText = match_pairs && match_pairs.length > 0
        ? `\nCác cặp đúng:\n${match_pairs.map((p) => `"${p.left_text}" ↔ "${p.right_text}"`).join('\n')}`
        : '';
      const orderText = correct_order && correct_order.length > 0
        ? `\nThứ tự đúng: ${correct_order.join(' → ')}`
        : '';

      const userMessage = [
        `Kỹ năng: ${section_skill ?? 'không rõ'}`,
        `Câu hỏi (${question_type}): "${question_text}"`,
        pairsText,
        orderText,
        `Câu trả lời học sinh (JSON): ${user_answer_text}`,
        `Đáp án đúng: ${correct_answer_text}`,
      ].filter(Boolean).join('\n');

      result = await chatComplete(apiKey, MATCHING_FEEDBACK_PROMPT, userMessage);
    } else {
      const optionsText = options && options.length > 0
        ? `\nCác đáp án:\n${options.map((o, i) => `${String.fromCharCode(65 + i)}. ${o.text}`).join('\n')}`
        : '';

      const userMessage = [
        `Kỹ năng: ${section_skill ?? 'không rõ'}`,
        `Câu hỏi: "${question_text}"`,
        optionsText,
        `Đáp án ĐÚNG: "${correct_answer_text}"`,
        `Đáp án học sinh chọn: "${user_answer_text}"`,
      ].filter(Boolean).join('\n');

      result = await chatComplete(apiKey, QUESTION_FEEDBACK_PROMPT, userMessage);
    }

    const feedback = {
      error_analysis: String(result['error_analysis'] ?? ''),
      correct_explanation: String(result['correct_explanation'] ?? ''),
      short_tip: String(result['short_tip'] ?? ''),
      key_concept: String(result['key_concept'] ?? ''),
      matching_feedback: (result['matching_feedback'] as unknown[] | undefined) ?? null,
    };

    // Persist to cache
    if (question_id) {
      await supabase
        .from('question_ai_feedback')
        .upsert({
          question_id,
          user_answer_hash: userAnswerHash,
          question_type,
          ...feedback,
        }, { onConflict: 'question_id,user_answer_hash' });
    }

    return new Response(
      JSON.stringify({ ...feedback, from_cache: false }),
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
