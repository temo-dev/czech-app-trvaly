create extension if not exists pgcrypto;

create table if not exists public.exam_analysis (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.exam_attempts(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete set null,
  status text not null default 'processing'
    check (status in ('processing', 'ready', 'error')),
  question_feedbacks jsonb not null default '{}'::jsonb,
  skill_insights jsonb not null default '{}'::jsonb,
  overall_recommendations jsonb not null default '[]'::jsonb,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (attempt_id)
);

create index if not exists idx_exam_analysis_user_id
  on public.exam_analysis(user_id);

create index if not exists idx_exam_analysis_status
  on public.exam_analysis(status);

alter table public.exam_analysis enable row level security;

drop policy if exists "service role can manage exam_analysis"
  on public.exam_analysis;

create policy "service role can manage exam_analysis"
  on public.exam_analysis
  for all
  to service_role
  using (true)
  with check (true);

drop policy if exists "authenticated users can read own exam_analysis"
  on public.exam_analysis;

create policy "authenticated users can read own exam_analysis"
  on public.exam_analysis
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "anon users can read anonymous exam_analysis"
  on public.exam_analysis;

create policy "anon users can read anonymous exam_analysis"
  on public.exam_analysis
  for select
  to anon
  using (
    exists (
      select 1
      from public.exam_attempts attempt
      where attempt.id = exam_analysis.attempt_id
        and attempt.user_id is null
    )
  );

grant select on public.exam_analysis to anon, authenticated;
grant select, insert, update, delete on public.exam_analysis to service_role;

create or replace function public.set_exam_analysis_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_exam_analysis_updated_at
  on public.exam_analysis;

create trigger trg_exam_analysis_updated_at
before update on public.exam_analysis
for each row
execute function public.set_exam_analysis_updated_at();
