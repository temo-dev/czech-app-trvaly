-- Grant service_role access to AI attempt tables used by edge functions
GRANT SELECT, INSERT, UPDATE ON public.ai_speaking_attempts TO service_role;
GRANT SELECT, INSERT, UPDATE ON public.ai_writing_attempts TO service_role;

-- grade-exam needs to read questions, options, sections and write to exam_results
GRANT SELECT ON public.questions TO service_role;
GRANT SELECT ON public.question_options TO service_role;
GRANT SELECT ON public.exam_sections TO service_role;
GRANT SELECT, UPDATE ON public.exam_attempts TO service_role;
GRANT SELECT, INSERT, DELETE ON public.exam_results TO service_role;
