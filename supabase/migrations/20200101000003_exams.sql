-- ============================================================
-- Migration 002: exams, exam_sections, exam_attempts, exam_results
-- ============================================================

-- Exam metadata
create table if not exists public.exams (
  id               uuid primary key default gen_random_uuid(),
  title            text not null,
  duration_minutes int  not null,
  is_active        bool not null default true,
  created_at       timestamptz not null default now()
);

-- Sections per exam (e.g. reading, listening, writing, speaking)
create table if not exists public.exam_sections (
  id                       uuid primary key default gen_random_uuid(),
  exam_id                  uuid not null references public.exams(id) on delete cascade,
  skill                    text not null,   -- 'reading' | 'listening' | 'writing' | 'speaking'
  label                    text not null,   -- displayed label in Vietnamese
  question_count           int  not null,
  section_duration_minutes int,             -- null = shared global timer
  order_index              int  not null default 0
);

-- One row per exam session (anon or authenticated)
create table if not exists public.exam_attempts (
  id                uuid primary key default gen_random_uuid(),
  exam_id           uuid not null references public.exams(id),
  user_id           uuid references auth.users(id),  -- null = anonymous
  status            text not null default 'in_progress',  -- 'in_progress' | 'submitted'
  answers           jsonb not null default '{}',
  remaining_seconds int,
  started_at        timestamptz not null default now(),
  submitted_at      timestamptz
);

-- Scored results (populated by submit-exam-attempt function)
create table if not exists public.exam_results (
  id              uuid primary key default gen_random_uuid(),
  attempt_id      uuid not null references public.exam_attempts(id) on delete cascade unique,
  user_id         uuid references auth.users(id),
  total_score     int  not null default 0,  -- 0–100
  pass_threshold  int  not null default 60,
  section_scores  jsonb not null default '{}',  -- { skill: { score, total } }
  weak_skills     text[] not null default '{}',
  created_at      timestamptz not null default now()
);

-- ── RLS ────────────────────────────────────────────────────────────────────

alter table public.exams          enable row level security;
alter table public.exam_sections  enable row level security;
alter table public.exam_attempts  enable row level security;
alter table public.exam_results   enable row level security;

-- Exams + sections: public read (guest needs to see exam info)
create policy "Public read exams"
  on public.exams for select using (true);

create policy "Public read exam_sections"
  on public.exam_sections for select using (true);

-- Attempts: anyone can create; only owner (or anon row) can read/update
create policy "Anyone can create attempt"
  on public.exam_attempts for insert with check (true);

create policy "Owner or anon can read attempt"
  on public.exam_attempts for select
  using (user_id = auth.uid() or user_id is null);

create policy "Owner or anon can update attempt"
  on public.exam_attempts for update
  using (user_id = auth.uid() or user_id is null);

-- Results: owner can read own result; anon result readable by attempt owner
create policy "Owner can read own result"
  on public.exam_results for select
  using (user_id = auth.uid() or user_id is null);

create policy "Anyone can insert result"
  on public.exam_results for insert
  with check (true);

create policy "Owner can update own result"
  on public.exam_results for update
  using (user_id = auth.uid() or user_id is null);

-- ── Seed data ───────────────────────────────────────────────────────────────

do $$
declare
  exam_id uuid;
begin
  -- Only seed if no exams exist yet
  if not exists (select 1 from public.exams limit 1) then
    insert into public.exams (title, duration_minutes)
    values ('Trvalý Pobyt — Bài thi thử (A2)', 45)
    returning id into exam_id;

    insert into public.exam_sections (exam_id, skill, label, question_count, order_index)
    values
      (exam_id, 'reading',   'Đọc hiểu (Čtení)',    10, 1),
      (exam_id, 'listening', 'Nghe hiểu (Poslech)', 10, 2),
      (exam_id, 'writing',   'Viết (Psaní)',          5, 3),
      (exam_id, 'speaking',  'Nói (Mluvení)',          5, 4);
  end if;
end;
$$;
