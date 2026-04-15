# State Map — Trvalý Prep MVP
> Riverpod 2.x · AsyncNotifier / Notifier / StreamProvider
> File paths relative to `lib/`

---

## Global app state

### Auth state
**Provider**: `currentUserProvider` (AsyncNotifier)  
**File**: `shared/providers/auth_provider.dart`

```dart
@riverpod
class CurrentUser extends _$CurrentUser {
  // AsyncValue<AppUser?>
  // null = logged out
}
```

| State value | Meaning |
|-------------|---------|
| `AsyncLoading` | Session check in progress (splash) |
| `AsyncData(null)` | Unauthenticated |
| `AsyncData(AppUser)` | Authenticated |
| `AsyncError` | Supabase unreachable |

**Transitions**
```
app start → AsyncLoading
           → AsyncData(null)         unauthenticated
           → AsyncData(AppUser)      session restored
signIn()  → AsyncLoading → AsyncData(user)
signOut() → AsyncData(null)
```

---

### Connectivity state
**Provider**: `connectivityProvider` (StreamProvider)  
**File**: `shared/providers/connectivity_provider.dart`

```dart
enum ConnectivityStatus { online, offline }
```

Drives `OfflineBanner` visibility. Answers buffered locally when offline.

---

## Auth module

**Provider**: `authNotifierProvider` (Notifier)  
**File**: `features/auth/providers/auth_notifier.dart`

```dart
enum AuthFormStatus { idle, submitting, success, validationError, authError }

@freezed
class AuthFormState with _$AuthFormState {
  const factory AuthFormState({
    @Default(AuthFormStatus.idle) AuthFormStatus status,
    String? errorMessage,
  }) = _AuthFormState;
}
```

| State | Trigger |
|-------|---------|
| `idle` | Page mounted |
| `submitting` | Form submitted |
| `validationError` | Client-side validation fails |
| `authError` | Supabase returns 400/401 |
| `success` | Session created → navigate |

---

## Mock exam module

**Provider**: `examSessionNotifierProvider(String attemptId)` (AsyncNotifier)  
**File**: `features/mock_test/providers/exam_session_notifier.dart`

```dart
enum ExamSessionStatus {
  initializing,
  ready,
  autosaving,
  autosaveFailed,
  submitting,
  submitted,
}

@freezed
class ExamSessionState with _$ExamSessionState {
  const factory ExamSessionState({
    required ExamSession session,
    @Default(ExamSessionStatus.ready) ExamSessionStatus status,
    @Default({}) Map<String, Answer> currentAnswers,
    @Default(0) int currentSectionIndex,
    @Default(0) int currentQuestionIndex,
    @Default(false) bool showSectionTransition,
    String? autosaveError,
  }) = _ExamSessionState;
}
```

| Status | UI behaviour |
|--------|-------------|
| `initializing` | Full-screen spinner |
| `ready` | Exam active, timer ticking |
| `autosaving` | Small pulsing dot in top bar |
| `autosaveFailed` | Warning banner; answers kept in `shared_preferences` |
| `submitting` | All inputs locked, button spinner |
| `submitted` | `context.pushReplacement` to result |

**Timer** — separate `examTimerProvider(remainingSeconds)` (Notifier) that ticks every second. Auto-submits when reaches 0.

**Autosave** — debounced 30s timer + on every answer change. Falls back to `shared_preferences` if network fails.

---

## Exam result module

**Provider**: `examResultProvider(String attemptId)` (AsyncNotifier)  
**File**: `features/result/providers/exam_result_provider.dart`

```dart
// AsyncValue<ExamResult?>
// null = result not found
```

| State | |
|-------|--|
| `AsyncLoading` | Skeleton + animated score ring |
| `AsyncData(ExamResult)` | Full result displayed |
| `AsyncData(null)` | EmptyStateCard |
| `AsyncError` | ErrorStateCard + retry |

---

## Dashboard module

**Provider**: `dashboardProvider` (AsyncNotifier, composes sub-providers)  
**File**: `features/dashboard/providers/dashboard_provider.dart`

```dart
@freezed
class DashboardData with _$DashboardData {
  const factory DashboardData({
    required AppUser user,
    ExamResult? latestResult,
    RecommendedLesson? recommendation,
    @Default(0) int streakDays,
    @Default(0) int totalXp,
    @Default(0) int weeklyXp,
    int? weeklyRank,
    @Default([]) List<LeaderboardRow> leaderboardPreview,
    CourseProgress? activeCourse,
  }) = _DashboardData;
}
```

| State | Widget |
|-------|--------|
| `AsyncLoading` | `DashboardSkeleton` |
| `AsyncData` with no result | `EmptyResultBanner` |
| `AsyncData` with no course | `CoursePickerBanner` |
| `AsyncData` full | Full dashboard |
| `AsyncError` | `ErrorStateCard` |

---

## Course module

**Provider**: `courseDetailProvider(String courseSlug)` (AsyncNotifier)  
**File**: `features/course/providers/course_provider.dart`

```dart
// AsyncValue<CourseDetail?>
```

**Provider**: `moduleDetailProvider(String moduleId)` (AsyncNotifier)

**Provider**: `lessonDetailProvider(String lessonId)` (AsyncNotifier)

```dart
@freezed
class LessonDetailState with _$LessonDetailState {
  const factory LessonDetailState({
    required LessonDetail lesson,
    @Default(LessonStatus.inProgress) LessonStatus status,
  }) = _LessonDetailState;
}

enum LessonStatus { inProgress, allBlocksDone, bonusUnlocked }
```

---

## Practice / Exercise module

**Provider**: `practiceSessionNotifierProvider(String exerciseId)` (AsyncNotifier)  
**File**: `features/exercise/providers/practice_session_notifier.dart`

```dart
enum PracticeStatus {
  loading,
  ready,
  answerSubmitting,
  answerCorrect,
  answerIncorrect,
  navigatingToAI,
}

@freezed
class PracticeSessionState with _$PracticeSessionState {
  const factory PracticeSessionState({
    required Exercise exercise,
    @Default(PracticeStatus.ready) PracticeStatus status,
    Answer? selectedAnswer,
    String? errorMessage,
  }) = _PracticeSessionState;
}
```

---

## Speaking AI module

**Provider**: `speakingSessionNotifierProvider` (Notifier)  
**File**: `features/speaking_ai/providers/speaking_session_notifier.dart`

```dart
enum SpeakingStatus {
  micPermissionNeeded,
  readyToRecord,
  recording,
  reviewingRecording,
  uploading,
  scoringInProgress,
  scoringSuccess,
  scoringError,
}

@freezed
class SpeakingSessionState with _$SpeakingSessionState {
  const factory SpeakingSessionState({
    @Default(SpeakingStatus.readyToRecord) SpeakingStatus status,
    String? recordingPath,
    String? uploadedKey,
    String? attemptId,
    String? errorMessage,
  }) = _SpeakingSessionState;
}
```

**State machine**
```
readyToRecord
  → [tap mic] → recording
      → [tap stop] → reviewingRecording
          → [tap submit] → uploading
              → [upload done] → scoringInProgress
                  → [poll ready] → scoringSuccess → navigate to /ai-feedback/speaking/:id
                  → [poll error] → scoringError
          → [tap discard] → readyToRecord
  → [no mic permission] → micPermissionNeeded
```

**Provider**: `speakingFeedbackProvider(String attemptId)` (AsyncNotifier, polls Supabase until status = ready)

---

## Writing AI module

**Provider**: `writingSessionNotifierProvider` (Notifier)  
**File**: `features/writing_ai/providers/writing_session_notifier.dart`

```dart
enum WritingStatus { idle, editing, submitting, scoringInProgress, scoringSuccess, scoringError }

@freezed
class WritingSessionState with _$WritingSessionState {
  const factory WritingSessionState({
    @Default(WritingStatus.idle) WritingStatus status,
    @Default('') String draftText,
    int wordCount = 0,
    String? attemptId,
    String? errorMessage,
  }) = _WritingSessionState;
}
```

**Provider**: `writingFeedbackProvider(String attemptId)` (AsyncNotifier)

---

## Gamification module

**Provider**: `streakProvider` (AsyncNotifier)  
**Provider**: `xpNotifierProvider` (Notifier)  
**File**: `shared/providers/gamification_provider.dart`

```dart
enum GamificationEvent { lessonCompleted, examSubmitted, streakExtended, bonusUnlocked }

@freezed
class XpState with _$XpState {
  const factory XpState({
    @Default(0) int total,
    @Default(0) int weekly,
    int? weeklyRank,
    GamificationEvent? lastEvent,
  }) = _XpState;
}
```

XP award flow: exercise submitted → `xpNotifier.award(points)` → optimistic local update → confirm with Supabase

---

## Leaderboard module

**Provider**: `leaderboardProvider` (AsyncNotifier)  
**File**: `features/leaderboard/providers/leaderboard_provider.dart`

```dart
enum LeaderboardTab { weekly, allTime }

@freezed
class LeaderboardState with _$LeaderboardState {
  const factory LeaderboardState({
    @Default(LeaderboardTab.weekly) LeaderboardTab activeTab,
    @Default([]) List<LeaderboardRow> rows,
    int? ownRank,
    int? ownXp,
  }) = _LeaderboardState;
}
```

---

## Notifications module

**Provider**: `notificationPrefsNotifierProvider` (AsyncNotifier)  
**File**: `features/notifications/providers/notification_prefs_notifier.dart`

```dart
@freezed
class NotificationPrefs with _$NotificationPrefs {
  const factory NotificationPrefs({
    @Default(true) bool enabled,
    @Default(20) int reminderHour,
    @Default('Asia/Ho_Chi_Minh') String timezone,
  }) = _NotificationPrefs;
}
```

---

## Provider dependency graph (simplified)

```
authProvider
  └── currentUserProvider
        ├── dashboardProvider
        │     ├── streakProvider
        │     ├── xpProvider
        │     └── leaderboardProvider (preview)
        ├── courseDetailProvider
        │     └── moduleDetailProvider
        │           └── lessonDetailProvider
        │                 └── practiceSessionProvider
        │                       ├── speakingSessionProvider → speakingFeedbackProvider
        │                       └── writingSessionProvider → writingFeedbackProvider
        └── examResultProvider
```

Anonymous providers (no auth):
```
mockExamMetaProvider
  └── examSessionNotifierProvider
        └── examResultProvider
```
