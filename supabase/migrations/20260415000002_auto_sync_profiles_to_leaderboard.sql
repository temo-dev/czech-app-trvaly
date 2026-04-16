-- Migration: auto-sync profiles → leaderboard_weekly
--
-- Vấn đề: leaderboard_weekly không có cơ chế tự động cập nhật.
-- refresh_leaderboard_weekly() phải gọi thủ công và bỏ qua user có weekly_xp = 0.
-- Kết quả: user mới đăng ký không bao giờ xuất hiện trên bảng xếp hạng.
--
-- Fix: trigger tự upsert vào leaderboard_weekly mỗi khi profile được tạo
-- hoặc khi weekly_xp / display_name / avatar_url thay đổi.

-- 1. Function trigger
create or replace function sync_profile_to_leaderboard()
returns trigger language plpgsql security definer as $$
declare
  v_week_start date := date_trunc('week', now())::date;
begin
  insert into leaderboard_weekly (user_id, display_name, avatar_url, weekly_xp, week_start)
  values (
    new.id,
    coalesce(new.display_name, split_part(new.email, '@', 1)),
    new.avatar_url,
    new.weekly_xp,
    v_week_start
  )
  on conflict (user_id, week_start) do update
    set weekly_xp    = excluded.weekly_xp,
        display_name = excluded.display_name,
        avatar_url   = excluded.avatar_url;
  return new;
end;
$$;

-- 2. Trigger: chạy sau khi INSERT (signup) hoặc UPDATE các cột liên quan
drop trigger if exists trg_sync_profile_to_leaderboard on profiles;
create trigger trg_sync_profile_to_leaderboard
  after insert or update of weekly_xp, display_name, avatar_url
  on profiles
  for each row execute procedure sync_profile_to_leaderboard();

-- 3. Backfill: thêm ngay tất cả profile hiện tại vào leaderboard tuần này
insert into leaderboard_weekly (user_id, display_name, avatar_url, weekly_xp, week_start)
select
  id,
  coalesce(display_name, split_part(email, '@', 1)),
  avatar_url,
  weekly_xp,
  date_trunc('week', now())::date
from profiles
on conflict (user_id, week_start) do update
  set weekly_xp    = excluded.weekly_xp,
      display_name = excluded.display_name,
      avatar_url   = excluded.avatar_url;
