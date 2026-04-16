import { corsHeaders } from '../_shared/cors.ts';
import { getOpenAIKey, chatComplete } from '../_shared/openai.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const WRITING_SYSTEM_PROMPT = `
Bạn là giáo viên chấm bài viết tiếng Séc cho người học người Việt Nam.
Người học đang luyện thi kỳ thi trình độ A2 để xin Trvalý pobyt (cư trú lâu dài) tại Cộng hòa Séc.

Tiêu chí chấm:
- grammar (ngữ pháp): 0–100 — độ chính xác về biến cách, chia động từ, trật tự từ
- vocabulary (từ vựng): 0–100 — sự đa dạng và phù hợp của từ ngữ
- coherence (mạch lạc): 0–100 — sự liên kết, cấu trúc đoạn văn
- task_achievement (hoàn thành nhiệm vụ): 0–100 — đáp ứng đúng yêu cầu của đề bài

Lưu ý lỗi thường gặp với người học tiếng Việt: lỗi biến cách danh từ và tính từ,
sử dụng sai giới từ, thiếu mạo từ, dịch sát từ tiếng Việt làm câu nghe kỳ lạ.

Trả về JSON chính xác theo định dạng sau (không có văn bản nào khác):
{
  "overall_score": <int 0-100>,
  "grammar": <int 0-100>,
  "vocabulary": <int 0-100>,
  "coherence": <int 0-100>,
  "task_achievement": <int 0-100>,
  "annotated_spans": [
    { "text": "<đoạn văn không có lỗi>", "issue_type": null },
    { "text": "<từ hoặc cụm từ có lỗi>", "issue_type": "grammar", "correction": "<sửa>", "explanation": "<giải thích ngắn>" }
  ],
  "corrected_essay": "<toàn bộ bài viết đã được sửa hoàn chỉnh>",
  "overall_feedback": "<nhận xét tổng quan 2-3 câu bằng tiếng Việt>"
}

Lưu ý quan trọng về annotated_spans:
- Phải bao phủ TOÀN BỘ văn bản gốc theo thứ tự
- Các đoạn không có lỗi dùng issue_type = null
- issue_type có thể là: "grammar", "vocabulary", "spelling"
`.trim();

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
      text?: string;
      question_id?: string;
      lesson_id?: string;
    };

    const { text, question_id } = body;

    if (!text || !question_id) {
      return new Response(
        JSON.stringify({ error: 'text and question_id are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Get authenticated user (nullable for anonymous)
    const authHeader = req.headers.get('Authorization');
    let userId: string | null = null;
    if (authHeader) {
      const { data: { user } } = await supabase.auth.getUser(
        authHeader.replace('Bearer ', ''),
      );
      userId = user?.id ?? null;
    }

    // Fetch question prompt
    const { data: question } = await supabase
      .from('questions')
      .select('prompt')
      .eq('id', question_id)
      .maybeSingle();

    const promptText = (question as Record<string, unknown> | null)?.['prompt'] as string ?? '';
    const rubricType = detectRubricType(promptText);

    // Insert attempt row
    const { data: attempt, error: insertErr } = await supabase
      .from('ai_writing_attempts')
      .insert({
        user_id: userId,
        exercise_id: null,
        prompt_text: promptText,
        answer_text: text,
        rubric_type: rubricType,
        status: 'processing',
      })
      .select('id')
      .single();

    if (insertErr || !attempt) {
      throw new Error(`Failed to create writing attempt: ${insertErr?.message}`);
    }

    const attemptId: string = (attempt as Record<string, unknown>)['id'] as string;
    const apiKey = getOpenAIKey();

    // Score with GPT-4o-mini
    const userMessage = `Đề bài: "${promptText}"\n\nBài viết của học viên:\n"${text}"`;
    const scored = await chatComplete(apiKey, WRITING_SYSTEM_PROMPT, userMessage);

    const overallScore = Number(scored['overall_score'] ?? 0);
    const metrics = {
      grammar: Number(scored['grammar'] ?? 0),
      vocabulary: Number(scored['vocabulary'] ?? 0),
      coherence: Number(scored['coherence'] ?? 0),
      task_achievement: Number(scored['task_achievement'] ?? 0),
    };

    // Store annotated_spans in grammar_notes (flexible JSONB column)
    const annotatedSpans = (scored['annotated_spans'] as unknown[]) ?? [{ text, issue_type: null }];
    const correctedEssay = String(scored['corrected_essay'] ?? '');
    const overallFeedback = String(scored['overall_feedback'] ?? '');

    await supabase
      .from('ai_writing_attempts')
      .update({
        status: 'ready',
        overall_score: overallScore,
        metrics,
        grammar_notes: annotatedSpans,         // annotated_spans stored here
        vocabulary_notes: [{ overall_feedback: overallFeedback }], // overall feedback stored here
        corrected_essay: correctedEssay,
        updated_at: new Date().toISOString(),
      })
      .eq('id', attemptId);

    return new Response(
      JSON.stringify({ attempt_id: attemptId }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('writing-submit error:', err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});

function detectRubricType(prompt: string): 'letter' | 'essay' | 'form' {
  const p = prompt.toLowerCase();
  if (p.includes('dopis') || p.includes('email') || p.includes('napište')) return 'letter';
  if (p.includes('formulář') || p.includes('form')) return 'form';
  return 'essay';
}
