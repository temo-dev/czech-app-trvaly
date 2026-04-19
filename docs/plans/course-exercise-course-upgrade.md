# Plan: Sửa lỗi và nâng cấp Course/Exercise

## Mục tiêu

- Sửa lỗi module chưa học nhưng vẫn hiện `ĐANG HỌC`
- Cho phép học lại lesson đã hoàn thành bằng cách reset `user_progress` của lesson
- Ghi nhận hoàn thành đúng cho mọi lesson block, không chỉ speaking/writing
- Đồng bộ logic progress giữa course detail, module detail, lesson player, và dashboard

## Phạm vi triển khai

### 1. Chuẩn hoá progress model
- Mở rộng `lib/features/course/models/course_models.dart`
  - thêm `ModuleStatus { locked, notStarted, inProgress, completed }`
  - `ModuleSummary` thêm `status`
  - `LessonSummary` thêm `completedBlockCount`, `totalBlockCount`, `canReplay`
  - `LessonDetail` thêm `isCompleted`
- Dùng chung helper rule:
  - lesson `available` khi `completedBlocks == 0`
  - lesson `inProgress` khi `0 < completedBlocks < totalBlocks`
  - lesson `completed` khi `completedBlocks >= totalBlocks`
  - module `notStarted` khi mọi lesson chưa có progress
  - module `inProgress` khi có progress dở dang thật
  - module `completed` khi mọi lesson completed

### 2. Refactor provider course/module/lesson
- `courseDetailProvider`
  - fetch `modules`, `lessons`, `lesson_blocks`, `user_progress`
  - tính `completedCount` theo lesson complete thật
  - set `ModuleStatus` từ lesson statuses
- `moduleDetailProvider`
  - trả về `completedBlockCount`, `totalBlockCount`, `canReplay`
- `lessonDetailProvider`
  - trả thêm `isCompleted`
- Thêm helper:
  - `resetLessonProgress(lessonId)`
  - `refreshCourseProgressProviders(courseId, moduleId, lessonId)`

### 3. Sửa flow hoàn thành block
- `LessonPlayerScreen` truyền `lessonId`, `lessonBlockId`, `courseId`, `moduleId` cho:
  - vocab
  - grammar
  - reading
  - listening
  - speaking
  - writing
- `PracticeScreen`
  - insert `exercise_attempts`
  - upsert `user_progress`
  - update streak
  - invalidate lesson/module/course/dashboard providers
- speaking/writing feedback screens cũng refresh cùng chuỗi provider
- `user_progress` RLS phải có thêm `UPDATE` policy vì `upsert` sẽ đi qua nhánh `UPDATE` khi conflict `(user_id, lesson_block_id)` xảy ra

### 4. Học lại lesson
- `ModuleDetailScreen`: lesson completed hiển thị badge `HỌC LẠI`
- `LessonPlayerScreen`: lesson completed hiển thị CTA chính `Học lại bài này`
- Khi xác nhận replay:
  - xoá `user_progress` theo `user_id + lesson_id`
  - không xoá `exercise_attempts`
  - không rollback XP, streak, bonus unlock, AI attempt history
  - refresh toàn bộ provider liên quan

### 5. Đồng bộ UI
- `CourseDetailScreen`
  - badge/CTA dựa trên `ModuleStatus`
  - module untouched không hiện `ĐANG HỌC`
  - course có thể có nhiều module `ĐANG HỌC` nếu đều có progress thật
- `ModuleDetailScreen`
  - hiển thị tiến độ block của từng lesson
- `LessonPlayerScreen`
  - block completed/pending phản ánh `user_progress`

## Test và xác minh

- Unit test cho:
  - `lessonStatusFromCounts`
  - `moduleStatusFromLessons`
  - `LessonSummary.canReplay`
- Chạy `flutter analyze` và các test liên quan sau khi xử lý quyền lockfile Flutter SDK.

## Giả định đã chốt

- `ĐANG HỌC` bắt đầu sau khi hoàn thành block đầu tiên
- Có thể có nhiều module `ĐANG HỌC` trong cùng một course nếu mỗi module có progress thật
- Replay là reset theo lesson
- Replay vẫn cho cộng XP đầy đủ ở lần làm lại
