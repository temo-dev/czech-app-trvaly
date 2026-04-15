-- =============================================================================
-- Trvalý Prep — seed_user.sql
-- User-dependent mock data — chạy SAU KHI đã tạo test account
--
-- BƯỚC 1: Tạo test user (1 trong 2 cách):
--   A) Supabase Dashboard → Authentication → Users → Add user
--      Email: test@trvaly.app  |  Password: Test1234!
--   B) Chạy app → màn hình đăng ký → dùng email test@trvaly.app
--
-- BƯỚC 2: Lấy UUID của user vừa tạo:
--   Dashboard → Authentication → Users → copy UUID
--   HOẶC chạy SQL: SELECT id FROM auth.users WHERE email = 'test@trvaly.app';
--
-- BƯỚC 3: Thay TẤT CẢ 'TEST_USER_UUID' bên dưới bằng UUID thật, rồi Run
-- =============================================================================

-- Kiểm tra nhanh (uncomment để xem UUID):
-- SELECT id, email FROM auth.users WHERE email = 'test@trvaly.app';
-- SELECT id, email, display_name FROM profiles ORDER BY created_at DESC LIMIT 5;


-- ═════════════════════════════════════════════════════════════════════════════
-- PHẦN E — CẬP NHẬT PROFILE
-- (trigger on_auth_user_created đã tạo row — ta chỉ UPDATE thêm thông tin)
-- ═════════════════════════════════════════════════════════════════════════════

UPDATE profiles SET
  display_name        = 'Nguyễn Minh Tú',
  total_xp            = 1240,
  weekly_xp           = 340,
  current_streak_days = 7,
  last_activity_date  = CURRENT_DATE,
  exam_date           = CURRENT_DATE + INTERVAL '45 days'
WHERE id = 'TEST_USER_UUID';


-- ═════════════════════════════════════════════════════════════════════════════
-- PHẦN F — EXAM ATTEMPT + RESULT (cho dashboard card "Kết quả gần nhất")
-- UUIDs: chỉ dùng ký tự hex [0-9a-f]
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO exam_attempts (
  id, exam_id, user_id, status, answers,
  remaining_seconds, started_at, submitted_at
) VALUES (
  'a110e001-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  'TEST_USER_UUID',
  'submitted',
  '{}',
  0,
  NOW() - INTERVAL '2 days',
  NOW() - INTERVAL '2 days' + INTERVAL '75 minutes'
) ON CONFLICT DO NOTHING;

INSERT INTO exam_results (
  id, attempt_id, user_id,
  total_score, pass_threshold,
  section_scores, weak_skills
) VALUES (
  'e5001001-0000-0000-0000-000000000001',
  'a110e001-0000-0000-0000-000000000001',
  'TEST_USER_UUID',
  72,
  60,
  '{"reading":{"score":8,"total":10},"listening":{"score":7,"total":10},"writing":{"score":3,"total":5},"speaking":{"score":3,"total":5}}',
  ARRAY['listening', 'speaking']
) ON CONFLICT DO NOTHING;


-- ═════════════════════════════════════════════════════════════════════════════
-- PHẦN G — USER PROGRESS (3/6 blocks của Reading lesson đã hoàn thành)
-- → Lesson 1 hiện status=inProgress trên UI
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO user_progress (id, user_id, lesson_id, lesson_block_id, completed_at) VALUES
(
  'c0de0001-0000-0000-0000-000000000001',
  'TEST_USER_UUID',
  '00000000-0000-0000-0011-000000000001',
  'b1000001-0000-0000-0000-000000000001',
  NOW() - INTERVAL '1 day'
),
(
  'c0de0001-0000-0000-0000-000000000002',
  'TEST_USER_UUID',
  '00000000-0000-0000-0011-000000000001',
  'b1000001-0000-0000-0000-000000000002',
  NOW() - INTERVAL '1 day' + INTERVAL '5 minutes'
),
(
  'c0de0001-0000-0000-0000-000000000003',
  'TEST_USER_UUID',
  '00000000-0000-0000-0011-000000000001',
  'b1000001-0000-0000-0000-000000000003',
  NOW() - INTERVAL '1 day' + INTERVAL '12 minutes'
)
ON CONFLICT DO NOTHING;


-- ═════════════════════════════════════════════════════════════════════════════
-- PHẦN H — EXERCISE ATTEMPTS (lịch sử luyện tập)
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO exercise_attempts (
  id, exercise_id, user_id, lesson_block_id,
  answer, is_correct, xp_awarded, attempted_at
) VALUES
(
  'ea000001-0000-0000-0000-000000000001',
  'e1000001-0000-0000-0000-000000000001',
  'TEST_USER_UUID',
  'b1000001-0000-0000-0000-000000000001',
  '{"written_answer": "obchodu"}',
  true, 10,
  NOW() - INTERVAL '1 day'
),
(
  'ea000001-0000-0000-0000-000000000002',
  'e1000001-0000-0000-0000-000000000002',
  'TEST_USER_UUID',
  'b1000001-0000-0000-0000-000000000002',
  '{"selected_option_id": "a"}',
  true, 10,
  NOW() - INTERVAL '1 day' + INTERVAL '5 minutes'
),
(
  'ea000001-0000-0000-0000-000000000003',
  'e1000001-0000-0000-0000-000000000003',
  'TEST_USER_UUID',
  'b1000001-0000-0000-0000-000000000003',
  '{"selected_option_id": "b"}',
  true, 10,
  NOW() - INTERVAL '1 day' + INTERVAL '12 minutes'
)
ON CONFLICT DO NOTHING;


-- ═════════════════════════════════════════════════════════════════════════════
-- PHẦN I — TEACHER REVIEWS + COMMENTS (gắn vào test user)
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO teacher_reviews (id, user_id, skill, status, preview_text, unread_count, created_at)
VALUES
(
  'fee00001-0000-0000-0000-000000000001',
  'TEST_USER_UUID',
  'writing',
  'reviewed',
  'Email của bạn có cấu trúc tốt. Cần chú ý thêm về cách dùng cách 7 (instrumentál) sau động từ pomoc.',
  2,
  NOW() - INTERVAL '2 days'
),
(
  'fee00001-0000-0000-0000-000000000002',
  'TEST_USER_UUID',
  'speaking',
  'pending',
  'Đang chờ giáo viên xem xét bài nói của bạn...',
  0,
  NOW() - INTERVAL '1 day'
)
ON CONFLICT DO NOTHING;

INSERT INTO teacher_comments (id, review_id, body, is_teacher, author_name, created_at)
VALUES
(
  'c011e001-0000-0000-0000-000000000001',
  'fee00001-0000-0000-0000-000000000001',
  'Xin chào! Tôi đã xem bài viết email của bạn. Nhìn chung rất tốt!',
  true,
  'Mgr. Jana Horáková',
  NOW() - INTERVAL '2 days' + INTERVAL '1 hour'
),
(
  'c011e001-0000-0000-0000-000000000002',
  'fee00001-0000-0000-0000-000000000001',
  'Cấu trúc email rất tốt. Tuy nhiên, cần chú ý: pomoc vyžaduje předložku S + instrumentál. Ví dụ: za pomoc S nákupem (không phải "za pomoc nákupem"). Ngoài ra, thay vì hezké, hãy dùng milé hoặc laskavé cho hành động/cử chỉ.',
  true,
  'Mgr. Jana Horáková',
  NOW() - INTERVAL '2 days' + INTERVAL '2 hours'
),
(
  'c011e001-0000-0000-0000-000000000003',
  'fee00001-0000-0000-0000-000000000001',
  'Cảm ơn cô đã nhận xét! Tôi sẽ luyện thêm về instrumentál và cách dùng tính từ hezký vs milý.',
  false,
  NULL,
  NOW() - INTERVAL '1 day'
)
ON CONFLICT DO NOTHING;


-- ═════════════════════════════════════════════════════════════════════════════
-- PHẦN J — GẮN AI FEEDBACK STUBS VÀO TEST USER
-- (các rows đã được tạo trong seed.sql với user_id=NULL)
-- ═════════════════════════════════════════════════════════════════════════════

UPDATE ai_speaking_attempts
SET user_id = 'TEST_USER_UUID'
WHERE id = 'a15ea001-0000-0000-0000-000000000001'
  AND user_id IS NULL;

UPDATE ai_writing_attempts
SET user_id = 'TEST_USER_UUID'
WHERE id = 'a17e1001-0000-0000-0000-000000000001'
  AND user_id IS NULL;


-- ═════════════════════════════════════════════════════════════════════════════
-- PHẦN K — LEADERBOARD ENTRY CHO TEST USER (rank ~3, XP=340)
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO leaderboard_weekly (user_id, display_name, weekly_xp, week_start)
VALUES (
  'TEST_USER_UUID',
  'Nguyễn Minh Tú',
  340,
  DATE_TRUNC('week', NOW())::date
)
ON CONFLICT DO NOTHING;


-- =============================================================================
-- XONG! Kiểm tra kết quả:
-- =============================================================================
-- SELECT display_name, total_xp, weekly_xp, current_streak_days FROM profiles WHERE id = 'TEST_USER_UUID';
-- SELECT total_score, section_scores, weak_skills FROM exam_results WHERE user_id = 'TEST_USER_UUID';
-- SELECT COUNT(*) FROM user_progress WHERE user_id = 'TEST_USER_UUID';
-- SELECT skill, status, preview_text FROM teacher_reviews WHERE user_id = 'TEST_USER_UUID';
-- SELECT status, overall_score, metrics FROM ai_speaking_attempts WHERE user_id = 'TEST_USER_UUID';
-- SELECT status, overall_score, metrics FROM ai_writing_attempts WHERE user_id = 'TEST_USER_UUID';
-- SELECT display_name, weekly_xp FROM leaderboard_weekly ORDER BY weekly_xp DESC LIMIT 5;
