# State Map

Riverpod provider definitions and Freezed state classes across the app.

---

## Shared Providers (`lib/shared/providers/`)

### `auth_provider.dart`

| Provider | Type | Returns | Notes |
|---|---|---|---|
| `authSessionProvider` | `StreamProvider<Session?>` | `Session?` | Backed by `supabase.auth.onAuthStateChange` |
| `currentUserProvider` | `AsyncNotifier<AppUser?>` | `AsyncValue<AppUser?>` | Fetches from `profiles` table; falls back to auth metadata if profile missing |
| `isAuthenticatedProvider` | `Provider<bool>` | `bool` | `supabase.auth.currentSession != null` |

`CurrentUser` methods: `signIn(email, password)`, `signUp(email, password, displayName)`, `signOut()`, `sendPasswordReset(email)`, `updateProfile({displayName, avatarUrl, examDate, dailyGoalMinutes})`.

---

### `subscription_provider.dart`

| Provider | Type | Returns |
|---|---|---|
| `subscriptionStatusProvider` | `Provider<SubscriptionStatus>` | Derived from `currentUserProvider` |
| `isPremiumProvider` | `Provider<bool>` | `subscriptionStatus == .active` |

Enum `SubscriptionStatus { active, expired, free }`.
The router's `_RouterNotifier` watches `subscriptionStatusProvider` to refresh routes on subscription changes.

---

### `connectivity_provider.dart`

| Provider | Type | Returns |
|---|---|---|
| `connectivityProvider` | `StreamProvider<ConnectivityStatus>` | `online` or `offline` |

Enum `ConnectivityStatus { online, offline }`. Read by `AppShell`'s offline banner.

---

### `gamification_provider.dart`

Top-level functions (not providers):

- `awardXp(WidgetRef ref, int xpAmount)` — optimistic update on local profile, persists via `increment_xp` RPC, falls back to raw UPDATE. Invalidates `currentUserProvider`.
- `updateActivityStreak(WidgetRef ref)` — increments streak if `last_activity_date` = yesterday; resets to 1 if gap > 1 day; no-op if already updated today. Invalidates `currentUserProvider`.

---

## Feature Providers

### `auth` — `lib/features/auth/providers/auth_notifier.dart`

State: `AuthState` (Freezed)
```dart
@freezed
class AuthState {
  factory AuthState.initial()
  factory AuthState.loading()
  factory AuthState.success()
  factory AuthState.error(String message)
}
```

Provider: `authNotifierProvider` — `Notifier<AuthState>`. Delegates to `currentUserProvider` methods.

---

### `dashboard` — `lib/features/dashboard/providers/dashboard_provider.dart`

Provider: `dashboardProvider` — `AsyncNotifier<DashboardData>`.

Build query: fetches `currentUserProvider`, latest `exam_results` row, `leaderboard_weekly` top 5 + own rank, `user_progress` latest lesson, active course progress. Assembles `DashboardData`.

---

### `mock_test` — `lib/features/mock_test/providers/`

| Provider | Type | Returns |
|---|---|---|
| `examListProvider` | `AsyncNotifier<List<ExamMeta>>` | Active exams with sections |
| `mockExamMetaProvider` | `AsyncNotifier<ExamMeta>` | Single exam by ID (arg) |
| `examQuestionsProvider` | `AsyncNotifier<List<Question>>` | Questions for all sections of an attempt |
| `examResultProvider` | `AsyncNotifier<MockTestResult>` | Result by attemptId (arg) — includes `aiGradingPending` flag |
| `examAnalysisProvider` | `FutureProvider.autoDispose.family<ExamAnalysis?, String>` | Fetches `exam_analysis` by `attempt_id`; when status = `processing` it returns the row immediately and schedules another refresh after 3s so mock-test UI can show whole-exam grading progress instead of waiting silently |
| `questionFeedbackProvider` | `AsyncNotifier<QuestionAiFeedback?>` | **Auto-fetch** AI feedback via `question-feedback` edge function; kết quả lấy từ cache `question_ai_feedback` nếu đã tồn tại |
| `examSessionNotifier` | `Notifier<ExamSessionState>` | **See state machine below** |

#### `ExamSessionState` (Freezed)

```dart
@freezed
class ExamSessionState {
  factory ExamSessionState({
    required ExamAttempt attempt,
    required ExamMeta meta,
    required Map<String, ExamQuestionAnswer> currentAnswers,
    required int currentSectionIndex,
    required int currentQuestionIndex,
    required bool showSectionTransition,
    required ExamSessionStatus status,
    required AutosaveStatus autosaveStatus,
    String? errorMessage,
  })
}

enum ExamSessionStatus {
  initializing,
  ready,
  autosaving,
  autosaveFailed,
  submitting,
  submitted,
}
```

`currentAnswers` được lưu theo `question_id`, không dùng key kiểu `q_<index>` nữa.
Payload mỗi câu hỏi:
`{ question_id, selected_option_id?, written_answer?, ai_attempt_id? }`

Key methods: `answerQuestion(globalIndex, QuestionAnswer)`, `flagQuestion(globalIndex)`, `navigateTo(index)`, `submitExam()`, `tickTimer()`.

Operational notes:
- When every `exam_section.section_duration_minutes` is non-null and `> 0`, the session uses per-section timers and derives `currentSectionIndex` from `remaining_seconds`.
- The question renderer now hydrates `intro_text`, `intro_image_url`, `passage_text`, `audio_url`, and `accepted_answers` directly from Supabase instead of overloading `prompt`.
- Listening `fill_blank` shows the audio player above the input field.

---

### `course` — `lib/features/course/providers/course_providers.dart`

| Provider | Type | Returns |
|---|---|---|
| `courseCatalogProvider` | `AsyncNotifier<List<CourseDetail>>` | All courses with progress |
| `courseDetailProvider` | `AsyncNotifier<CourseDetail>` | Course by ID (arg) |
| `moduleDetailProvider` | `AsyncNotifier<ModuleDetail>` | Module with lesson list (arg) |
| `lessonDetailProvider` | `AsyncNotifier<LessonDetail>` | Lesson with blocks + exercises (arg) |

Helpers in the same file:
- `markBlockComplete(lessonId, lessonBlockId)` — idempotent `SELECT` + `INSERT`
  into `user_progress`
- `resetLessonProgress(lessonId)` — delete current user's `user_progress` rows for one lesson so it can be replayed
- `refreshCourseProgressProviders(courseId, moduleId, lessonId)` — invalidates lesson/module/course/dashboard progress state together

Operational note:
- `markBlockComplete` no longer relies on conflict-update semantics in the
  current client path, so repeated ready/rebuild events do not rewrite the same
  progress row.
- `user_progress` still keeps an `UPDATE` policy for backward compatibility with
  legacy clients or older flows that used `upsert`.
- Speaking/Writing feedback screens only sync lesson progress after AI result reaches `ready`; progress sync is wrapped defensively so an RLS/config issue does not crash the screen.

Progress rules:
- `LessonStatus.available` = 0 completed blocks
- `LessonStatus.inProgress` = partial completed blocks
- `LessonStatus.completed` = all blocks completed
- `ModuleStatus.inProgress` only appears when the module has real progress, not just because another module is active

---

### `exercise` (Lesson Feedback) — `lib/features/exercise/providers/lesson_feedback_provider.dart`

| Provider | Type | Returns |
|---|---|---|
| `lessonQuestionFeedbackProvider(params)` | `FutureProvider.autoDispose.family<QuestionAiFeedback?, LessonFeedbackParams>` | AI feedback cho câu trả lời sai trong lesson; chỉ fetch với MCQ/fill_blank; hit cache từ `question_ai_feedback` |

`LessonFeedbackParams { questionId, questionText, options, correctAnswerText, userAnswerText, sectionSkill, questionType }`

`QuestionAiFeedback { errorAnalysis, correctExplanation, shortTip, keyConceptLabel, matchingFeedback? }`

---

### `exercise` — `lib/features/exercise/providers/exercise_provider.dart`

State: `ExerciseSessionState` (Freezed)

```dart
@freezed
class ExerciseSessionState {
  factory ExerciseSessionState({
    required List<Exercise> exercises,
    required int currentIndex,
    required Map<String, QuestionAnswer> answers,
    required Map<String, bool> results,
    required ExerciseSessionStatus status,
    String? currentFeedback,
  })
}

enum ExerciseSessionStatus {
  loading,
  intro,
  question,
  explanation,
  completed,
  error,
}
```

Provider: `exerciseSessionProvider` — `AsyncNotifier<ExerciseSessionState>`.
Methods: `submitAnswer(exerciseId, QuestionAnswer)`, `next()`, `restart()`.

---

### `speaking_ai` — `lib/features/speaking_ai/providers/speaking_provider.dart`

State: `SpeakingState` (plain class with `copyWith`)

```dart
enum SpeakingStatus { idle, recording, recorded, uploading, uploaded, error }

class SpeakingState {
  final SpeakingStatus status;
  final String? audioPath;
  final String? attemptId;
  final String? errorMessage;
  final List<double> amplitudes; // 0.0–1.0, recent 30 samples for waveform
}
```

Provider: `speakingSessionProvider` — `StateNotifierProvider<SpeakingSessionNotifier, SpeakingState>`.

Key methods on `SpeakingSessionNotifier`:
- `startRecording()` — requests mic permission, starts `AudioRecorder`, prefers `wav` when supported (falls back to `m4a`), begins amplitude polling (80ms interval, last 30 samples kept)
- `stopRecording()` → status `recorded`
- `submitRecording({ lessonId, questionId, exerciseId?, examAttemptId? })` — encodes audio as base64, passes `audio_format`, calls `speaking-upload` edge function; ONLY pass `questionId` for mock test / lesson questions (do NOT pass `exerciseId` when `questionId` is a real questions-table UUID — causes FK violation)
- `discardRecording()` — deletes temp file, resets to idle
- `restoreRecording(value)` — restores `recorded` (file path) or `uploaded` (UUID) state when navigating back
- `resetToIdle()` — clears state

**State update safety:** `_setStateSafely` uses `runZonedGuarded` (not plain try/catch) because Riverpod notifies listeners via `Zone.runBinaryGuarded`, routing `AssertionError` from defunct `ConsumerStatefulElement`s through the zone error handler rather than normal exception propagation.

Feedback provider: `speakingFeedbackProvider(attemptId)` — `AsyncNotifier` that fetches a completed `ai_speaking_attempts` row.

---

### `writing_ai` — `lib/features/writing_ai/providers/writing_provider.dart`

State: `WritingState` (Freezed)

```dart
@freezed
class WritingState {
  factory WritingState.idle()
  factory WritingState.submitting()
  factory WritingState.processing(String attemptId)
  factory WritingState.ready(WritingResult result)
  factory WritingState.error(String message)
}
```

Provider: `writingProvider` — `Notifier<WritingState>`.
Methods: `submit(text, exerciseId)`, `pollResult(attemptId)` — polls every 3s, max 10 retries.

---

### `leaderboard` — `lib/features/leaderboard/providers/leaderboard_provider.dart`

Provider: `leaderboardProvider` — `AsyncNotifier<List<LeaderboardRow>>`.
Fetches current week's `leaderboard_weekly` ordered by `weekly_xp DESC`, marks own row.

---

### `progress` — `lib/features/progress/providers/progress_provider.dart`

Provider: `progressProvider` — `AsyncNotifier<ProgressData>`.
Aggregates `user_progress` counts per skill, `exercise_attempts` accuracy, XP history.

---

### `chat` — `lib/features/chat/providers/`

**`chat_providers.dart`**

| Provider | Type | Returns |
|---|---|---|
| `conversationListProvider` | `StreamProvider<List<DmConversation>>` | Realtime inbox |
| `chatRoomProvider(roomId)` | `StreamProvider<List<ChatMessage>>` | Realtime messages for a room |
| `sendMessageProvider` | `AsyncNotifier` | Fire-and-forget send; handles text + attachments |

**`friend_providers.dart`**

| Provider | Type | Returns |
|---|---|---|
| `friendListProvider` | `AsyncNotifier<List<UserProfile>>` | Accepted friends |
| `friendRequestsProvider` | `AsyncNotifier<List<UserProfile>>` | Pending incoming requests |
| `userSearchProvider(query)` | `AsyncNotifier<List<UserProfile>>` | Search `public_profiles` view |

---

### `teacher_feedback` — `lib/features/teacher_feedback/providers/teacher_feedback_provider.dart`

| Provider | Type | Returns |
|---|---|---|
| `teacherReviewListProvider` | `AsyncNotifier<List<TeacherReview>>` | Own review threads |
| `teacherThreadProvider(reviewId)` | `AsyncNotifier<List<TeacherComment>>` | Thread messages |

---

### `notifications` — `lib/features/notifications/providers/notification_prefs_provider.dart`

Provider: `notificationPrefsProvider` — `AsyncNotifier<NotificationPrefs>`.
Reads/writes `profiles.notification_prefs` jsonb column.

---

## AI Polling Pattern

Both speaking and writing use polling-based result screens, but speaking now returns faster from submit and finishes AI work in the background:

```
submit (upload/submit edge fn) → create attempt row (`processing`) → { attempt_id }
    ↓
poll result edge fn → { status: 'pending' | 'ready' | 'error' }
    ↓
ready → update state to SpeakingState.ready / WritingState.ready
error → update state to *.error(message), show retry CTA
timeout → keep pending copy for AI Teacher review; speaking/writing result screens may still show retry/error CTA
```

**Mock test context:** Khi submit speaking/writing trong mock test, `exam_attempt_id` phải được truyền vào `speaking-upload` / `writing-submit`. `grade-exam` JOIN các bảng AI attempt theo `exam_attempt_id + question_id`; nếu AI chưa xong thì câu đó tạm thời chưa có điểm và `exam_results.ai_grading_pending = true` để result screen hiển thị banner chờ. Sau khi ghi `exam_results`, edge function còn trigger `analyze-exam` để batch toàn bộ feedback vào `exam_analysis`, gồm `question_feedbacks` và `teacher_reviews_by_question`.
`exam_results.passed` hiện được persist theo official bucket rule của đề A2: written `>= 42/70` và speaking `>= 24/40`.
Trong lúc `ai_grading_pending = true`, app phải coi row này là provisional: chưa hiển thị kết luận đậu/rớt, tổng điểm cuối, weak skills, hoặc breakdown kỹ năng chính thức. Khi speaking/writing attempt mock test hoàn tất (`ready` hoặc `error`), edge function sẽ trigger `grade-exam` lại để chốt row cuối.

**Operational note:** `speaking-upload` no longer blocks on OpenAI scoring. It inserts the attempt row first, returns `attempt_id` immediately, then uses an Edge Runtime background task to run transcription + grading and update the same row to `ready/error`. For `wav`/`mp3`, the function now starts transcription and audio-native scoring in parallel, persists the transcript as soon as it is available, and uses that intermediate transcript presence to distinguish `transcribing` vs `scoring` while the row remains `processing`. Speaking grading still prefers audio-native scoring for both exercise and exam flows, while transcript remains available for review UI and fallback grading.

`writing-submit` now follows the same async pattern: it resolves `question_id`/`exercise_id`, inserts `ai_writing_attempts(status='processing')`, returns `attempt_id` immediately, then uses an Edge Runtime background task to score the essay with `gpt-5-mini` and update the same row to `ready/error`.

`aiTeacherReviewEntryProvider` also auto-polls while `ai-review-result` returns `pending`. Pending responses now include a user-facing `message` plus optional `processing_stage`, so review cards/detail screens can distinguish between “đang nhận transcript”, “đang chấm bài nói/bài viết”, and “đang hoàn thiện nhận xét”. Subjective speaking/writing reviews now poll at `2s x 20 retries`; objective reviews keep the previous slower cadence.

## Question Feedback Pattern (Lesson + Review)

```
MCQ/fill_blank/matching/ordering trả lời sai
    ↓
gọi question-feedback edge function (với question_id + user_answer_text)
    ↓
edge function check cache (question_ai_feedback table)
    ├─ cache hit → trả về ngay (from_cache: true)
    └─ cache miss → gọi GPT → upsert vào cache → trả về
    ↓
Lesson flow: hiển thị LessonAnswerFeedbackSheet (bottom sheet) trước khi sang câu tiếp
Mock test review: `analyze-exam` gọi lại cùng cache/prompt này theo batch cho objective questions; result screen đọc `exam_analysis.question_feedbacks` cho summary card và `teacher_reviews_by_question` cho subjective detail nên không còn tap từng câu để khởi động AI Teacher review.
```

---

## Anonymous → Authenticated Linking

1. Guest submits mock test → `exam_attempts.user_id = null`
2. After `grade-exam` succeeds → `pendingAttemptId` stored in `PrefsStorage` (shared_preferences)
3. User signs up → `signUp()` success handler:
   - Reads `pendingAttemptId` from prefs
   - PATCHes `exam_attempts`, `exam_results`, `exam_analysis`, `ai_speaking_attempts`, `ai_writing_attempts` bằng `exam_attempt_id`
   - Clears `pendingAttemptId` from prefs
   - Invalidates `examResultProvider`
