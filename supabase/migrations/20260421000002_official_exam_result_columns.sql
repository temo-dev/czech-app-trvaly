ALTER TABLE public.questions
ADD COLUMN IF NOT EXISTS accepted_answers text[] NOT NULL DEFAULT '{}';

ALTER TABLE public.exam_results
ADD COLUMN IF NOT EXISTS passed boolean NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS written_score int NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS written_total int NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS written_pass_threshold int NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS speaking_score int NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS speaking_total int NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS speaking_pass_threshold int NOT NULL DEFAULT 0;

UPDATE public.exam_results
SET passed = total_score >= pass_threshold
WHERE written_total = 0
  AND speaking_total = 0;
