-- ============================================================
-- Trvalý Prep — Initial Schema Migration
-- Run this once in Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- ── Extensions ────────────────────────────────────────────────────────────────
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";


-- ══════════════════════════════════════════════════════════════════════════════
-- PROFILES
-- ══════════════════════════════════════════════════════════════════════════════
create table if not exists profiles (
  id                  uuid primary key references auth.users(id) on delete cascade,
  email               text not null,
  display_name        text,
  avatar_url          text,
  locale              text not null default 'vi',
  role                text not null default 'learner' check (role in ('learner', 'teacher')),
  exam_date           date,
  total_xp            int  not null default 0,
  weekly_xp           int  not null default 0,
  current_streak_days int  not null default 0,
  last_activity_date  date,
  notification_prefs  jsonb,
  created_at          timestamptz not null default now()
);

-- Auto-create profile on signup
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

-- RPC: atomic XP increment (used by gamification_provider)
create or replace function increment_xp(p_user_id uuid, p_amount int)
returns void language plpgsql security definer as $$
begin
  update profiles
  set total_xp  = total_xp  + p_amount,
      weekly_xp = weekly_xp + p_amount
  where id = p_user_id;
end;
$$;


-- ══════════════════════════════════════════════════════════════════════════════
-- EXAM CATALOGUE
-- ══════════════════════════════════════════════════════════════════════════════
create table if not exists exams (
  id                uuid primary key default uuid_generate_v4(),
  title             text not null,
  duration_minutes  int  not null default 90,
  is_active         bool not null default true,
  created_at        timestamptz not null default now()
);

create table if not exists exam_sections (
  id                       uuid primary key default uuid_generate_v4(),
  exam_id                  uuid not null references exams(id) on delete cascade,
  skill                    text not null check (skill in ('reading','listening','writing','speaking')),
  label                    text not null,
  question_count           int  not null default 10,
  section_duration_minutes int,          -- null = shared global timer
  order_index              int  not null default 0
);

create index if not exists idx_exam_sections_exam_id on exam_sections(exam_id);


-- ══════════════════════════════════════════════════════════════════════════════
-- QUESTION BANK
-- ══════════════════════════════════════════════════════════════════════════════
create table if not exists questions (
  id            uuid primary key default uuid_generate_v4(),
  section_id    uuid references exam_sections(id) on delete set null,
  type          text not null check (type in ('mcq','fill_blank','matching','ordering','reading_mcq','listening_mcq','speaking','writing')),
  skill         text not null,
  prompt        text not null,
  audio_url     text,
  image_url     text,
  passage_text  text,
  correct_answer text,
  explanation   text not null default '',
  points        int  not null default 1,
  order_index   int  not null default 0,
  created_at    timestamptz not null default now()
);

create table if not exists question_options (
  id          uuid primary key default uuid_generate_v4(),
  question_id uuid not null references questions(id) on delete cascade,
  text        text not null,
  image_url   text,
  is_correct  bool not null default false,
  order_index int  not null default 0
);

create index if not exists idx_questions_section_id      on questions(section_id);
create index if not exists idx_question_options_question on question_options(question_id);


-- ══════════════════════════════════════════════════════════════════════════════
-- EXAM ATTEMPTS & RESULTS
-- ══════════════════════════════════════════════════════════════════════════════
create table if not exists exam_attempts (
  id                uuid primary key default uuid_generate_v4(),
  exam_id           uuid not null references exams(id),
  user_id           uuid references profiles(id) on delete set null,  -- null = anonymous
  status            text not null default 'in_progress' check (status in ('in_progress','submitted','abandoned')),
  answers           jsonb not null default '{}',
  remaining_seconds int  not null default 0,
  started_at        timestamptz not null default now(),
  submitted_at      timestamptz
);

create index if not exists idx_exam_attempts_user_id on exam_attempts(user_id);
create index if not exists idx_exam_attempts_exam_id on exam_attempts(exam_id);

create table if not exists exam_results (
  id              uuid primary key default uuid_generate_v4(),
  attempt_id      uuid not null references exam_attempts(id) on delete cascade,
  user_id         uuid references profiles(id) on delete set null,
  total_score     int  not null default 0,
  pass_threshold  int  not null default 60,
  section_scores  jsonb not null default '{}',
  weak_skills     text[] not null default '{}',
  created_at      timestamptz not null default now()
);

create index if not exists idx_exam_results_user_id    on exam_results(user_id);
create index if not exists idx_exam_results_attempt_id on exam_results(attempt_id);


-- ══════════════════════════════════════════════════════════════════════════════
-- COURSE CATALOGUE
-- ══════════════════════════════════════════════════════════════════════════════
create table if not exists courses (
  id            uuid primary key default uuid_generate_v4(),
  slug          text unique not null,
  title         text not null,
  description   text not null default '',
  skill         text not null,
  is_premium    bool not null default false,
  thumbnail_url text,
  order_index   int  not null default 0,
  created_at    timestamptz not null default now()
);

create table if not exists modules (
  id            uuid primary key default uuid_generate_v4(),
  course_id     uuid not null references courses(id) on delete cascade,
  title         text not null,
  order_index   int  not null default 0,
  created_at    timestamptz not null default now()
);

create table if not exists lessons (
  id            uuid primary key default uuid_generate_v4(),
  module_id     uuid not null references modules(id) on delete cascade,
  title         text not null,
  order_index   int  not null default 0,
  created_at    timestamptz not null default now()
);

create table if not exists lesson_blocks (
  id          uuid primary key default uuid_generate_v4(),
  lesson_id   uuid not null references lessons(id) on delete cascade,
  type        text not null check (type in ('vocab','grammar','reading','listening','speaking','writing')),
  exercise_id uuid,   -- references exercises.id (set after exercises table is created)
  order_index int  not null default 0  -- 1–6
);

create index if not exists idx_modules_course_id     on modules(course_id);
create index if not exists idx_lessons_module_id     on lessons(module_id);
create index if not exists idx_lesson_blocks_lesson  on lesson_blocks(lesson_id);


-- ══════════════════════════════════════════════════════════════════════════════
-- EXERCISES
-- ══════════════════════════════════════════════════════════════════════════════
create table if not exists exercises (
  id           uuid primary key default uuid_generate_v4(),
  type         text not null,
  skill        text not null,
  content_json jsonb not null default '{}',
  asset_urls   text[] not null default '{}',
  xp_reward    int  not null default 10,
  created_at   timestamptz not null default now()
);

-- Add FK constraint now that exercises table exists (idempotent)
do $$ begin
  alter table lesson_blocks
    add constraint fk_lesson_blocks_exercise
    foreign key (exercise_id) references exercises(id) on delete set null;
exception when duplicate_object then null;
end $$;

create table if not exists exercise_attempts (
  id              uuid primary key default uuid_generate_v4(),
  exercise_id     uuid not null references exercises(id),
  user_id         uuid not null references profiles(id) on delete cascade,
  lesson_block_id uuid references lesson_blocks(id) on delete set null,
  answer          jsonb not null default '{}',
  is_correct      bool not null default false,
  xp_awarded      int  not null default 0,
  attempted_at    timestamptz not null default now()
);

create index if not exists idx_exercise_attempts_user    on exercise_attempts(user_id);
create index if not exists idx_exercise_attempts_exercise on exercise_attempts(exercise_id);


-- ══════════════════════════════════════════════════════════════════════════════
-- USER PROGRESS  (one row per block completed by user)
-- ══════════════════════════════════════════════════════════════════════════════
create table if not exists user_progress (
  id              uuid primary key default uuid_generate_v4(),
  user_id         uuid not null references profiles(id) on delete cascade,
  lesson_id       uuid not null references lessons(id) on delete cascade,
  lesson_block_id uuid references lesson_blocks(id) on delete set null,
  completed_at    timestamptz not null default now(),
  unique (user_id, lesson_block_id)
);

create index if not exists idx_user_progress_user   on user_progress(user_id);
create index if not exists idx_user_progress_lesson on user_progress(lesson_id);


-- ══════════════════════════════════════════════════════════════════════════════
-- AI FEEDBACK
-- ══════════════════════════════════════════════════════════════════════════════
create table if not exists ai_speaking_attempts (
  id               uuid primary key default uuid_generate_v4(),
  user_id          uuid references profiles(id) on delete set null,
  exercise_id      uuid references exercises(id) on delete set null,
  audio_key        text,
  status           text not null default 'processing' check (status in ('processing','ready','error')),
  overall_score    int,
  metrics          jsonb,   -- { pronunciation, fluency, vocabulary }
  transcript       text,
  issues           jsonb,   -- [{ word, suggestion }]
  strengths        text[],
  improvements     text[],
  corrected_answer text,
  error_message    text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index if not exists idx_ai_speaking_user on ai_speaking_attempts(user_id);

create table if not exists ai_writing_attempts (
  id               uuid primary key default uuid_generate_v4(),
  user_id          uuid references profiles(id) on delete set null,
  exercise_id      uuid references exercises(id) on delete set null,
  prompt_text      text,
  answer_text      text,
  rubric_type      text check (rubric_type in ('letter','essay','form')),
  status           text not null default 'processing' check (status in ('processing','ready','error')),
  overall_score    int,
  metrics          jsonb,   -- { grammar, vocabulary, coherence, task_achievement }
  grammar_notes    jsonb,   -- [{ original, corrected, explanation }]
  vocabulary_notes jsonb,   -- [{ original, suggestion }]
  corrected_essay  text,
  error_message    text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index if not exists idx_ai_writing_user on ai_writing_attempts(user_id);


-- ══════════════════════════════════════════════════════════════════════════════
-- TEACHER FEEDBACK
-- ══════════════════════════════════════════════════════════════════════════════
create table if not exists teacher_reviews (
  id           uuid primary key default uuid_generate_v4(),
  user_id      uuid not null references profiles(id) on delete cascade,
  skill        text not null check (skill in ('writing','speaking')),
  status       text not null default 'pending' check (status in ('pending','reviewed','closed')),
  preview_text text,
  unread_count int  not null default 0,
  created_at   timestamptz not null default now()
);

create table if not exists teacher_comments (
  id          uuid primary key default uuid_generate_v4(),
  review_id   uuid not null references teacher_reviews(id) on delete cascade,
  body        text not null,
  is_teacher  bool not null default false,
  author_name text,
  created_at  timestamptz not null default now()
);

create index if not exists idx_teacher_reviews_user   on teacher_reviews(user_id);
create index if not exists idx_teacher_comments_review on teacher_comments(review_id);


-- ══════════════════════════════════════════════════════════════════════════════
-- LEADERBOARD (simple table — refresh weekly via cron or edge function)
-- ══════════════════════════════════════════════════════════════════════════════
create table if not exists leaderboard_weekly (
  id           uuid primary key default uuid_generate_v4(),
  user_id      uuid not null references profiles(id) on delete cascade,
  display_name text not null,
  avatar_url   text,
  weekly_xp    int  not null default 0,
  week_start   date not null default date_trunc('week', now())::date,
  unique (user_id, week_start)
);

create index if not exists idx_leaderboard_weekly_xp on leaderboard_weekly(weekly_xp desc);

-- RPC: refresh leaderboard_weekly from profiles.weekly_xp
create or replace function refresh_leaderboard_weekly()
returns void language plpgsql security definer as $$
declare
  week_start date := date_trunc('week', now())::date;
begin
  insert into leaderboard_weekly (user_id, display_name, avatar_url, weekly_xp, week_start)
  select id, coalesce(display_name, email), avatar_url, weekly_xp, week_start
  from profiles
  where weekly_xp > 0
  on conflict (user_id, week_start) do update
    set weekly_xp    = excluded.weekly_xp,
        display_name = excluded.display_name,
        avatar_url   = excluded.avatar_url;
end;
$$;


-- ══════════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ══════════════════════════════════════════════════════════════════════════════

alter table profiles              enable row level security;
alter table exams                 enable row level security;
alter table exam_sections         enable row level security;
alter table questions             enable row level security;
alter table question_options      enable row level security;
alter table exam_attempts         enable row level security;
alter table exam_results          enable row level security;
alter table courses               enable row level security;
alter table modules               enable row level security;
alter table lessons               enable row level security;
alter table lesson_blocks         enable row level security;
alter table exercises             enable row level security;
alter table exercise_attempts     enable row level security;
alter table user_progress         enable row level security;
alter table ai_speaking_attempts  enable row level security;
alter table ai_writing_attempts   enable row level security;
alter table teacher_reviews       enable row level security;
alter table teacher_comments      enable row level security;
alter table leaderboard_weekly    enable row level security;

-- profiles: own row only
create policy "profiles_select_own" on profiles for select using (auth.uid() = id);
create policy "profiles_update_own" on profiles for update using (auth.uid() = id);

-- public read: exam catalogue, questions, courses, modules, lessons, exercises
create policy "exams_public_read"          on exams           for select using (true);
create policy "exam_sections_public_read"  on exam_sections   for select using (true);
create policy "questions_public_read"      on questions        for select using (true);
create policy "question_options_public_read" on question_options for select using (true);
create policy "courses_public_read"        on courses          for select using (true);
create policy "modules_public_read"        on modules          for select using (true);
create policy "lessons_public_read"        on lessons          for select using (true);
create policy "lesson_blocks_public_read"  on lesson_blocks    for select using (true);
create policy "exercises_public_read"      on exercises        for select using (true);
create policy "leaderboard_public_read"    on leaderboard_weekly for select using (true);

-- exam_attempts: own rows (user_id = auth.uid) OR anonymous (user_id is null)
create policy "exam_attempts_select" on exam_attempts for select
  using (user_id = auth.uid() or user_id is null);
create policy "exam_attempts_insert" on exam_attempts for insert
  with check (user_id = auth.uid() or user_id is null);
create policy "exam_attempts_update" on exam_attempts for update
  using (user_id = auth.uid() or user_id is null);

-- exam_results: own rows
create policy "exam_results_select" on exam_results for select using (user_id = auth.uid());
create policy "exam_results_insert" on exam_results for insert with check (user_id = auth.uid() or user_id is null);

-- exercise_attempts: own rows
create policy "exercise_attempts_select" on exercise_attempts for select using (user_id = auth.uid());
create policy "exercise_attempts_insert" on exercise_attempts for insert with check (user_id = auth.uid());

-- user_progress: own rows
create policy "user_progress_select" on user_progress for select using (user_id = auth.uid());
create policy "user_progress_insert" on user_progress for insert with check (user_id = auth.uid());
create policy "user_progress_delete" on user_progress for delete using (user_id = auth.uid());

-- AI attempts: own rows
create policy "ai_speaking_select" on ai_speaking_attempts for select using (user_id = auth.uid());
create policy "ai_speaking_insert" on ai_speaking_attempts for insert with check (user_id = auth.uid() or user_id is null);
create policy "ai_speaking_update" on ai_speaking_attempts for update using (user_id = auth.uid() or user_id is null);

create policy "ai_writing_select" on ai_writing_attempts for select using (user_id = auth.uid());
create policy "ai_writing_insert" on ai_writing_attempts for insert with check (user_id = auth.uid() or user_id is null);
create policy "ai_writing_update" on ai_writing_attempts for update using (user_id = auth.uid() or user_id is null);

-- teacher feedback: learner sees own reviews; teacher sees all (role check)
create policy "teacher_reviews_learner_select" on teacher_reviews for select
  using (user_id = auth.uid());
create policy "teacher_reviews_learner_insert" on teacher_reviews for insert
  with check (user_id = auth.uid());

create policy "teacher_comments_select" on teacher_comments for select
  using (review_id in (select id from teacher_reviews where user_id = auth.uid()));
create policy "teacher_comments_insert" on teacher_comments for insert
  with check (
    review_id in (select id from teacher_reviews where user_id = auth.uid())
    or exists (select 1 from profiles where id = auth.uid() and role = 'teacher')
  );


-- ══════════════════════════════════════════════════════════════════════════════
-- SEED DATA — 1 exam + minimal course structure to test the app
-- ══════════════════════════════════════════════════════════════════════════════

-- Exam
insert into exams (id, title, duration_minutes) values
  ('00000000-0000-0000-0000-000000000001', 'Bài thi thử Trvalý pobyt', 90)
on conflict do nothing;

-- Sections
insert into exam_sections (exam_id, skill, label, question_count, order_index) values
  ('00000000-0000-0000-0000-000000000001', 'reading',   'Đọc hiểu',    10, 1),
  ('00000000-0000-0000-0000-000000000001', 'listening', 'Nghe hiểu',   10, 2),
  ('00000000-0000-0000-0000-000000000001', 'writing',   'Viết',         5, 3),
  ('00000000-0000-0000-0000-000000000001', 'speaking',  'Nói',          5, 4)
on conflict do nothing;

-- Course
insert into courses (id, slug, title, description, skill, order_index) values
  ('00000000-0000-0000-0000-000000000010', 'czech-reading-b1',  'Đọc hiểu B1',  'Luyện đọc hiểu tiếng Séc trình độ B1', 'reading',   1),
  ('00000000-0000-0000-0000-000000000011', 'czech-listening-b1','Nghe hiểu B1', 'Luyện nghe tiếng Séc trình độ B1',     'listening', 2),
  ('00000000-0000-0000-0000-000000000012', 'czech-writing-b1',  'Viết B1',      'Luyện viết tiếng Séc trình độ B1',     'writing',   3),
  ('00000000-0000-0000-0000-000000000013', 'czech-speaking-b1', 'Nói B1',       'Luyện nói tiếng Séc trình độ B1',      'speaking',  4)
on conflict do nothing;

-- Module (1 per course for demo)
insert into modules (id, course_id, title, order_index) values
  ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000010', 'Module 1 — Văn bản hành chính', 1),
  ('00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0000-000000000011', 'Module 1 — Hội thoại đời thường', 1),
  ('00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0000-000000000012', 'Module 1 — Viết thư chính thức', 1),
  ('00000000-0000-0000-0004-000000000001', '00000000-0000-0000-0000-000000000013', 'Module 1 — Giới thiệu bản thân', 1)
on conflict do nothing;

-- Lesson (1 per module for demo)
insert into lessons (id, module_id, title, order_index) values
  ('00000000-0000-0000-0011-000000000001', '00000000-0000-0000-0001-000000000001', 'Bài 1 — Đọc biển hiệu và thông báo', 1),
  ('00000000-0000-0000-0022-000000000001', '00000000-0000-0000-0002-000000000001', 'Bài 1 — Nghe chỉ đường', 1),
  ('00000000-0000-0000-0033-000000000001', '00000000-0000-0000-0003-000000000001', 'Bài 1 — Viết email xin việc', 1),
  ('00000000-0000-0000-0044-000000000001', '00000000-0000-0000-0004-000000000001', 'Bài 1 — Giới thiệu về bản thân', 1)
on conflict do nothing;
