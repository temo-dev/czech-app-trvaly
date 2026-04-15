# Screen Map — Trvalý Prep MVP
> Flutter Web + iOS · Riverpod · GoRouter · Supabase
> Each entry is a complete implementation contract for one screen.

---

## Legend
| Field | Meaning |
|-------|---------|
| `file` | Dart file path relative to `lib/` |
| `provider` | Riverpod provider(s) the screen consumes |
| `state` | States the screen must render |
| `data in` | What the screen needs before it can paint |
| `data out` | What the screen produces (mutations/navigation) |

---

## S01 · Landing Page

| | |
|---|---|
| **Route** | `/` |
| **file** | `features/landing/screens/landing_screen.dart` |
| **module** | `landing` |
| **auth** | anonymous |
| **purpose** | Acquire users; drive into free mock test |

**Components**
- `LandingHeroSection` — headline + sub + 2 CTAs (mock test / login)
- `ExamSkillsGrid` — 4 skill cards (Reading, Listening, Writing, Speaking)
- `ResultPreviewSection` — blurred result screenshot + "know your score" copy
- `TestimonialsCarousel` — 3 learner quotes
- `LandingFaqAccordion` — 5 most common questions
- `StickyBottomCTA` — persistent "Thi thử miễn phí" bar on mobile

**State variants**
| State | Behaviour |
|-------|-----------|
| `initial` | Static content renders, no API call |
| `web-wide` | 2-column hero layout, sidebar nav |
| `mobile` | Single column, sticky bottom CTA |

**data in** — no API call; all content is hardcoded/localised strings  
**data out** — `context.push(AppRoutes.mockTestIntro)` or `context.push(AppRoutes.login)`

**Platform notes**  
- Web: full-width hero with side graphic, `WebSidebarNav` visible  
- iOS: `MobileBottomNav` hidden on this screen (not in shell)

---

## S02 · Free Mock Test Intro

| | |
|---|---|
| **Route** | `/mock-test/intro` |
| **file** | `features/mock_test/screens/mock_test_intro_screen.dart` |
| **module** | `mock_test` |
| **auth** | anonymous |

**Components**
- `ExamInfoCard` — duration, section count, skill list
- `ExamRulesChecklist` — 4 rule bullets
- `PrimaryButton` `label: 'Bắt đầu thi'`

**Provider** — `mockExamMetaProvider` (fetches exam config from Supabase `exams` table)

**State variants**
| State | Widget shown |
|-------|-------------|
| `loading` | `AppSkeleton` |
| `success` | Full intro UI |
| `error` | `ErrorStateCard` + retry |

**data in**
```dart
ExamMeta { id, title, durationMinutes, sections: [SectionMeta] }
```

**data out**  
- POST `exam_attempts` → get `attemptId`  
- `context.push('/mock-test/session/$attemptId')`

---

## S03 · Exam Simulator

| | |
|---|---|
| **Route** | `/mock-test/session/:attemptId` |
| **file** | `features/mock_test/screens/exam_session_screen.dart` |
| **module** | `mock_test` |
| **auth** | anonymous |

**Components**
- `ExamTopBar` — `ExamTimer` + section label + autosave indicator
- `QuestionShell` — renders one of: `McqQuestion`, `FillBlankQuestion`, `ListeningQuestion`, `WritingPromptQuestion`, `SpeakingPromptQuestion`
- `QuestionProgressBar` — answered / total
- `QuestionNavigationPanel` — bottom sheet grid on mobile; sidebar panel on web
- `SectionTransitionCard` — between-section screen
- `ExamSubmitButton` + `ConfirmSubmitDialog`

**Provider** — `examSessionNotifierProvider(attemptId)` (AsyncNotifier)

**State variants**
| State | |
|-------|--|
| `session_initializing` | Full-screen loading spinner |
| `session_ready` | Active exam UI |
| `autosaving` | Small dot indicator pulses |
| `autosave_failed` | Warning banner, answers stored locally |
| `submitting` | Button spinner, inputs locked |
| `submitted` | Navigate to result |

**data in**
```dart
ExamSession {
  attemptId, sections: [Section { id, skill, questions: [Question] }],
  currentAnswers: Map<questionId, Answer>,
  remainingSeconds: int,
}
```

**data out**
- PATCH `exam_attempts/:id/answers` (every 30s + on answer change)
- POST `exam_attempts/:id/submit`
- `context.pushReplacement('/mock-test/result/$attemptId')`

**Critical behaviours**
- App backgrounded → timer pauses; resume on foreground
- Answers buffered in `shared_preferences` as fallback if network drops
- Back button → `ConfirmExitDialog`

---

## S04 · Exam Result

| | |
|---|---|
| **Route** | `/mock-test/result/:attemptId` |
| **file** | `features/result/screens/exam_result_screen.dart` |
| **module** | `result` |
| **auth** | anonymous or authenticated |

**Components**
- `TotalScoreHero` — large score ring + pass/fail label
- `SkillBreakdownChart` — 4 horizontal bars (R/L/W/S)
- `WeakSkillsList` — chips for skills < threshold
- `RecommendationCard` — "Start with Listening Module 1"
- `ResultCTASection` — if anonymous: `SignupToSaveCTA`; if auth: `StartLearningCTA`

**Provider** — `examResultProvider(attemptId)`

**State variants**
| State | |
|-------|--|
| `loading` | Skeleton with animated score ring |
| `success` | Full result |
| `no_result` | `EmptyStateCard` "Result not found" |
| `error` | `ErrorStateCard` |

**data in**
```dart
ExamResult {
  attemptId, totalScore, passThreshold,
  sectionScores: { skill: { score, total } },
  weakSkills: [Skill],
  recommendation: RecommendationSummary,
  isAuthenticated: bool,
}
```

**data out** (anonymous path)
- Store `pendingAttemptId` in `shared_preferences`
- `context.push(AppRoutes.signup)`

**data out** (authenticated path)
- `context.push(AppRoutes.dashboard)`

---

## S05 · Login

| | |
|---|---|
| **Route** | `/auth/login` |
| **file** | `features/auth/screens/login_screen.dart` |
| **module** | `auth` |
| **auth** | anonymous |

**Components**
- `AppLogo` + page title
- `AppTextField` email + `PasswordField`
- `LoadingButton` label 'Đăng nhập'
- `InlineLinkButton` 'Quên mật khẩu?' → `/auth/forgot-password`
- `InlineLinkButton` 'Tạo tài khoản' → `/auth/signup`
- `SocialAuthButton` (Google, Apple) — optional Phase 2

**Provider** — `authNotifierProvider`

**State variants**
| State | |
|-------|--|
| `idle` | Clean form |
| `submitting` | Button spinner, fields disabled |
| `validation_error` | Inline field errors |
| `auth_error` | Snackbar "Email hoặc mật khẩu không đúng" |
| `success` | Navigate to `?from=` param or `/dashboard` |

**data in** — `?from=` query param (redirect target after login)  
**data out** — Supabase `signInWithPassword` → session

---

## S06 · Signup

| | |
|---|---|
| **Route** | `/auth/signup` |
| **file** | `features/auth/screens/signup_screen.dart` |
| **module** | `auth` |
| **auth** | anonymous |

**Components**
- `AppTextField` email + `PasswordField` + confirm password
- `SaveResultBanner` — shown if `pendingAttemptId` exists in prefs
- `LoadingButton` 'Tạo tài khoản'
- `InlineLinkButton` 'Đã có tài khoản' → login

**Provider** — `authNotifierProvider`

**Special flow**: on success, if `pendingAttemptId` in prefs → PATCH `exam_attempts/:id` with new `user_id` → clear prefs key

**data in** — optional `pendingAttemptId` from `shared_preferences`  
**data out** — Supabase `signUp` → profile row insert → `context.pushReplacement(AppRoutes.dashboard)`

---

## S07 · Dashboard

| | |
|---|---|
| **Route** | `/dashboard` |
| **file** | `features/dashboard/screens/dashboard_screen.dart` |
| **module** | `dashboard` |
| **auth** | authenticated |

**Components**
- `DailyGreetingHeader` — "Chào [name], hôm nay học gì?" + exam countdown chip
- `LatestResultCard` — score ring + weak skill chips
- `RecommendedLessonCard` → navigates to lesson
- `StreakCard` — flame + day count
- `PointsCard` — XP total + weekly rank preview
- `WeakSkillsSection` — 2–3 `WeakSkillChip` → practise
- `LeaderboardPreviewCard` — top 3 + own rank
- `CourseProgressSection` — active course progress bar

**Provider** — `dashboardProvider` (composes multiple sub-providers)

**State variants**
| State | |
|-------|--|
| `loading` | `DashboardSkeleton` (shimmer 4 cards) |
| `no_result_yet` | `EmptyResultBanner` "Bắt đầu bằng bài thi thử" |
| `no_course_yet` | `CoursePickerBanner` |
| `success` | Full dashboard |
| `error` | `ErrorStateCard` with retry |

**data in**
```dart
DashboardData {
  user: AppUser,
  latestResult: ExamResult?,
  recommendation: RecommendedLesson?,
  streak: int,
  weeklyXp: int,
  totalXp: int,
  weeklyRank: int?,
  leaderboardPreview: List<LeaderboardRow>,
  activeCourse: CourseProgress?,
}
```

---

## S08 · Course Overview

| | |
|---|---|
| **Route** | `/course/:courseSlug` |
| **file** | `features/course/screens/course_overview_screen.dart` |
| **module** | `course` |
| **auth** | authenticated |

**Components**
- `CourseHeaderBanner` — title + description + skill tag + `ProgressRing`
- `CourseModuleList` — `ModuleCard` per module (locked / in-progress / complete)
- `StickyBottomCTA` 'Tiếp tục học' → last accessed lesson
- `BreadcrumbBar` (web only)

**Provider** — `courseDetailProvider(courseSlug)`

**State variants**: loading · success · error · all_locked (free user)

**data in**
```dart
CourseDetail {
  course: Course,
  modules: List<ModuleSummary { id, title, lessonCount, completedCount, isLocked }>,
  overallProgress: double,
  lastAccessedLessonId: String?,
}
```

---

## S09 · Module Detail

| | |
|---|---|
| **Route** | `/module/:moduleId` |
| **file** | `features/course/screens/module_detail_screen.dart` |
| **module** | `course` |
| **auth** | authenticated |

**Components**
- `ModuleHeaderCard` — title + skill + lesson count
- `LessonList` — `LessonListTile` per lesson (status icon: lock / circle / checkmark)

**Provider** — `moduleDetailProvider(moduleId)`

**data in**
```dart
ModuleDetail {
  module: Module,
  lessons: List<LessonSummary { id, title, type, status: LessonStatus }>,
}
```

---

## S10 · Lesson Detail

| | |
|---|---|
| **Route** | `/lesson/:lessonId` |
| **file** | `features/course/screens/lesson_detail_screen.dart` |
| **module** | `course` |
| **auth** | authenticated |

**Components**
- `LessonHeaderCard` — title + skill tag + duration
- `LessonBlockList` — exactly 6 `LessonBlockCard`s (ordered)
  - Block types: `VocabBlock`, `GrammarBlock`, `ReadingBlock`, `ListeningBlock`, `SpeakingBlock`, `WritingBlock`
- `ExerciseProgressFooter` — `x/6 blocks done`
- `BonusUnlockSection` — locked until all 6 done; costs XP

**Provider** — `lessonDetailProvider(lessonId)`

**State variants**: loading · lesson_ready · lesson_completed (all 6 done, bonus unlocked)

**data in**
```dart
LessonDetail {
  lesson: Lesson,
  blocks: List<LessonBlock { id, type, exerciseId, status: BlockStatus }>,
  bonusXpCost: int,
  bonusUnlocked: bool,
  totalXp: int,
}
```

**data out** — navigate to `/practice/:exerciseId` per block

---

## S11 · Practice Exercise

| | |
|---|---|
| **Route** | `/practice/:exerciseId` |
| **file** | `features/exercise/screens/practice_screen.dart` |
| **module** | `exercise` |
| **auth** | authenticated |

**Components** — `ExerciseShell` wraps one of:
| Exercise type | Renderer widget |
|--------------|----------------|
| `mcq` | `McqExercise` |
| `fill_blank` | `FillBlankExercise` |
| `matching` | `MatchingExercise` |
| `ordering` | `OrderingExercise` |
| `reading_mcq` | `ReadingPassageExercise` |
| `listening_mcq` | `ListeningExercise` + `AudioPlayerBar` |
| `speaking` | `SpeakingRecorderExercise` |
| `writing` | `WritingInputExercise` |

**Shared sub-components**: `SubmitAnswerButton`, `ExplanationPanel` (shown after submit), `ExerciseProgressFooter`

**Provider** — `practiceSessionNotifierProvider(exerciseId)`

**State variants**
| State | |
|-------|--|
| `loading` | Skeleton |
| `ready` | Exercise rendered |
| `answer_submitting` | Button spinner |
| `answer_correct` | Green highlight + `ExplanationPanel` |
| `answer_incorrect` | Red highlight + `ExplanationPanel` |
| `navigating_to_ai` | Spinner (speaking/writing → AI screen) |

**data out** (speaking) → upload → `context.push('/ai-feedback/speaking/$attemptId')`  
**data out** (writing) → submit → `context.push('/ai-feedback/writing/$attemptId')`  
**data out** (other) → POST `exercise_attempts` → award XP → `context.pop()` to lesson

---

## S12 · Speaking AI Feedback

| | |
|---|---|
| **Route** | `/ai-feedback/speaking/:attemptId` |
| **file** | `features/speaking_ai/screens/speaking_feedback_screen.dart` |
| **module** | `speaking_ai` |
| **auth** | authenticated |

**Components**
- `AIFeedbackHeader` — skill + score badge
- `ScoreMetricCard` × 3 — Pronunciation / Fluency / Vocabulary
- `TranscriptBlock` — learner transcript, issues highlighted
- `StrengthList` + `ImprovementList`
- `CorrectedAnswerPanel` — AI-improved version
- `RetryButton` + `ContinueLessonButton`

**Provider** — `speakingFeedbackProvider(attemptId)` — polls until `status == ready`

**State variants**
| State | |
|-------|--|
| `scoring_in_progress` | Animated "Đang chấm điểm..." with pulse ring |
| `scoring_success` | Full feedback |
| `scoring_error` | `ErrorStateCard` + retry option |

**data in**
```dart
SpeakingFeedback {
  attemptId, overallScore: int,
  metrics: { pronunciation: int, fluency: int, vocabulary: int },
  transcript: String,
  strengths: List<String>,
  improvements: List<String>,
  correctedAnswer: String,
  processingStatus: 'processing' | 'ready' | 'error',
}
```

---

## S13 · Writing AI Feedback

| | |
|---|---|
| **Route** | `/ai-feedback/writing/:attemptId` |
| **file** | `features/writing_ai/screens/writing_feedback_screen.dart` |
| **module** | `writing_ai` |
| **auth** | authenticated |

**Components**
- `AIFeedbackHeader` — score + task type
- `ScoreMetricCard` × 4 — Grammar / Vocabulary / Coherence / Task Achievement
- `AnnotatedEssayPanel` — learner text with inline annotation taps
- `CorrectedAnswerPanel` — AI-improved essay
- `GrammarNotesList` + `VocabularyNotesList`
- `RetryButton` + `ContinueLessonButton`

**Provider** — `writingFeedbackProvider(attemptId)`

**State variants**: `scoring_in_progress` · `scoring_success` · `scoring_error`

**data in**
```dart
WritingFeedback {
  attemptId, overallScore: int,
  metrics: { grammar: int, vocabulary: int, coherence: int, taskAchievement: int },
  grammarNotes: List<FeedbackNote { text, annotation }>,
  vocabularyNotes: List<FeedbackNote>,
  correctedEssay: String,
  processingStatus: 'processing' | 'ready' | 'error',
}
```

---

## S14 · Leaderboard

| | |
|---|---|
| **Route** | `/leaderboard` |
| **file** | `features/leaderboard/screens/leaderboard_screen.dart` |
| **module** | `leaderboard` |
| **auth** | authenticated |

**Components**
- `LeaderboardTabBar` — Weekly / All-time
- `TopThreePodium` — 1st/2nd/3rd with avatars + scores
- `LeaderboardList` — `WeeklyLeaderboardRow` × N
- `OwnRankStickyCard` — fixed to bottom, always visible

**Provider** — `leaderboardProvider`

**State variants**: loading · success · empty (first week) · error

---

## S15 · Progress

| | |
|---|---|
| **Route** | `/progress` |
| **file** | `features/progress/screens/progress_screen.dart` |
| **module** | `progress` |
| **auth** | authenticated |

**Components**
- `SkillRadarChart` — Reading / Listening / Writing / Speaking axes
- `StreakCalendarHeatmap` — last 30 days
- `MockTestHistoryList` — date + score per attempt
- `CourseProgressSection` — per-module completion bars
- `TotalStatsRow` — total XP · lessons · study days

**Provider** — `progressProvider`

---

## S16 · Notification Settings

| | |
|---|---|
| **Route** | `/settings/notifications` |
| **file** | `features/notifications/screens/notification_settings_screen.dart` |
| **module** | `notifications` |
| **auth** | authenticated |

**Components**
- `AppToggle` — enable daily reminder
- `TimePickerField` — reminder hour
- `NotificationPreviewText` — "Nhắc học lúc 20:00 mỗi ngày"
- `SaveButton`

**Provider** — `notificationPrefsNotifierProvider`

**data in/out**
```dart
NotificationPrefs { enabled: bool, reminderHour: int, timezone: String }
```
Supabase: `PATCH profiles SET notification_prefs = {...}`

---

## S17 · Profile

| | |
|---|---|
| **Route** | `/profile` |
| **file** | `features/profile/screens/profile_screen.dart` |
| **module** | `profile` |
| **auth** | authenticated |

**Components**
- `ProfileAvatarHeader` — avatar + display name + role badge
- `StatsRow` — streak · XP · rank
- `ActiveCourseChip`
- `SettingsMenuList`:
  - → `/settings/notifications`
  - → Subscription/upgrade (Phase 2)
  - Logout action → `authNotifier.signOut()`

**Provider** — `currentUserProvider`

---

## S18 · Teacher Feedback

| | |
|---|---|
| **Route** | `/teacher-feedback/:reviewId` |
| **file** | `features/teacher_feedback/screens/teacher_feedback_screen.dart` |
| **module** | `teacher_feedback` |
| **auth** | authenticated |

**Components**
- `TeacherReviewHeader` — date · reviewer name · submission type
- `ScoreSummaryCard`
- `TeacherCommentList` — `TeacherCommentCard` per comment (text + timestamp)
- `SubmissionPreviewPanel` — original learner audio/text snippet
- `BackToLessonButton`

**Provider** — `teacherFeedbackProvider(reviewId)`

**data in**
```dart
TeacherReview {
  reviewId, reviewerName, submittedAt, score: int,
  comments: List<TeacherComment { body, createdAt }>,
  submissionType: 'speaking' | 'writing',
  submissionRef: String,
}
```
