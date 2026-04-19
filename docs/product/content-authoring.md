# Content Authoring Guide

Hướng dẫn tạo và thay thế nội dung học (đề thi + khoá học) trong app Trvalý Prep.

---

## Tổng quan kiến trúc nội dung

```
Exam (1)
└── ExamSection (4: reading · listening · writing · speaking)
    └── Question (n)
        └── QuestionOption (4 mỗi câu MCQ)

Course (1)
└── Module (n)
    └── Lesson (n)
        └── LessonBlock (6 mỗi bài: vocab · grammar · reading · listening · speaking · writing)
            └── LessonBlockExercise → Exercise (content_json)
```

Tất cả nội dung được seed qua **Supabase migration files** trong `supabase/migrations/`.

---

## Đề thi (Exam)

### Cấu trúc bảng

| Bảng | Vai trò |
|------|---------|
| `exams` | Metadata: tiêu đề, thời gian, `is_active` |
| `exam_sections` | 4 phần thi per exam (reading/listening/writing/speaking) |
| `questions` | Câu hỏi, liên kết với section |
| `question_options` | Các đáp án MCQ (4 option mỗi câu) |

### Quy tắc `is_active`

App load đề thi bằng `.eq('is_active', true)` — chỉ cần **một exam active** tại một thời điểm. Để thay đề mới: set exam cũ `is_active = false`, tạo exam mới `is_active = true`.

### UUID chiến lược

Migration hiện tại dùng UUID cố định để dễ debug:

```
Exam:     00000000-0000-0000-0000-000000000001
Reading:  aaaaaaaa-1111-0000-0000-000000000001
Listening:aaaaaaaa-1111-0000-0000-000000000002
Writing:  aaaaaaaa-1111-0000-0000-000000000003
Speaking: aaaaaaaa-1111-0000-0000-000000000004

Questions Reading:  00000001-0000-0000-0000-00000000000N
Questions Listening:00000002-0000-0000-0000-00000000000N
Questions Writing:  00000003-0000-0000-0000-00000000000N
Questions Speaking: 00000004-0000-0000-0000-00000000000N
```

### Schema câu hỏi

```sql
INSERT INTO questions (
  id,            -- UUID cố định (dễ tham chiếu)
  section_id,    -- UUID của exam_section
  type,          -- 'mcq' | 'writing' | 'speaking'
  skill,         -- 'reading' | 'listening' | 'writing' | 'speaking'
  prompt,        -- Nội dung câu hỏi (tiếng Czech + context)
  correct_answer,-- 'a'/'b'/'c'/'d' cho MCQ, null cho writing/speaking
  explanation,   -- Giải thích đáp án bằng tiếng Việt
  points,        -- 1 (MCQ) hoặc 2 (writing/speaking)
  order_index    -- Thứ tự hiển thị (1–10 cho reading/listening, 1–5 cho writing/speaking)
)
```

### Schema đáp án MCQ

```sql
INSERT INTO question_options (
  question_id,  -- FK → questions.id
  text,         -- Nội dung đáp án
  is_correct,   -- true cho đáp án đúng (chỉ 1 per question)
  order_index   -- 1/2/3/4
)
```

> **Lưu ý:** `correct_answer` trong `questions` ('a'/'b'/'c'/'d') phải khớp với `order_index` của option có `is_correct = true`. App dùng cả hai để grade.

### Cấu trúc prompt câu hỏi

**Reading/Listening MCQ** — Nhúng văn bản đọc/nghe trực tiếp vào `prompt`:
```
Đọc biển tại cửa hàng:

ALBERT SUPERMARKET
Otevírací doba: ...

Bạn muốn đi mua sắm vào Chủ nhật lúc 19:00. Cửa hàng có còn mở không?
```

**Listening** — Dùng prefix `[Poslech]` và viết lời thoại dạng script:
```
[Poslech] Nghe đoạn hội thoại qua điện thoại:

Lễ tân: "..."
Bệnh nhân: "..."

Câu hỏi?
```

**Writing** — Prompt có cấu trúc rõ ràng: thể loại văn bản, số từ, các điểm cần bao gồm.

**Speaking** — Prompt có tình huống + bullet points các điểm cần nói + thời lượng.

---

## Khoá học (Course)

### Cấu trúc bảng

| Bảng | Vai trò |
|------|---------|
| `courses` | Metadata khoá học |
| `modules` | Nhóm bài học theo chủ đề |
| `lessons` | Bài học cụ thể |
| `lesson_blocks` | 6 block per bài (vocab/grammar/reading/listening/speaking/writing) |
| `lesson_block_exercises` | Junction table: block → exercise (1-to-many) |
| `exercises` | Nội dung bài tập (lưu dạng JSON trong `content_json`) |

> **Quan trọng:** `lesson_blocks` **không còn** cột `exercise_id`. Link được tạo qua bảng trung gian `lesson_block_exercises`.

### Schema khoá học

```sql
INSERT INTO courses (
  id, slug,          -- UUID + slug URL-friendly
  title,             -- Tên khoá học (tiếng Việt)
  description,       -- Mô tả ngắn
  skill,             -- Kỹ năng chính: 'speaking'|'reading'|'grammar'|...
  is_premium,        -- false (miễn phí) | true (trả phí)
  order_index,       -- Thứ tự hiển thị trong danh sách
  instructor_name,   -- Tên giảng viên
  instructor_bio,    -- Tiểu sử ngắn
  duration_days      -- Số ngày học ước tính
)
```

### Schema lesson

```sql
INSERT INTO lessons (
  id, module_id,
  title,             -- Tiêu đề bài học
  description,       -- Mô tả nội dung bài
  duration_minutes,  -- Thời lượng ước tính (thường 20–30 phút)
  order_index,       -- Thứ tự trong module (1, 2, ...)
  bonus_xp_cost      -- XP cần để mở bonus content (300–500)
)
```

### 6 block types per lesson

Mỗi bài học có đúng 6 block theo thứ tự cố định:

| order_index | type | skill | Nội dung điển hình |
|-------------|------|-------|-------------------|
| 1 | `vocab` | `vocabulary` | MCQ từ vựng mới |
| 2 | `grammar` | `grammar` | Fill-in-the-blank ngữ pháp |
| 3 | `reading` | `reading` | MCQ đọc hiểu đoạn văn ngắn |
| 4 | `listening` | `listening` | MCQ nghe hội thoại mô phỏng |
| 5 | `speaking` | `speaking` | Prompt nói tự do (AI-graded) |
| 6 | `writing` | `writing` | Prompt viết (AI-graded) |

### Schema exercise (content_json)

Tất cả nội dung bài tập lưu trong cột `content_json` dạng JSONB.

**MCQ (vocab / reading / listening):**
```json
{
  "prompt": "Câu hỏi (có thể chứa văn bản đọc/nghe dạng ASCII art hoặc script)",
  "explanation": "Giải thích đáp án đúng bằng tiếng Việt, kèm từ vựng liên quan",
  "options": [
    {"id": "a", "text": "Đáp án A", "is_correct": false},
    {"id": "b", "text": "Đáp án B", "is_correct": true},
    {"id": "c", "text": "Đáp án C", "is_correct": false},
    {"id": "d", "text": "Đáp án D", "is_correct": false}
  ]
}
```

**Fill-in-the-blank (grammar):**
```json
{
  "prompt": "Câu với chỗ trống ______\n(Dịch nghĩa)\n\nGợi ý: từ1 / từ2 / từ3",
  "correct_answer": "từ đúng",
  "explanation": "Giải thích tại sao đúng + ngữ pháp liên quan"
}
```

**Speaking:**
```json
{
  "prompt": "Tình huống + yêu cầu cụ thể\n• Bullet point 1\n• Bullet point 2\n\nNói ít nhất X câu.",
  "explanation": "Câu mẫu (model answer) + từ vựng quan trọng"
}
```

**Writing:**
```json
{
  "prompt": "Thể loại văn bản (X–Y từ)\n\nTình huống/yêu cầu:\n• Điểm 1\n• Điểm 2",
  "explanation": "Văn bản mẫu hoàn chỉnh + từ vựng quan trọng"
}
```

### Tạo block trong DO $$ block

```sql
DO $$
DECLARE
  v_les1_id uuid := gen_random_uuid();
  v_l1e1 uuid := gen_random_uuid();  -- exercise ID
  v_l1b1 uuid := gen_random_uuid();  -- block ID (cần lưu để link với exercise)
BEGIN
  -- 1. Tạo lesson
  INSERT INTO lessons (...) VALUES (v_les1_id, ...);

  -- 2. Tạo exercise
  INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
  VALUES (v_l1e1, 'mcq', 'vocabulary', 'beginner', 10, 10, '{ ... }');

  -- 3. Tạo block (KHÔNG có exercise_id)
  INSERT INTO lesson_blocks (id, lesson_id, type, order_index)
  VALUES (v_l1b1, v_les1_id, 'vocab', 1);

  -- 4. Link block → exercise
  INSERT INTO lesson_block_exercises (block_id, exercise_id, order_index)
  VALUES (v_l1b1, v_l1e1, 1);
END $$;
```

---

## Workflow thay đổi nội dung

### Thay toàn bộ đề thi + khoá học

1. Tạo file migration mới: `supabase/migrations/YYYYMMDDNNNNNN_new_content.sql`
2. Bắt đầu file với phần xoá dữ liệu cũ (theo thứ tự FK):

```sql
DELETE FROM public.ai_teacher_reviews;
DELETE FROM public.exam_results;
DELETE FROM public.exam_attempts;
DELETE FROM public.question_options;
DELETE FROM public.questions;
DELETE FROM public.exam_sections;
DELETE FROM public.exams;

DELETE FROM public.exercise_attempts;
DELETE FROM public.user_progress;
DELETE FROM public.lesson_block_exercises;
DELETE FROM public.lesson_blocks;
DELETE FROM public.ai_speaking_attempts;
DELETE FROM public.ai_writing_attempts;
DELETE FROM public.exercises;
DELETE FROM public.lessons;
DELETE FROM public.modules;
DELETE FROM public.courses;
```

3. Thêm nội dung mới sau phần xoá
4. Apply migration:

```bash
supabase db push --linked
```

5. Nếu migration bị lỗi và cần retry:

```bash
supabase migration repair --status reverted <timestamp>
supabase db push --linked
```

### Chỉ thêm đề thi mới (không xoá cũ)

```sql
-- Set đề cũ inactive
UPDATE public.exams SET is_active = false;

-- Tạo đề mới với is_active = true
INSERT INTO public.exams (id, title, duration_minutes, is_active)
VALUES (gen_random_uuid(), 'Tên đề mới', 60, true);
```

### Chỉ thêm khoá học mới

Không cần xoá gì — chỉ cần INSERT course + modules + lessons + exercises + blocks vào cuối migration mới.

### Lưu ý về progress khi sửa lesson flow

- Client hiện tại ghi `user_progress` theo cách idempotent: check row hiện có theo
  `(user_id, lesson_block_id)`, chỉ `INSERT` khi block chưa được đánh dấu xong.
- Cách này tránh duplicate write khi AI feedback screen rebuild hoặc ready nhiều lần.
- `UPDATE` policy vẫn nên tồn tại ở môi trường thật để tương thích với client cũ
  hoặc flow cũ từng dùng `upsert`.
- Migration compatibility là: `20260419204926_user_progress_update_policy.sql`.
- Nếu môi trường remote thiếu migration trên, các client cũ vẫn có thể log lỗi
  `42501 new row violates row-level security policy` khi đi vào nhánh update của `upsert`.

---

## Nội dung hiện tại (tính đến 2026-04-21)

### Đề thi đang active

**"Trvalý Pobyt — Bài thi thử (A2)"** — Migration: `20260421000001_fresh_exam_and_course.sql`

| Section | Số câu | Chủ đề |
|---------|--------|--------|
| Reading | 10 MCQ | Giờ mở cửa, thông báo tòa nhà, thuê nhà, nhãn thuốc, phân loại rác, lịch tàu, bảo hiểm y tế, đăng ký học, số khẩn cấp, hóa đơn |
| Listening | 10 MCQ | Đặt lịch bác sĩ, dự báo thời tiết, thông báo siêu thị, thông báo ga tàu, ULO tự động, dược sĩ, xe buýt, công việc, hàng xóm, cháy tòa nhà |
| Writing | 5 | Email cơ quan, thư xin phép cho con, mô tả tuần làm việc, khiếu nại chủ nhà, lý do muốn ở lại Czech |
| Speaking | 5 | Giới thiệu gia đình, mô tả nơi ở, kinh nghiệm làm việc, truyền thống Czech, xử lý hồ sơ bị mất |

### Khoá học đang có

**"Tiếng Czech trong cuộc sống hàng ngày"** — slug: `tieng-czech-hang-ngay` — Migration: `20260421000001_fresh_exam_and_course.sql`

| Module | Lesson | Chủ đề |
|--------|--------|--------|
| Mua sắm & Dịch vụ | Tại siêu thị | Tìm sản phẩm, đọc nhãn, thanh toán |
| Mua sắm & Dịch vụ | Tại ngân hàng và bưu điện | Mở tài khoản, gửi bưu phẩm quốc tế |
| Sức khỏe & Khẩn cấp | Đặt lịch và gặp bác sĩ | Mô tả triệu chứng, đọc đơn thuốc |
| Sức khỏe & Khẩn cấp | Tình huống khẩn cấp | Gọi 155, báo trộm, thoát hiểm |

---

## Nguyên tắc chất lượng nội dung

- **Thực tế:** Tất cả văn bản Czech phải phản ánh tình huống người dùng thực sự gặp khi sống tại Czech.
- **A2 level:** Từ vựng và ngữ pháp ở mức A2 (chuẩn thi Trvalý pobyt). Tránh B1+ trừ khi giải thích rõ.
- **Vietnamese-first:** Câu hỏi, lựa chọn và giải thích đều bằng tiếng Việt. Czech chỉ xuất hiện trong văn bản đọc/nghe và câu mẫu.
- **Explanation = học liệu:** `explanation` không chỉ nói "đáp án đúng là B" mà phải giải thích từ vựng, ngữ pháp, hoặc bối cảnh văn hoá liên quan.
- **Diversity:** Mỗi section nên bao gồm nhiều chủ đề khác nhau (úřad, y tế, giao thông, nhà ở, mua sắm, khẩn cấp).
