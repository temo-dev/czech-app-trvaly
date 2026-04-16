-- ============================================================
-- Course Schema v2 — Add missing columns + unlock_lesson_bonus RPC
-- ============================================================

-- ── Courses: instructor info + duration ───────────────────────
ALTER TABLE courses
  ADD COLUMN IF NOT EXISTS instructor_name text,
  ADD COLUMN IF NOT EXISTS instructor_bio  text,
  ADD COLUMN IF NOT EXISTS duration_days   int NOT NULL DEFAULT 30;

-- ── Modules: description ──────────────────────────────────────
ALTER TABLE modules
  ADD COLUMN IF NOT EXISTS description text;

-- ── Lessons: description, duration, bonus fields ──────────────
ALTER TABLE lessons
  ADD COLUMN IF NOT EXISTS description      text,
  ADD COLUMN IF NOT EXISTS duration_minutes int  NOT NULL DEFAULT 15,
  ADD COLUMN IF NOT EXISTS bonus_unlocked   bool NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS bonus_xp_cost    int  NOT NULL DEFAULT 500;

-- ── RPC: unlock bonus lesson (deduct XP + mark lesson) ────────
CREATE OR REPLACE FUNCTION unlock_lesson_bonus(p_lesson_id uuid, p_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_cost int;
  v_xp   int;
BEGIN
  SELECT bonus_xp_cost INTO v_cost FROM lessons WHERE id = p_lesson_id;
  SELECT total_xp      INTO v_xp   FROM profiles WHERE id = p_user_id;

  IF v_cost IS NULL THEN
    RAISE EXCEPTION 'lesson_not_found';
  END IF;
  IF v_xp < v_cost THEN
    RAISE EXCEPTION 'insufficient_xp';
  END IF;

  UPDATE lessons
    SET bonus_unlocked = true
    WHERE id = p_lesson_id;

  UPDATE profiles
    SET total_xp  = total_xp  - v_cost,
        weekly_xp = GREATEST(0, weekly_xp - v_cost)
    WHERE id = p_user_id;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION unlock_lesson_bonus(uuid, uuid) TO authenticated;
