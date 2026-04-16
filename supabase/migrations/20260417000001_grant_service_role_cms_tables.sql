-- Grant service_role full access to CMS-managed tables
-- service_role bypasses RLS but still needs table-level GRANT

GRANT ALL ON public.exams             TO service_role;
GRANT ALL ON public.exam_sections     TO service_role;
GRANT ALL ON public.questions         TO service_role;
GRANT ALL ON public.question_options  TO service_role;
GRANT ALL ON public.exercises         TO service_role;
GRANT ALL ON public.courses           TO service_role;
GRANT ALL ON public.modules           TO service_role;
GRANT ALL ON public.lessons           TO service_role;
GRANT ALL ON public.lesson_blocks     TO service_role;
GRANT ALL ON public.teacher_reviews   TO service_role;
GRANT ALL ON public.teacher_comments  TO service_role;
GRANT ALL ON public.profiles          TO service_role;
