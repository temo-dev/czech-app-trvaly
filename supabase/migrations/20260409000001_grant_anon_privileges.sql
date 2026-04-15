-- Fix: permission denied for anon role
-- PostgreSQL requires explicit GRANT even when RLS policies exist.
-- RLS policies filter WHICH rows, but table GRANTs control IF the role can query at all.

GRANT SELECT ON public.exams TO anon, authenticated;
GRANT SELECT ON public.exam_sections TO anon, authenticated;
GRANT SELECT ON public.questions TO anon, authenticated;
GRANT SELECT ON public.question_options TO anon, authenticated;

-- exam_attempts: anon users can create + read + update their own attempts
GRANT INSERT, SELECT, UPDATE ON public.exam_attempts TO anon, authenticated;

-- exam_results: anyone can insert result, owner can read
GRANT INSERT, SELECT ON public.exam_results TO anon, authenticated;
