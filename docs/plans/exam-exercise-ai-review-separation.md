# Exam And Exercise AI Review Separation

## Summary

- Save this plan before implementation so the exam/exercise split is documented in-repo.
- Keep `exercise` on the existing per-question AI Teacher flow using `ai_teacher_reviews`.
- Move `exam` review to a batch pipeline where `exam_analysis` is the only source of truth for objective and subjective feedback.
- Stop starting AI review from each speaking/writing question on the mock test result screen.
- Store full speaking/writing review payloads in `exam_analysis.teacher_reviews_by_question`.
- Use an exam-specific detail screen for subjective mock test review instead of reusing practice feedback screens.

## Implementation Order

1. Save this document under `docs/plans/`.
2. Add the `teacher_reviews_by_question` field to `exam_analysis`.
3. Extend `analyze-exam` to materialize full speaking/writing review payloads into `exam_analysis`.
4. Update Flutter exam analysis models/providers and mock test result UI to read only from `exam_analysis`.
5. Add exam-specific detail routes/screens.
6. Update product docs and run verification.

## Backend

### Source Of Truth

- Keep `ai-review-submit` and `ai-review-result` for `exercise`, `lesson`, and `practice`.
- Do not use `ai_teacher_reviews` as the main review path for `mock_test`.
- Make `exam_analysis` the only review source for exam result screens.

### `exam_analysis`

- Keep `question_feedbacks` for objective feedback and lightweight per-question summaries.
- Add `teacher_reviews_by_question` as a JSONB field keyed by `question_id`.
- Persist the full materialized speaking/writing review payload for each subjective question into this new field.

### `analyze-exam`

- Keep objective feedback generation as-is.
- For speaking/writing attempts that are `ready`, build the full review payload via the existing review payload builders.
- Store the full payload in `teacher_reviews_by_question[question_id]`.
- Also keep a summary-friendly entry in `question_feedbacks[question_id]` for list cards.
- Only mark `exam_analysis.status = ready` when the batch review state is resolved under the current batch rules.

## Flutter Data Model

- Extend `ExamAnalysis` to parse `teacher_reviews_by_question`.
- Treat exam subjective review as materialized read-only data, not a submit/poll workflow.
- Keep a helper that resolves a question ID to a parsed review object for the exam UI.

## Mock Test UI

- `MockTestResultScreen` keeps polling `examAnalysisProvider`, but that provider becomes the only source for review state.
- When `exam_analysis.status = processing`, show a whole-exam grading state such as “AI đang chấm toàn bộ bài thi và tạo nhận xét”.
- `QuestionReviewList`:
  - objective cards read from `question_feedbacks`
  - speaking/writing cards read summary data from `question_feedbacks`
  - speaking/writing detail reads from `teacher_reviews_by_question`
- Do not submit new AI review requests when expanding a card or opening detail.

## Exam Detail Screen

- Add an exam-specific subjective review detail route under the mock test flow.
- The screen reads review data from `examAnalysisProvider`.
- Presentation widgets may be reused, but the screen/provider path stays exam-specific and read-only.
- Do not use `SpeakingFeedbackScreen` or `WritingFeedbackScreen` for mock test review anymore.

## Boundaries

- Keep exercise/practice behavior unchanged.
- Keep `aiTeacherReviewBatchProvider` in the codebase for now, but stop using it in the mock test path.
- Maintain backward compatibility for older `exam_analysis` rows that do not have `teacher_reviews_by_question`.

## Verification

- Mock test submit with speaking/writing shows a whole-exam pending state.
- No `ai-review-submit` requests are triggered by expanding mock test review cards or opening subjective detail.
- When `exam_analysis` becomes `ready`, all speaking/writing review content appears together.
- Objective feedback remains correct.
- Practice/exercise speaking and writing feedback still work through the current AI Teacher flow.
- Older `exam_analysis` rows without the new field do not crash the UI.
