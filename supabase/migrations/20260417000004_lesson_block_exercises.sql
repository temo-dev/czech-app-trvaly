-- Replace lesson_blocks.exercise_id (1-to-1) with lesson_block_exercises (1-to-many)

-- 1. Create junction table
CREATE TABLE public.lesson_block_exercises (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  block_id     uuid NOT NULL REFERENCES public.lesson_blocks(id) ON DELETE CASCADE,
  exercise_id  uuid NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
  order_index  int  NOT NULL DEFAULT 0,
  UNIQUE(block_id, exercise_id)
);

CREATE INDEX idx_lesson_block_exercises_block ON public.lesson_block_exercises(block_id);

-- 2. Migrate existing 1-to-1 links
INSERT INTO public.lesson_block_exercises (block_id, exercise_id, order_index)
SELECT id, exercise_id, 1
FROM public.lesson_blocks
WHERE exercise_id IS NOT NULL;

-- 3. Drop old column
ALTER TABLE public.lesson_blocks DROP COLUMN IF EXISTS exercise_id;

-- 4. RLS
ALTER TABLE public.lesson_block_exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_lesson_block_exercises"
  ON public.lesson_block_exercises FOR SELECT USING (true);

CREATE POLICY "admin_all_lesson_block_exercises"
  ON public.lesson_block_exercises FOR ALL
  USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 5. Service role access
GRANT ALL ON public.lesson_block_exercises TO service_role;
