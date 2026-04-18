import { corsHeaders } from '../_shared/cors.ts';
import { getOpenAIKey, transcribeAudio, chatComplete } from '../_shared/openai.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SPEAKING_SYSTEM_PROMPT = `
Bạn là giám khảo chấm điểm bài thi nói tiếng Séc cho người học người Việt Nam.
Người học đang luyện thi kỳ thi trình độ A2 để xin trạng thái Trvalý pobyt (cư trú lâu dài) tại Cộng hòa Séc.

⚠️ QUY TẮC QUAN TRỌNG NHẤT: Bài thi YÊU CẦU trả lời bằng TIẾNG SÉC.
- Nếu phiên âm KHÔNG phải tiếng Séc (tiếng Anh, tiếng Việt, hoặc ngôn ngữ khác), hãy cho điểm 0 tất cả các tiêu chí và giải thích rõ lý do bằng tiếng Việt.
- Chỉ chấm điểm bình thường khi bài nói thực sự là tiếng Séc.

Tiêu chí chấm (chỉ áp dụng khi bài nói là tiếng Séc):
- pronunciation (phát âm): 0–100 — độ rõ ràng và chính xác của âm thanh tiếng Séc
- fluency (độ lưu loát): 0–100 — nhịp nói, ngắt câu tự nhiên, không ngập ngừng nhiều
- vocabulary (từ vựng): 0–100 — sử dụng từ phù hợp, đa dạng
- task_achievement (trả lời đúng câu hỏi): 0–100 — câu trả lời có liên quan và đáp ứng đúng yêu cầu của câu hỏi không

Lưu ý với bài tiếng Séc: Người học nói tiếng Việt là tiếng mẹ đẻ, những lỗi điển hình bao gồm:
dấu thanh tiếng Séc (háček), phụ âm đặc biệt (ř, č, ž, š), trật tự từ, giới từ, và các đuôi danh từ biến cách.

Hãy trả về JSON theo đúng định dạng sau (không có văn bản nào khác):
{
  "is_czech": <true nếu bài nói là tiếng Séc, false nếu không phải>,
  "overall_score": <int 0-100, bắt buộc là 0 nếu is_czech = false>,
  "pronunciation": <int 0-100, bắt buộc là 0 nếu is_czech = false>,
  "fluency": <int 0-100, bắt buộc là 0 nếu is_czech = false>,
  "vocabulary": <int 0-100, bắt buộc là 0 nếu is_czech = false>,
  "task_achievement": <int 0-100, bắt buộc là 0 nếu is_czech = false>,
  "transcript_issues": [],
  "pronunciation_feedback": {
    "detail": "<Nếu không phải tiếng Séc: để trống. Nếu tiếng Séc: nhận xét CHI TIẾT về phát âm, liệt kê lỗi cụ thể.>",
    "tip": "<Lời khuyên ngắn 1 câu, actionable: cách luyện phát âm đúng. Để trống nếu không phải tiếng Séc.>"
  },
  "grammar_feedback": {
    "detail": "<Nếu không phải tiếng Séc: để trống. Nếu tiếng Séc: nhận xét CHI TIẾT về ngữ pháp.>",
    "tip": "<Lời khuyên ngắn 1 câu về ngữ pháp. Để trống nếu không phải tiếng Séc.>"
  },
  "vocabulary_feedback": {
    "detail": "<Nếu không phải tiếng Séc: để trống. Nếu tiếng Séc: nhận xét CHI TIẾT về từ vựng.>",
    "tip": "<Lời khuyên ngắn 1 câu về từ vựng. Để trống nếu không phải tiếng Séc.>"
  },
  "content_feedback": {
    "detail": "<Nếu không phải tiếng Séc: để trống. Nếu tiếng Séc: nhận xét về nội dung.>",
    "tip": "<Lời khuyên ngắn 1 câu về nội dung/cách trả lời. Để trống nếu không phải tiếng Séc.>"
  },
  "short_tips": ["<tip1 ngắn gọn>", "<tip2 ngắn gọn>", "<tip3 ngắn gọn>"],
  "overall_feedback": "<Nếu không phải tiếng Séc: giải thích rõ bằng tiếng Việt rằng bài thi yêu cầu trả lời bằng tiếng Séc, không chấp nhận ngôn ngữ khác, và ngôn ngữ phát hiện là gì. Nếu tiếng Séc: nhận xét tổng quan 2-3 câu.>",
  "corrected_answer": "<Nếu không phải tiếng Séc: để trống. Nếu tiếng Séc: câu trả lời đã sửa hoàn chỉnh.>"
}

Lưu ý: short_tips là tối đa 3 lời khuyên ngắn gọn, mỗi tip tối đa 15 từ, ưu tiên lỗi cần sửa nhất. Để trống array [] nếu không phải tiếng Séc.
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

    // Step 1: Transcribe with Whisper (auto language detection)
    const { text: transcript, detectedLanguage } = await transcribeAudio(
      apiKey, audioBytes, `audio_${attemptId}.m4a`,
    );

    // Step 2: Score with GPT-4o-mini
    const questionPrompt = (question as Record<string, unknown> | null)?.['prompt'] as string ?? '';
    const userMessage = `Câu hỏi thi: "${questionPrompt}"\n\nNgôn ngữ Whisper phát hiện: ${detectedLanguage}\n\nPhiên âm bài nói của học viên:\n"${transcript}"`;
    const scored = await chatComplete(apiKey, SPEAKING_SYSTEM_PROMPT, userMessage);

    // Hard enforcement: if GPT or Whisper detects non-Czech, zero out all scores
    const isCzechByGpt = scored['is_czech'] === true;
    const isCzechByWhisper = detectedLanguage === 'czech' || detectedLanguage === 'cs';
    const isCzech = isCzechByGpt && isCzechByWhisper;

    const getFeedbackDetail = (val: unknown): string => {
      if (typeof val === 'string') return val;
      if (val && typeof val === 'object') {
        return String((val as Record<string, unknown>)['detail'] ?? '');
      }
      return '';
    };
    const getFeedbackTip = (val: unknown): string => {
      if (val && typeof val === 'object') {
        return String((val as Record<string, unknown>)['tip'] ?? '');
      }
      return '';
    };

    const overallScore = isCzech ? Number(scored['overall_score'] ?? 0) : 0;
    const nonCzechFeedback = isCzech ? '' : String(scored['overall_feedback'] ?? `Bài thi yêu cầu trả lời bằng tiếng Séc. Whisper phát hiện ngôn ngữ: "${detectedLanguage}". Vui lòng thử lại bằng tiếng Séc.`);
    const metrics = {
      pronunciation: isCzech ? Number(scored['pronunciation'] ?? 0) : 0,
      pronunciation_feedback: isCzech ? getFeedbackDetail(scored['pronunciation_feedback']) : '',
      pronunciation_tip: isCzech ? getFeedbackTip(scored['pronunciation_feedback']) : '',
      fluency: isCzech ? Number(scored['fluency'] ?? 0) : 0,
      vocabulary: isCzech ? Number(scored['vocabulary'] ?? 0) : 0,
      vocabulary_feedback: isCzech ? getFeedbackDetail(scored['vocabulary_feedback']) : '',
      vocabulary_tip: isCzech ? getFeedbackTip(scored['vocabulary_feedback']) : '',
      task_achievement: isCzech ? Number(scored['task_achievement'] ?? 0) : 0,
      content_feedback: isCzech ? getFeedbackDetail(scored['content_feedback']) : '',
      content_tip: isCzech ? getFeedbackTip(scored['content_feedback']) : '',
      grammar_feedback: isCzech ? getFeedbackDetail(scored['grammar_feedback']) : '',
      grammar_tip: isCzech ? getFeedbackTip(scored['grammar_feedback']) : '',
      overall_feedback: isCzech ? String(scored['overall_feedback'] ?? '') : nonCzechFeedback,
      short_tips: isCzech ? ((scored['short_tips'] as string[]) ?? []) : [],
    };
    const issues = (scored['transcript_issues'] as Array<{ word: string; type?: string; suggestion: string }>) ?? [];
    const correctedAnswer = String(scored['corrected_answer'] ?? '');

    await supabase
      .from('ai_speaking_attempts')
      .update({
        status: 'ready',
        transcript,
        overall_score: overallScore,
        metrics,
        issues,
        strengths: [],
        improvements: [],
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
