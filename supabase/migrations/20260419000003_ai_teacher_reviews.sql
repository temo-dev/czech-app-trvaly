create extension if not exists pgcrypto;

create table if not exists public.ai_teacher_reviews (
  id uuid primary key default gen_random_uuid(),
  request_key text not null unique,
  user_id uuid references public.profiles(id) on delete set null,
  source text not null check (source in ('mock_test', 'simulator', 'practice', 'lesson')),
  modality text not null check (modality in ('objective', 'writing', 'speaking')),
  status text not null default 'processing' check (status in ('processing', 'ready', 'error')),
  verdict text check (verdict in ('correct', 'incorrect', 'needs_retry', 'partial')),
  question_id uuid not null references public.questions(id) on delete cascade,
  exercise_id uuid references public.exercises(id) on delete set null,
  lesson_id uuid references public.lessons(id) on delete set null,
  exam_attempt_id uuid references public.exam_attempts(id) on delete set null,
  writing_attempt_id uuid references public.ai_writing_attempts(id) on delete set null,
  speaking_attempt_id uuid references public.ai_speaking_attempts(id) on delete set null,
  access_level text not null default 'basic' check (access_level in ('basic', 'premium')),
  input_payload jsonb not null default '{}'::jsonb,
  result_payload jsonb,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_ai_teacher_reviews_question
  on public.ai_teacher_reviews(question_id);

create index if not exists idx_ai_teacher_reviews_exam
  on public.ai_teacher_reviews(exam_attempt_id);

create index if not exists idx_ai_teacher_reviews_user
  on public.ai_teacher_reviews(user_id);

create index if not exists idx_ai_teacher_reviews_writing_attempt
  on public.ai_teacher_reviews(writing_attempt_id);

create index if not exists idx_ai_teacher_reviews_speaking_attempt
  on public.ai_teacher_reviews(speaking_attempt_id);

alter table public.ai_teacher_reviews enable row level security;

drop policy if exists "service role can manage ai_teacher_reviews"
  on public.ai_teacher_reviews;

create policy "service role can manage ai_teacher_reviews"
  on public.ai_teacher_reviews
  for all
  to service_role
  using (true)
  with check (true);

create or replace function public.set_ai_teacher_reviews_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_ai_teacher_reviews_updated_at
  on public.ai_teacher_reviews;

create trigger trg_ai_teacher_reviews_updated_at
before update on public.ai_teacher_reviews
for each row
execute function public.set_ai_teacher_reviews_updated_at();
