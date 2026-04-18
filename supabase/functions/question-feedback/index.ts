import { corsHeaders } from '../_shared/cors.ts';
import { getOpenAIKey, chatComplete } from '../_shared/openai.ts';

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

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const body = await req.json() as {
      question_text?: string;
      options?: Array<{ id: string; text: string }>;
      correct_answer_text?: string;
      user_answer_text?: string;
      section_skill?: string;
    };

    const { question_text, options, correct_answer_text, user_answer_text, section_skill } = body;

    if (!question_text || !correct_answer_text || !user_answer_text) {
      return new Response(
        JSON.stringify({ error: 'question_text, correct_answer_text, user_answer_text required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const apiKey = getOpenAIKey();

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

    const result = await chatComplete(apiKey, QUESTION_FEEDBACK_PROMPT, userMessage);

    return new Response(
      JSON.stringify({
        error_analysis: String(result['error_analysis'] ?? ''),
        correct_explanation: String(result['correct_explanation'] ?? ''),
        short_tip: String(result['short_tip'] ?? ''),
        key_concept: String(result['key_concept'] ?? ''),
      }),
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
