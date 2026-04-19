-- Cache for AI-generated question feedback.
-- Keyed by (question_id, user_answer_hash) — avoids re-calling GPT for identical answers.

CREATE TABLE IF NOT EXISTS public.question_ai_feedback (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id         uuid NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  user_answer_hash    text NOT NULL,
  question_type       text NOT NULL DEFAULT 'mcq',
  error_analysis      text NOT NULL DEFAULT '',
  correct_explanation text NOT NULL DEFAULT '',
  short_tip           text NOT NULL DEFAULT '',
  key_concept         text NOT NULL DEFAULT '',
  matching_feedback   jsonb,
  created_at          timestamptz NOT NULL DEFAULT now(),
  UNIQUE (question_id, user_answer_hash)
);

CREATE INDEX IF NOT EXISTS idx_question_ai_feedback_question
  ON public.question_ai_feedback(question_id);

ALTER TABLE public.question_ai_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qaf_select" ON public.question_ai_feedback
  FOR SELECT USING (true);

CREATE POLICY "qaf_service_insert" ON public.question_ai_feedback
  FOR INSERT WITH CHECK (true);

CREATE POLICY "qaf_service_update" ON public.question_ai_feedback
  FOR UPDATE USING (true);

GRANT SELECT ON public.question_ai_feedback TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.question_ai_feedback TO service_role;
