# Nâng cấp AI stack cho speaking/writing theo hướng UX-first

## Summary

- Nâng cấp toàn bộ lớp AI dùng chung, nhưng ưu tiên speaking exam và speaking lesson trước vì đây là điểm nghẽn UX rõ nhất.
- Đổi từ mô hình “submit chờ AI xử lý xong mới trả về” sang “submit trả `attempt_id` ngay, AI xử lý bất đồng bộ, UI poll trạng thái thật”.
- Tách model theo loại tác vụ thay vì dùng chung một helper/model cho tất cả.
- Mục tiêu cuối: transcript chính xác hơn, feedback tốt hơn, thời gian chờ cảm nhận ngắn hơn, và output JSON ổn định hơn.

## Key Changes

- Tách `supabase/functions/_shared/openai.ts` thành helper theo tác vụ, không dùng một `chatComplete()` cứng model cho mọi flow nữa.
  - `transcribeSpeech()` dùng `gpt-4o-transcribe` cho speaking audio.
  - `scoreInteractive()` dùng `gpt-5-mini` cho speaking scoring, writing scoring, question feedback, và AI Teacher review vì đây là các flow user-facing cần chất lượng cao nhưng vẫn giữ latency hợp lý.
  - `synthesizeExamAnalysis()` dùng `gpt-5.1` cho `analyze-exam` vì đây là batch/background flow, ưu tiên chất lượng insight hơn tốc độ.
- Chuẩn hóa output sang schema-validated JSON ở helper layer thay cho parse JSON lỏng hiện tại.
  - Mỗi flow có schema riêng: speaking score payload, writing score payload, teacher review payload, exam synthesis payload.
  - Nếu model trả thiếu field hoặc field sai kiểu, helper đánh dấu lỗi có cấu trúc và ghi row `error` thay vì parse nửa đúng nửa sai.
- Đưa speaking/writing submit flow về async đúng nghĩa.
  - `speaking-upload` chỉ làm: validate access, normalize `question_id/exercise_id`, tạo `ai_speaking_attempts(status='processing')`, lưu request context, trả `attempt_id` ngay.
  - `writing-submit` làm tương tự cho `ai_writing_attempts`.
  - Thêm worker functions chuyên xử lý AI, ví dụ `speaking-process` và `writing-process`, đọc row `processing`, gọi OpenAI, cập nhật row sang `ready/error`.
  - `speaking-result` và `writing-result` giữ contract hiện có để client không phải đổi route-level API shape.
- Giữ UI contract hiện tại nhưng sửa UX để phản ánh async flow thật.
  - Speaking full-screen và embedded speaking trong exam đều chuyển sang trạng thái `processing` ngay sau submit thay vì chờ upload function xử lý xong.
  - Result/polling copy được cập nhật rõ hơn: “đã nhận bài”, “đang transcript”, “đang chấm”, “đang tạo nhận xét”.
  - Với exam, `ai_grading_pending` tiếp tục là nguồn hiển thị banner, nhưng speaking review card sẽ dựa trên trạng thái thật từ `ai_teacher_reviews`.
- Chuẩn hóa AI Teacher cho subjective flows.
  - `ai-review-submit` không gọi lại model cho speaking/writing nếu đã có payload đủ tốt từ attempt row; chỉ chuyển đổi attempt data thành review payload chuẩn.
  - Nếu attempt row còn `processing`, AI Teacher review row cũng ở `processing` và detail screen poll tiếp.
- Thêm feature flag + rollout từng bước.
  - Flag riêng cho `speech_transcription_v2`, `interactive_grading_v2`, `exam_synthesis_v2`.
  - Shadow evaluation cho speaking: chạy model mới song song trên một tập sample trước khi cut over.
  - Cut over theo thứ tự: speaking transcript -> speaking scoring/review -> writing -> exam synthesis.
- Cập nhật docs chuẩn trong `docs/product/architecture.md`, `docs/product/state-map.md`, `docs/product/data-contract-map.md` để phản ánh flow async thật, model mapping mới, và trạng thái AI mới.

## Public API / Interface Changes

- Giữ nguyên endpoint names hiện có cho client-facing submit/result APIs.
- Thay đổi hành vi của `speaking-upload` và `writing-submit`:
  - Trả `attempt_id` ngay sau khi tạo row `processing`, không chờ chấm xong.
- Bổ sung worker entrypoints nội bộ:
  - `speaking-process`
  - `writing-process`
- Mở rộng status semantics trong DB-facing handling:
  - `processing` là trạng thái thật trong suốt vòng đời AI, không còn chỉ tồn tại rất ngắn.
  - Error payload được chuẩn hóa để UI có thể hiển thị retry message phân loại hơn.
- Không đổi shape route Flutter hiện tại; thay đổi chủ yếu nằm ở provider state transitions và edge-function timing.

## Test Plan

- Speaking transcript:
  - Audio Czech rõ, audio Czech accent Việt, audio không phải tiếng Czech, audio rỗng, audio hỏng.
  - So sánh transcript, language detection, và pass/fail Czech enforcement giữa model cũ và mới.
- Speaking exam flow:
  - Record xong phải nhận `attempt_id` nhanh, autosave `ai_attempt_id` vào `exam_attempts.answers`, nộp exam khi speaking còn `processing` vẫn tạo `exam_results` với `ai_grading_pending=true`.
  - Khi worker hoàn tất, result/review screen phải cập nhật đúng score và AI Teacher review.
- Speaking lesson/practice flow:
  - Feedback screen phải vào trạng thái `processing` ngay, và chỉ mark lesson progress sau khi AI Teacher review `ready`.
- Writing flow:
  - Submit trả nhanh, retry an toàn, review payload hợp schema, UI xử lý đúng `processing/error/ready`.
- AI Teacher:
  - Objective và subjective review phải ra đúng schema, không còn lỗi parse JSON.
  - Speaking/writing review không được gọi model dư thừa khi attempt row đã có dữ liệu đủ để dựng review.
- Reliability:
  - Worker retry idempotent, double-submit không tạo duplicate review/attempt logic sai.
  - Timeout OpenAI, malformed response, và network error đều phải cập nhật row `error` nhất quán.
- Rollout validation:
  - Chạy benchmark offline trên tập sample nội bộ, đo transcript quality, score consistency, latency p50/p95, error rate, và cost per attempt trước khi bật flag production.

## Assumptions

- Phạm vi là toàn bộ AI flows dùng chung, nhưng speaking là rollout đầu tiên.
- Ưu tiên cao nhất là UX và chất lượng, chấp nhận tăng chi phí và độ trễ ở mức vừa phải.
- Model mặc định được chốt như sau:
  - `gpt-4o-transcribe` cho speech-to-text
  - `gpt-5-mini` cho interactive scoring/review
  - `gpt-5.1` cho exam-level synthesis
- Client routes hiện tại sẽ được giữ nguyên; phần lớn thay đổi nằm ở Edge Functions, helper OpenAI, provider states, và copy trạng thái.
- Nếu trong quá trình implementation có ràng buộc endpoint/schema của OpenAI mới, helper layer sẽ hấp thụ khác biệt đó, không đẩy thay đổi lên Flutter layer.
