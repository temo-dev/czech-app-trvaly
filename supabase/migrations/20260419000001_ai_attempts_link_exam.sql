-- Link AI attempts to exam context so grade-exam can JOIN real AI scores
-- instead of using 50% placeholder for speaking/writing questions.

ALTER TABLE public.ai_speaking_attempts
  ADD COLUMN IF NOT EXISTS question_id uuid REFERENCES public.questions(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS exam_attempt_id uuid REFERENCES public.exam_attempts(id) ON DELETE SET NULL;

ALTER TABLE public.ai_writing_attempts
  ADD COLUMN IF NOT EXISTS question_id uuid REFERENCES public.questions(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS exam_attempt_id uuid REFERENCES public.exam_attempts(id) ON DELETE SET NULL;

-- grade-exam sets this flag when speaking/writing AI scoring is still in progress
ALTER TABLE public.exam_results
  ADD COLUMN IF NOT EXISTS ai_grading_pending boolean NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_ai_speaking_exam ON public.ai_speaking_attempts(exam_attempt_id);
CREATE INDEX IF NOT EXISTS idx_ai_speaking_question ON public.ai_speaking_attempts(question_id);
CREATE INDEX IF NOT EXISTS idx_ai_writing_exam ON public.ai_writing_attempts(exam_attempt_id);
CREATE INDEX IF NOT EXISTS idx_ai_writing_question ON public.ai_writing_attempts(question_id);
