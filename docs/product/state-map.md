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
| `examAnalysisProvider` | `FutureProvider.autoDispose.family<ExamAnalysis?, String>` | Polls `exam_analysis` every 3s (max 30 retries) until status = `ready` / `error`; returns `null` on timeout so UI keeps shimmer/fallback |
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

---

### `course` — `lib/features/course/providers/course_providers.dart`

| Provider | Type | Returns |
|---|---|---|
| `courseCatalogProvider` | `AsyncNotifier<List<CourseDetail>>` | All courses with progress |
| `courseDetailProvider` | `AsyncNotifier<CourseDetail>` | Course by ID (arg) |
| `moduleDetailProvider` | `AsyncNotifier<ModuleDetail>` | Module with lesson list (arg) |
| `lessonDetailProvider` | `AsyncNotifier<LessonDetail>` | Lesson with blocks + exercises (arg) |

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
- `startRecording()` — requests mic permission, starts `AudioRecorder`, begins amplitude polling (80ms interval, last 30 samples kept)
- `stopRecording()` → status `recorded`
- `submitRecording({ lessonId, questionId, exerciseId?, examAttemptId? })` — encodes audio as base64, calls `speaking-upload` edge function; ONLY pass `questionId` for mock test / lesson questions (do NOT pass `exerciseId` when `questionId` is a real questions-table UUID — causes FK violation)
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

Both speaking and writing use identical polling flow:

```
submit (upload/submit edge fn) → { attempt_id }
    ↓
poll every 3s (result edge fn) → { status: 'pending' | 'ready' | 'error' }
    ↓ (max 10 retries)
ready → update state to SpeakingState.ready / WritingState.ready
error → update state to *.error(message), show retry CTA
timeout (10 retries exhausted) → *.error('scoring_timeout')
```

**Mock test context:** Khi submit speaking/writing trong mock test, `exam_attempt_id` phải được truyền vào `speaking-upload` / `writing-submit`. `grade-exam` JOIN các bảng AI attempt theo `exam_attempt_id + question_id`; nếu AI chưa xong thì câu đó tạm thời chưa có điểm và `exam_results.ai_grading_pending = true` để result screen hiển thị banner chờ. Sau khi ghi `exam_results`, edge function còn trigger `analyze-exam` để batch toàn bộ feedback vào `exam_analysis`.

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
Mock test review: `analyze-exam` gọi lại cùng cache/prompt này theo batch cho objective questions; result screen đọc `exam_analysis.question_feedbacks` nên không cần tap từng câu để khởi động AI
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
