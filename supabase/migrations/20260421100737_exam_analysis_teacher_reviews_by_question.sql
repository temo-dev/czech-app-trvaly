alter table public.exam_analysis
add column if not exists teacher_reviews_by_question jsonb not null default '{}'::jsonb;
