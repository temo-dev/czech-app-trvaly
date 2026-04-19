# Plan: Refactor AI Teacher — Batch Exam Analysis

## Context

Hiện tại, AI feedback cho từng câu hỏi trong bài thi mock test được kích hoạt **on-demand**: người dùng phải bấm vào từng câu sai thì AI mới chấm và trả kết quả. Yêu cầu mới: sau khi nộp bài, AI tự động chấm và nhận xét **toàn bộ câu** (đúng + sai, tất cả loại bài), rồi **tổng hợp** thành chart kỹ năng + "Gợi ý tổng quan cải thiện". Người dùng vào màn kết quả là thấy ngay, không cần tap từng câu.

---

## Architecture Change

```
Before:  grade-exam → exam_results  →  result screen  →  user taps question  →  question-feedback (on-demand)
After:   grade-exam → exam_results
                    → analyze-exam (fire-and-forget)
                          ↓ batch all questions (objective: GPT; speaking/writing: pull existing tables)
                          ↓ 1x synthesis GPT call
                          → exam_analysis table (status: processing → ready)
                    result screen polls examAnalysisProvider → show insights + per-question feedback (preloaded)
```

---

## Phase 1 — Backend

### 1. New Supabase Migration
**File:** `supabase/migrations/20260420000001_exam_analysis.sql`

```sql
create table public.exam_analysis (
  id                      uuid primary key default gen_random_uuid(),
  attempt_id              uuid not null references public.exam_attempts(id) on delete cascade,
  user_id                 uuid references public.profiles(id) on delete set null,
  status                  text not null default 'processing'
                          check (status in ('processing', 'ready', 'error')),
  question_feedbacks      jsonb not null default '{}'::jsonb,
  skill_insights          jsonb not null default '{}'::jsonb,
  overall_recommendations jsonb not null default '[]'::jsonb,
  error_message           text,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),
  unique (attempt_id)
);
-- RLS: service role full access; authenticated users read own; anon read by attempt_id
```

`question_feedbacks` shape (keyed by `question_id`):
- Objective: `{ verdict, error_analysis, correct_explanation, short_tip, key_concept, matching_feedback?, skipped }`
- Speaking/Writing: `{ verdict, summary, criteria: [{label, score, feedback}], short_tips, skipped }`

`skill_insights` shape: `{ reading: { summary, main_issue }, listening: {...}, ... }`

`overall_recommendations` shape: `[{ title, detail }, ...]` (3–5 items)

---

### 2. New Edge Function: `analyze-exam`
**File:** `supabase/functions/analyze-exam/index.ts`

Logic:
1. Upsert `exam_analysis` row with `status='processing'` (idempotent via `onConflict: attempt_id`)
2. Fetch all questions + user answers (same query as `grade-exam`)
3. Fetch `ai_speaking_attempts` and `ai_writing_attempts` rows for this exam (already scored during exam)
4. If speaking/writing still `processing` → wait up to 30s in retry loop, then mark `skipped: true`
5. Loop all questions with concurrency=5:
   - **MCQ / fill_blank / matching / ordering (WRONG)**: check `question_ai_feedback` cache first; on miss → call GPT (reuse `QUESTION_FEEDBACK_PROMPT` from `question-feedback/index.ts`)
   - **MCQ / fill_blank / matching / ordering (CORRECT)**: use `question.explanation` directly (no GPT) → `correct_explanation = question.explanation`. Only call GPT if explanation is empty.
   - **Speaking**: pull metrics from `ai_speaking_attempts`, reformat to feedback shape. **No extra GPT call.**
   - **Writing**: pull metrics + annotated spans from `ai_writing_attempts`, reformat. **No extra GPT call.**
6. 1x synthesis GPT call with all per-question verdicts + section scores → `skill_insights` + `overall_recommendations`
7. Update row: `status='ready'`, write all fields
8. On unhandled error: `status='error'`, `error_message`

Per-question timeout: 15s with `AbortController`. On timeout → `skipped: true`, continue.

### 3. Modify `grade-exam` — trigger analyze-exam
**File:** `supabase/functions/grade-exam/index.ts`

After the `exam_results` insert succeeds (~line 356), add:
```typescript
supabase.functions.invoke('analyze-exam', { body: { attempt_id } }).catch(() => {});
```
Fire-and-forget, non-fatal.

---

## Phase 2 — Flutter Models

### 4. New Model File
**File:** `lib/features/mock_test/models/exam_analysis.dart`

```dart
enum ExamAnalysisStatus { processing, ready, error }

class QuestionAnalysisFeedback {
  final String questionId;
  final String verdict;       // 'correct' | 'incorrect' | 'partial'
  final String errorAnalysis;
  final String correctExplanation;
  final String shortTip;
  final String keyConceptLabel;
  final List<dynamic> matchingFeedback;
  final String summary;           // speaking/writing
  final List<Map<String, dynamic>> criteria; // speaking/writing
  final List<String> shortTips;
  final bool skipped;
  // fromJson factory
}

class SkillInsight { final String skill, summary, mainIssue; }
class OverallRecommendation { final String title, detail; }

class ExamAnalysis {
  final String id, attemptId;
  final ExamAnalysisStatus status;
  final Map<String, QuestionAnalysisFeedback> questionFeedbacks;
  final List<SkillInsight> skillInsights;
  final List<OverallRecommendation> overallRecommendations;
  final String? errorMessage;
  bool get isReady => status == ExamAnalysisStatus.ready;
  // fromJson factory
}
```

---

## Phase 3 — Riverpod Provider

### 5. New Provider
**File:** `lib/features/mock_test/providers/exam_analysis_provider.dart`

```dart
@riverpod
Future<ExamAnalysis?> examAnalysis(ExamAnalysisRef ref, String attemptId) async {
  // Poll exam_analysis table every 3s, max 30 retries (90s total)
  // Return null on timeout (caller shows shimmer/fallback, not error)
}
```

Run `make gen` after creating.

---

## Phase 4 — Result Screen

### 6. Modify `mock_test_result_screen.dart`
**File:** `lib/features/mock_test/screens/mock_test_result_screen.dart`

In `_ResultBody.build`:
- Add: `final analysis = ref.watch(examAnalysisProvider(result.attemptId)).valueOrNull;`
- Replace `_RecommendationCard(result: result)` with `OverallInsightsCard(analysis: analysis)`
- Pass `analysis` to `QuestionReviewList`

The score circle + skill chart section stays unchanged (already works from `examResultProvider`).

### 7. New Widget: `OverallInsightsCard`
**File:** `lib/features/mock_test/widgets/overall_insights_card.dart`

- `analysis == null || analysis.isProcessing` → shimmer skeleton + "Đang tổng hợp nhận xét AI..."
- `analysis.isReady` → render:
  - Skill insights row (per skill: summary + main_issue)
  - Recommendation tiles (title + detail cards)
- Uses `AppColors`, `AppTypography`, `AppSpacing` tokens

### 8. Modify `question_review_list.dart`
**File:** `lib/features/mock_test/widgets/question_review_list.dart`

- Add `final ExamAnalysis? analysis` to `QuestionReviewList` constructor
- Remove: `ref.watch(aiTeacherReviewBatchProvider(attemptId))` call from `_ReviewBody` (~line 98)
- Thread `analysis` down to `_QuestionCard` → `_ExpandedContent`
- In `_ExpandedContent`:
  - Replace `_AiQuestionFeedback(item)` + `_AiReinforcementPrompt(item)` for objective questions with:
    ```dart
    _PreloadedQuestionFeedback(
      feedback: analysis?.questionFeedbacks[item.question.id],
      isCorrect: item.isCorrect,
      questionType: item.question.type,
    )
    ```
  - Speaking/Writing panels (`_SpeakingReviewPanel`, `_WritingReviewPanel`) → unchanged, they read from `ai_speaking_attempts`/`ai_writing_attempts` via existing `aiTeacherReviewEntryProvider`
- New widget `_PreloadedQuestionFeedback`:
  - `feedback == null` → shimmer
  - `feedback.skipped` → "AI chưa phân tích được câu này"
  - correct → show `correctExplanation` (positive reinforcement)
  - incorrect → show `errorAnalysis` + `correctExplanation` + `shortTip` chip + `keyConceptLabel` badge

---

## What to Remove / Deprecate

| Target | Action |
|---|---|
| `ref.watch(aiTeacherReviewBatchProvider(attemptId))` in `_ReviewBody` | Remove |
| `_AiReinforcementPrompt` widget (objective questions) | Remove |
| `_AiQuestionFeedback` widget (objective questions) | Remove from exam review path |
| Static `_RecommendationCard` in result screen | Replace with `OverallInsightsCard` |
| `questionFeedbackProvider` | Keep — still used in lesson/exercise context |
| `aiTeacherReviewBatchProvider` | Keep — still used by speaking/writing detail screens; only remove exam-context trigger |
| `question-feedback` edge function | Keep — called internally by `analyze-exam` as cache writer |

---

## Implementation Order

1. `supabase/migrations/20260420000001_exam_analysis.sql` + apply migration
2. `supabase/functions/analyze-exam/index.ts` (new)
3. Modify `grade-exam/index.ts` (add fire-and-forget call)
4. `lib/features/mock_test/models/exam_analysis.dart` (new)
5. `lib/features/mock_test/providers/exam_analysis_provider.dart` (new) + `make gen`
6. Modify `mock_test_result_screen.dart`
7. `lib/features/mock_test/widgets/overall_insights_card.dart` (new)
8. Modify `lib/features/mock_test/widgets/question_review_list.dart`

---

## Verification

1. Submit a mock test (with MCQ + fill_blank + speaking + writing)
2. Verify `exam_analysis` row appears with `status='processing'` then transitions to `'ready'` within ~30–60s
3. Result screen: score + chart loads immediately (from `examResultProvider`), insights section shows shimmer then populates
4. Expand any MCQ question → feedback shown without any user action
5. Expand speaking/writing question → existing panels still render correctly
6. "Gợi ý tổng quan" shows 3–5 actionable recommendations
7. Test edge case: all-correct exam → reinforcement feedback shown per question
8. Test edge case: `analyze-exam` times out → shimmer stays, no crash, score section unaffected
