-- Add columns that were defined in profiles.sql but missing from initial_schema.sql
-- initial_schema.sql created profiles without these columns, and profiles.sql used
-- CREATE TABLE IF NOT EXISTS (no-op since table already existed).
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS daily_goal_minutes      INT  NOT NULL DEFAULT 15,
  ADD COLUMN IF NOT EXISTS subscription_tier       TEXT NOT NULL DEFAULT 'free',
  ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMPTZ;
