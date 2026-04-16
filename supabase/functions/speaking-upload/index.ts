import { corsHeaders } from '../_shared/cors.ts';
import { getOpenAIKey, transcribeAudio, chatComplete } from '../_shared/openai.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SPEAKING_SYSTEM_PROMPT = `
Bạn là giám khảo chấm điểm bài thi nói tiếng Séc cho người học người Việt Nam.
Người học đang luyện thi kỳ thi trình độ A2 để xin trạng thái Trvalý pobyt (cư trú lâu dài) tại Cộng hòa Séc.
Nhiệm vụ của bạn là chấm điểm bài nói dựa trên phần phiên âm (transcript) được cung cấp.

Tiêu chí chấm:
- pronunciation (phát âm): 0–100 — độ rõ ràng và chính xác của âm thanh tiếng Séc
- fluency (độ lưu loát): 0–100 — nhịp nói, ngắt câu tự nhiên, không ngập ngừng nhiều
- vocabulary (từ vựng): 0–100 — sử dụng từ phù hợp, đa dạng
- task_achievement (trả lời đúng câu hỏi): 0–100 — câu trả lời có liên quan và đáp ứng đúng yêu cầu của câu hỏi không

Lưu ý: Người học nói tiếng Việt là tiếng mẹ đẻ, vì vậy những lỗi điển hình bao gồm:
dấu thanh tiếng Séc (háček), phụ âm đặc biệt (ř, č, ž, š), trật tự từ, giới từ, và các đuôi danh từ biến cách.

Hãy trả về JSON theo đúng định dạng sau (không có văn bản nào khác):
{
  "overall_score": <int 0-100>,
  "pronunciation": <int 0-100>,
  "fluency": <int 0-100>,
  "vocabulary": <int 0-100>,
  "task_achievement": <int 0-100>,
  "transcript_issues": [{ "word": "<từ bị lỗi hoặc khó>", "suggestion": "<gợi ý phát âm/sử dụng đúng>" }],
  "strengths": ["<điểm mạnh 1>", "<điểm mạnh 2>"],
  "improvements": ["<điểm cần cải thiện 1>", "<điểm cần cải thiện 2>"],
  "corrected_answer": "<câu trả lời đã được sửa và hoàn chỉnh>",
  "overall_feedback": "<nhận xét tổng quan 1-2 câu bằng tiếng Việt>"
}
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
      lesson_id?: string;
      question_id?: string;
      audio_b64?: string;
    };

    const { lesson_id, question_id, audio_b64 } = body;

    if (!question_id) {
      return new Response(JSON.stringify({ error: 'question_id is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Get authenticated user (may be null for anonymous)
    const authHeader = req.headers.get('Authorization');
    let userId: string | null = null;
    if (authHeader) {
      const { data: { user } } = await supabase.auth.getUser(
        authHeader.replace('Bearer ', ''),
      );
      userId = user?.id ?? null;
    }

    // Fetch question prompt for scoring context
    const { data: question } = await supabase
      .from('questions')
      .select('prompt')
      .eq('id', question_id)
      .maybeSingle();

    // Insert attempt row with status 'processing'
    const { data: attempt, error: insertErr } = await supabase
      .from('ai_speaking_attempts')
      .insert({
        user_id: userId,
        exercise_id: null,
        audio_key: `speaking/${question_id}/${Date.now()}.m4a`,
        status: 'processing',
      })
      .select('id')
      .single();

    if (insertErr || !attempt) {
      throw new Error(`Failed to create attempt: ${insertErr?.message}`);
    }

    const attemptId: string = (attempt as Record<string, unknown>)['id'] as string;

    // If no audio provided (web MVP stub), mark error and return
    if (!audio_b64 || audio_b64.length === 0) {
      await supabase
        .from('ai_speaking_attempts')
        .update({
          status: 'error',
          error_message: 'No audio data provided',
          updated_at: new Date().toISOString(),
        })
        .eq('id', attemptId);

      return new Response(
        JSON.stringify({ attempt_id: attemptId, error: 'No audio data' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Decode base64 audio
    const audioBytes = Uint8Array.from(atob(audio_b64), (c) => c.charCodeAt(0));
    const apiKey = getOpenAIKey();

    // Step 1: Transcribe with Whisper
    const transcript = await transcribeAudio(apiKey, audioBytes, `audio_${attemptId}.m4a`);

    // Step 2: Score with GPT-4o-mini
    const questionPrompt = (question as Record<string, unknown> | null)?.['prompt'] as string ?? '';
    const userMessage = `Câu hỏi thi: "${questionPrompt}"\n\nPhiên âm bài nói của học viên:\n"${transcript}"`;
    const scored = await chatComplete(apiKey, SPEAKING_SYSTEM_PROMPT, userMessage);

    const overallScore = Number(scored['overall_score'] ?? 0);
    const metrics = {
      pronunciation: Number(scored['pronunciation'] ?? 0),
      fluency: Number(scored['fluency'] ?? 0),
      vocabulary: Number(scored['vocabulary'] ?? 0),
      task_achievement: Number(scored['task_achievement'] ?? 0),
    };
    const issues = (scored['transcript_issues'] as Array<{ word: string; suggestion: string }>) ?? [];
    const strengths = (scored['strengths'] as string[]) ?? [];
    const improvements = (scored['improvements'] as string[]) ?? [];
    const correctedAnswer = String(scored['corrected_answer'] ?? '');

    // Update attempt with results
    // overall_feedback is computed in speaking-result from strengths/improvements
    await supabase
      .from('ai_speaking_attempts')
      .update({
        status: 'ready',
        transcript,
        overall_score: overallScore,
        metrics,
        issues,
        strengths,
        improvements,
        corrected_answer: correctedAnswer,
        updated_at: new Date().toISOString(),
      })
      .eq('id', attemptId);

    return new Response(
      JSON.stringify({ attempt_id: attemptId }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('speaking-upload error:', err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
