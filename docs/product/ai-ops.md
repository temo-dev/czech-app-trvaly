# AI Ops Runbook

Runbook vận hành cho các flow AI trong Trvalý Prep: speaking, writing, objective review, question feedback, và exam analysis.

---

## Scope

Các Edge Functions liên quan:
- `speaking-upload`
- `speaking-result`
- `writing-submit`
- `writing-result`
- `question-feedback`
- `ai-review-submit`
- `ai-review-result`
- `grade-exam`
- `analyze-exam`

Runbook này tập trung vào:
- model mapping và env vars
- rollout/checklist trước khi deploy
- cách đọc log `vietnamese_guard`
- debug các sự cố thường gặp

---

## Current Defaults

Model selection được override bằng env ở Edge Function layer. Default hiện tại:

| Env var | Default | Dùng cho |
|---|---|---|
| `OPENAI_SPEAKING_TRANSCRIBE_MODEL` | `gpt-4o-transcribe` | transcript bài nói |
| `OPENAI_SPEAKING_AUDIO_MODEL` | `gpt-audio-mini` | chấm speaking audio-native |
| `OPENAI_SPEAKING_SCORING_MODEL` | `gpt-5-mini` | fallback transcript-only cho speaking |
| `OPENAI_WRITING_SCORING_MODEL` | `gpt-5-mini` | chấm writing |
| `OPENAI_QUESTION_FEEDBACK_MODEL` | `gpt-5-mini` | feedback objective/cache miss |
| `OPENAI_OBJECTIVE_REVIEW_MODEL` | `gpt-5-mini` | AI Teacher objective review |
| `OPENAI_EXAM_SYNTHESIS_MODEL` | `gpt-5.1` | tổng hợp `exam_analysis` |
| `OPENAI_VIETNAMESE_GUARD_MODEL` | `gpt-5-mini` | normalize feedback sang tiếng Việt |
| `OPENAI_DEFAULT_CHAT_MODEL` | `gpt-4.1-mini` | fallback cho helper chung |

Nguyên tắc:
- speaking/writing là interactive flow, ưu tiên tốc độ + chất lượng ổn định
- speaking ưu tiên audio-native scoring khi format upload hỗ trợ (`wav`/`mp3`); transcript chỉ là review artifact và fallback signal
- `exam_analysis` là batch/background flow, ưu tiên chất lượng synthesis hơn latency
- `OPENAI_DEFAULT_CHAT_MODEL` chỉ là fallback, không nên là nơi quyết định model thật cho flow nghiệp vụ

---

## Language Contract

User-facing AI feedback phải bằng tiếng Việt:
- summary
- feedback
- tip
- suggestion
- explanation
- recommendation
- message

Được phép giữ tiếng Séc ở:
- `transcript`
- `corrected_answer`
- `corrected_essay`
- `corrected_version`
- `annotated_spans.text`
- `correction`
- ví dụ/cụm từ được trích dẫn

Nếu model vẫn trả lẫn tiếng Anh, hệ thống chạy thêm Vietnamese guard trước khi lưu/trả payload.

---

## Vietnamese Guard

Guard được gọi ở các luồng:
- `speaking.scoring_payload`
- `writing.scoring_payload`
- `question_feedback.cache`
- `question_feedback.result`
- `objective_review.teacher_review_payload`
- `speaking.teacher_review_subjective`
- `writing.teacher_review_subjective`
- `speaking.teacher_review_hydration`
- `writing.teacher_review_hydration`
- `exam_analysis.speaking_review_payload`
- `exam_analysis.writing_review_payload`
- `exam_analysis.synthesis_payload`

Guard chỉ rewrite field user-facing. Nó cố ý giữ nguyên:
- transcript
- corrected answer/essay/version
- text spans gốc
- token/suggestion cho transcript issue

---

## Monitoring

Tất cả log guard dùng event:

```json
{
  "event": "vietnamese_guard"
}
```

Các field quan trọng:
- `status`: `triggered` | `rewritten` | `partial` | `fallback`
- `context`
- `context_group`
- `context_slug`
- `model`
- `suspicious_count`
- `remaining_count`
- `changed`

Ý nghĩa nhanh:
- `triggered`: guard phát hiện field nghi ngờ tiếng Anh và bắt đầu xử lý
- `rewritten`: rewrite xong, không còn field nghi ngờ
- `partial`: rewrite xong nhưng vẫn còn field nghi ngờ
- `fallback`: guard lỗi hoặc timeout, payload gốc được giữ nguyên

Query/log filtering nên dùng:
- mọi event guard: `event="vietnamese_guard"`
- lỗi guard: `status="fallback"`
- rewrite chưa sạch: `status="partial"`
- theo nhóm luồng: `context_group`
- theo caller cụ thể: `context_slug`

Điều tra ưu tiên khi:
- `fallback` tăng đột biến
- `partial` lặp lại trên cùng một `context_slug`
- `remaining_count > 0`
- `changed=false` nhưng `status="rewritten"`

Lưu ý:
- guard logs không chứa transcript hay feedback text
- chỉ log metadata, path nghi ngờ, model, và trạng thái xử lý

---

## Rollout Checklist

Trước khi đổi model/env:
- xác nhận flow nào sẽ bị ảnh hưởng
- kiểm tra model mới có hỗ trợ đúng endpoint đang dùng
- ưu tiên đổi qua env trước, tránh hardcode mới
- kiểm tra speaking/writing vẫn giữ contract `{ attempt_id }` + polling
- kiểm tra AI Teacher review vẫn ra `pending/ready/error` đúng như cũ

Trước khi deploy Edge Functions:
- mọi function phải vẫn dùng `verify_jwt = false`
- deploy bằng `--no-verify-jwt`
- chạy `deno check` cho tất cả file function đã sửa
- kiểm tra `git diff --check`

Sau khi deploy:
- submit 1 bài speaking
- submit 1 bài writing
- mở 1 AI Teacher review objective
- mở 1 AI Teacher review subjective
- nộp 1 mock test có speaking/writing để xác nhận `grade-exam` + `analyze-exam`
- xem logs `vietnamese_guard` để chắc guard không fallback bất thường

---

## Incident Playbook

### 1. AI feedback lẫn tiếng Anh

Kiểm tra:
- logs `event="vietnamese_guard"`
- có `status="fallback"` hoặc `status="partial"` không
- `context_group` nào bị ảnh hưởng

Nếu guard không trigger:
- xem lại prompt/path caller có đang đi qua `ensureVietnameseUserFacingJson()` không

Nếu guard trigger nhưng `partial`:
- kiểm tra `suspicious_paths`
- cân nhắc nâng `OPENAI_VIETNAMESE_GUARD_MODEL`

Nếu guard `fallback`:
- kiểm tra timeout/OpenAI error trong log
- retry với model guard ổn định hơn

### 2. Speaking stuck ở pending quá lâu

Kiểm tra:
- `ai_speaking_attempts.status`
- `speaking-upload` log background processing
- `ai_teacher_reviews.status` nếu đang ở màn review
- `exam_results.ai_grading_pending` nếu là mock test

Nguyên nhân thường gặp:
- transcription/scoring timeout
- background task fail
- AI Teacher đang đợi attempt row chuyển sang `ready`

### 3. Writing stuck ở pending quá lâu

Kiểm tra:
- `ai_writing_attempts.status`
- `writing-submit background error`
- `ai-review-result` pending message

Nguyên nhân thường gặp:
- scoring timeout
- prompt/model fail parse JSON
- review layer đang chờ `ai_writing_attempts.ready`

### 4. Exam result có banner chờ AI mãi

Kiểm tra:
- `exam_results.ai_grading_pending`
- các row `ai_speaking_attempts` / `ai_writing_attempts` theo `exam_attempt_id`
- `exam_analysis.status`

Nếu `exam_analysis` chậm:
- xem `analyze-exam` log
- kiểm tra objective feedback cache miss có bất thường không
- kiểm tra synthesis model response

### 5. Objective feedback bị lỗi hoặc không preload

Kiểm tra:
- `question-feedback` cache hit/miss
- `question_ai_feedback`
- `analyze-exam` log `objective feedback skipped`

---

## Safe Changes

Ưu tiên an toàn:
- đổi model bằng env trước
- giữ nguyên API shape client-facing
- không đổi polling contract nếu chưa sửa client
- không log nội dung learner vào ops logs

Không nên làm:
- đổi model mặc định chung rồi hy vọng mọi flow đúng
- bypass Vietnamese guard cho payload user-facing
- thêm field response mới ở Edge Function mà không kiểm tra client parse

---

## Verification Commands

```bash
rtk deno check supabase/functions/_shared/openai.ts
rtk deno check supabase/functions/_shared/vietnamese_guard.ts
rtk deno check supabase/functions/speaking-upload/index.ts
rtk deno check supabase/functions/writing-submit/index.ts
rtk deno check supabase/functions/ai-review-submit/index.ts
rtk deno check supabase/functions/ai-review-result/index.ts
rtk deno check supabase/functions/analyze-exam/index.ts
rtk git diff --check
```

Nếu sửa Flutter review screens:

```bash
HOME=/tmp rtk dart analyze lib/features/speaking_ai/screens/speaking_feedback_screen.dart
HOME=/tmp rtk dart analyze lib/features/writing_ai/screens/writing_feedback_screen.dart
```

---

## Related Docs

- [architecture.md](/Users/daniel.dev/Desktop/app-czech/docs/product/architecture.md)
- [state-map.md](/Users/daniel.dev/Desktop/app-czech/docs/product/state-map.md)
- [data-contract-map.md](/Users/daniel.dev/Desktop/app-czech/docs/product/data-contract-map.md)
- [ai-upgrade-ux-first.md](/Users/daniel.dev/Desktop/app-czech/docs/plans/ai-upgrade-ux-first.md)
