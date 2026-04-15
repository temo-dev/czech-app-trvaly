-- ============================================================
-- Migration 001: profiles table + handle_new_user trigger
-- Run in Supabase SQL Editor (Dashboard → SQL Editor → New query)
-- ============================================================

create table if not exists public.profiles (
  id                      uuid references auth.users(id) on delete cascade primary key,
  email                   text not null,
  display_name            text,
  avatar_url              text,
  locale                  text not null default 'vi',
  exam_date               timestamptz,
  daily_goal_minutes      int  not null default 15,
  current_streak_days     int  not null default 0,
  last_activity_date      date,
  total_xp                int  not null default 0,
  weekly_xp               int  not null default 0,
  subscription_tier       text not null default 'free',
  subscription_expires_at timestamptz,
  notification_prefs      jsonb not null default '{"enabled": true, "reminder_hour": 20, "timezone": "Asia/Ho_Chi_Minh"}',
  created_at              timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Auto-create profile row when a new user signs up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data ->> 'display_name'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- XP increment helper (used by gamification_provider)
create or replace function public.increment_xp(uid uuid, points int)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  update public.profiles
  set
    total_xp  = total_xp  + points,
    weekly_xp = weekly_xp + points
  where id = uid;
end;
$$;
