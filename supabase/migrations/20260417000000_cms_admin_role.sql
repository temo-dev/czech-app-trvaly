-- ════════════════════════════════════════════════════════
-- CMS: Add 'admin' role + admin-scoped RLS policies
-- ════════════════════════════════════════════════════════

-- 1. Expand the role check constraint
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('learner', 'teacher', 'admin'));

-- 2. Helper function used in RLS policies
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- 3. Admin full-read on profiles
DROP POLICY IF EXISTS "admin_profiles_select" ON public.profiles;
CREATE POLICY "admin_profiles_select"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id OR public.is_admin());

-- 4. Admin write on profiles
DROP POLICY IF EXISTS "admin_profiles_update" ON public.profiles;
CREATE POLICY "admin_profiles_update"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id OR public.is_admin());

-- 5. Admin full CRUD on content tables

DROP POLICY IF EXISTS "admin_courses_all" ON public.courses;
CREATE POLICY "admin_courses_all" ON public.courses
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "admin_modules_all" ON public.modules;
CREATE POLICY "admin_modules_all" ON public.modules
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "admin_lessons_all" ON public.lessons;
CREATE POLICY "admin_lessons_all" ON public.lessons
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "admin_lesson_blocks_all" ON public.lesson_blocks;
CREATE POLICY "admin_lesson_blocks_all" ON public.lesson_blocks
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "admin_exercises_all" ON public.exercises;
CREATE POLICY "admin_exercises_all" ON public.exercises
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "admin_questions_all" ON public.questions;
CREATE POLICY "admin_questions_all" ON public.questions
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "admin_question_options_all" ON public.question_options;
CREATE POLICY "admin_question_options_all" ON public.question_options
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "admin_exams_all" ON public.exams;
CREATE POLICY "admin_exams_all" ON public.exams
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "admin_exam_sections_all" ON public.exam_sections;
CREATE POLICY "admin_exam_sections_all" ON public.exam_sections
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "admin_teacher_reviews_all" ON public.teacher_reviews;
CREATE POLICY "admin_teacher_reviews_all" ON public.teacher_reviews
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "admin_teacher_comments_all" ON public.teacher_comments;
CREATE POLICY "admin_teacher_comments_all" ON public.teacher_comments
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 6. Admin read-only for analytics
DROP POLICY IF EXISTS "admin_exam_attempts_select" ON public.exam_attempts;
CREATE POLICY "admin_exam_attempts_select" ON public.exam_attempts
  FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "admin_exam_results_select" ON public.exam_results;
CREATE POLICY "admin_exam_results_select" ON public.exam_results
  FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "admin_ai_speaking_select" ON public.ai_speaking_attempts;
CREATE POLICY "admin_ai_speaking_select" ON public.ai_speaking_attempts
  FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "admin_ai_writing_select" ON public.ai_writing_attempts;
CREATE POLICY "admin_ai_writing_select" ON public.ai_writing_attempts
  FOR SELECT USING (public.is_admin());

-- 7. Dashboard aggregate RPC
CREATE OR REPLACE FUNCTION public.cms_dashboard_stats()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN jsonb_build_object(
    'total_questions',       (SELECT count(*) FROM public.questions),
    'total_exercises',       (SELECT count(*) FROM public.exercises),
    'total_courses',         (SELECT count(*) FROM public.courses),
    'total_lessons',         (SELECT count(*) FROM public.lessons),
    'total_users',           (SELECT count(*) FROM public.profiles),
    'pending_reviews',       (SELECT count(*) FROM public.teacher_reviews WHERE status = 'pending'),
    'pending_ai_speaking',   (SELECT count(*) FROM public.ai_speaking_attempts WHERE status = 'processing'),
    'pending_ai_writing',    (SELECT count(*) FROM public.ai_writing_attempts  WHERE status = 'processing')
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.cms_dashboard_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
