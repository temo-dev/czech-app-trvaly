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
| `examResultProvider` | `AsyncNotifier<MockTestResult>` | Result by attemptId (arg) |
| `questionFeedbackProvider` | `AsyncNotifier<QuestionFeedbackData>` | AI feedback via `question-feedback` edge function |
| `examSessionNotifier` | `Notifier<ExamSessionState>` | **See state machine below** |

#### `ExamSessionState` (Freezed)

```dart
@freezed
class ExamSessionState {
  factory ExamSessionState({
    required String attemptId,
    required List<Question> questions,
    required Map<String, QuestionAnswer> answers,
    required int currentGlobalIndex,
    required int remainingSeconds,
    required ExamSessionStatus status,
    String? errorMessage,
  })
}

enum ExamSessionStatus {
  loading,
  active,
  sectionTransition,
  submitting,
  submitted,
  error,
}
```

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

State: `SpeakingState` (Freezed)

```dart
@freezed
class SpeakingState {
  factory SpeakingState.idle()
  factory SpeakingState.recording()
  factory SpeakingState.uploading()
  factory SpeakingState.processing(String attemptId)
  factory SpeakingState.ready(SpeakingResult result)
  factory SpeakingState.error(String message)
}
```

Provider: `speakingProvider` — `Notifier<SpeakingState>`.
Methods: `startRecording()`, `stopAndUpload(exerciseId)`, `pollResult(attemptId)` — polls every 3s, max 10 retries.

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

---

## Anonymous → Authenticated Linking

1. Guest submits mock test → `exam_attempts.user_id = null`
2. After `grade-exam` succeeds → `pendingAttemptId` stored in `PrefsStorage` (shared_preferences)
3. User signs up → `signUp()` success handler:
   - Reads `pendingAttemptId` from prefs
   - PATCHes `exam_attempts` row with new `user_id`
   - Clears `pendingAttemptId` from prefs
   - Invalidates `examResultProvider`
