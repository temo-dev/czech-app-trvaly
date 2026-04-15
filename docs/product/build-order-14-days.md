# 14-Day Frontend Build Order — Trvalý Prep MVP
> Flutter Web + iOS
> Each day = ~6h focused engineering time
> Output = shippable increment, not just code

---

## Pre-start checklist
- [ ] Supabase project created (dev + prod)
- [ ] `env.dev.json` filled with real dev keys
- [ ] Be Vietnam Pro font files in `assets/fonts/`
- [ ] Flutter 3.24+ installed
- [ ] Stitch design exported / accessible for reference

---

## Day 1 — Scaffold + Shell
**Goal**: App boots, routes work, shell renders on web and iOS

**Tasks**
- [ ] `flutter pub get` — confirm no version conflicts
- [ ] Run `make gen` — freezed + Riverpod codegen passes
- [ ] Verify `AppEnv.validate()` asserts on missing keys
- [ ] Wire `app.dart` → `AppTheme.light/dark` + `AppLocalizations`
- [ ] Confirm GoRouter boots to `/` and redirects to `/dashboard` if authed (use hardcoded mock)
- [ ] `AppShell` renders on Chrome: side rail visible at ≥ 900px, bottom nav at < 900px
- [ ] `AppShell` renders on iOS simulator: bottom nav tabs tap without crash

**Files touched**
- `lib/app.dart`
- `lib/main_dev.dart`
- `lib/core/router/app_router.dart`
- `lib/features/shell/app_shell.dart`
- `lib/features/shell/widgets/bottom_nav_bar.dart`
- `lib/features/shell/widgets/side_rail_nav.dart`

**Acceptance criteria**
- `make run-web-dev` → landing screen renders without error
- Tap each of 5 nav tabs → URL changes correctly in Chrome address bar
- On iOS → no layout overflow in shell

---

## Day 2 — Design System + Shared Widgets
**Goal**: Token-backed theme, all shared utility widgets built and manually verified

**Tasks**
- [ ] Verify `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius` in `ThemeData`
- [ ] Build a temporary `/design-system` debug route that renders all widgets below (remove later)
- [ ] `PrimaryButton` / `SecondaryButton` / `LoadingButton` — all three variants
- [ ] `AppTextField` + `PasswordField` with show/hide toggle
- [ ] `EmptyStateCard` + `ErrorStateCard` + `ShimmerCardList`
- [ ] `ProgressRing` — animated at values 0.0 / 0.5 / 1.0
- [ ] `ScoreBadge` — four colour bands
- [ ] `TagChip` — three variants
- [ ] `StreakBadge`, `PointsBadge`
- [ ] `StickyBottomCTA`
- [ ] `OfflineBanner` (static render OK; connectivity wire later)
- [ ] `AppToggle`, `TimePickerField`

**Acceptance criteria**
- All widgets render without overflow on 375px iPhone width
- All widgets render without overflow on 1440px Chrome width
- Dark mode: all widgets readable (no white-on-white)
- `PrimaryButton` shows spinner when `isLoading: true`

---

## Day 3 — Auth Flow
**Goal**: Working login, signup, logout, forgot password

**Tasks**
- [ ] `LoginScreen` — form + Supabase `signInWithPassword` → dashboard redirect
- [ ] `SignupScreen` — form + `signUp` + profile row insert → dashboard redirect
- [ ] `ForgotPasswordScreen` — email field + `resetPasswordForEmail`
- [ ] `authNotifierProvider` with `AuthFormState` + error handling
- [ ] `currentUserProvider` with session restore on app start
- [ ] GoRouter auth redirect: `/dashboard` if session exists, `/auth/login` if not
- [ ] `?from=` param preserved through login redirect
- [ ] Logout from profile stub → session cleared → redirect to `/`

**Supabase setup required**
- `profiles` table with RLS
- `handle_new_user` trigger (insert profile on auth.users create)

**Acceptance criteria**
- Sign up with new email → profile row created in Supabase
- Login → session persisted; reload browser tab → still logged in
- Logout → `/` landing page; protected routes redirect to login
- Invalid email/password → inline error shown, no crash

---

## Day 4 — Landing Page + Mock Test Intro
**Goal**: The acquisition funnel top half works for a guest user

**Tasks**
- [ ] `LandingScreen` — hero + skill grid + testimonials + FAQ + `StickyBottomCTA`
- [ ] Responsive: 2-column hero on web, single column on mobile
- [ ] `MockTestIntroScreen` — fetch `ExamMeta` from Supabase, render info, button creates attempt
- [ ] `mockExamMetaProvider` — `AsyncValue<ExamMeta>`
- [ ] POST `create-exam-attempt` edge function call (or direct insert for MVP)
- [ ] Navigation: Landing → MockTestIntro → session screen (stub OK)
- [ ] `EmptyStateCTA` on landing if API fails (offline-safe)

**Acceptance criteria**
- Guest visits `/` → sees landing
- Taps CTA → `/mock-test/intro` → sees exam info
- Taps start → attempt row created in `exam_attempts` → route to `/mock-test/session/:id`

---

## Day 5 — Exam Simulator Shell
**Goal**: Timer, question navigation, autosave, section transitions all work. No question rendering yet.

**Tasks**
- [ ] `ExamSessionScreen` — full screen, no AppShell nav bar
- [ ] `ExamTopBar` — section label + `ExamTimer` (countdown) + autosave dot
- [ ] `ExamTimer` ticks from server-provided `remainingSeconds`
- [ ] `examTimerProvider` — ticks every second, triggers auto-submit at 0
- [ ] `QuestionProgressBar` — answered/total updates on answer
- [ ] `QuestionNavigationPanel` — bottom sheet (mobile) / right panel (web)
- [ ] `SectionTransitionCard` — full-screen between sections
- [ ] `ConfirmSubmitDialog` — shows unanswered count
- [ ] `AutosaveIndicator` states: idle / saving / saved / failed
- [ ] Local answer buffering in `shared_preferences` when autosave fails
- [ ] Back button → `ConfirmExitDialog`

**Acceptance criteria**
- Timer counts down visually; at 0 submit dialog fires
- Answer a question → progress bar updates immediately (optimistic)
- Kill network → autosave shows failed state; answers not lost
- Section transition card appears between sections 1→2, 2→3

---

## Day 6 — Question Renderer Types
**Goal**: All 6 question types render and accept answers. Correct/wrong feedback shown.

**Tasks**
- [ ] `McqExercise` — tap option, highlight selected, lock after submit
- [ ] `McqOptionTile` — 4 states: idle / selected / correct / incorrect
- [ ] `FillBlankExercise` — inline text inputs in sentence
- [ ] `ListeningExercise` — `AudioPlayerBar` + MCQ below
- [ ] `ReadingPassageExercise` — scrollable passage left, MCQ right (web) / stacked (mobile)
- [ ] `WritingInputExercise` — `WritingTextArea` with word count
- [ ] `SpeakingRecorderExercise` — record button + waveform (recording wired Day 11)
- [ ] `ExplanationPanel` — slides up after submit with correct answer + explanation text
- [ ] `QuestionShell` — dispatcher: selects correct renderer by `exercise.type`
- [ ] Wire into exam session: answers stored in `examSessionNotifier.currentAnswers`

**Acceptance criteria**
- All 6 types render without crash on 375px iPhone
- MCQ: tap option → highlighted; tap different → switches; submit → correct/incorrect shown
- Listening: audio plays; MCQ below selectable
- Writing: word count increments; over-limit highlighted

---

## Day 7 — Exam Submit + Result Page + Anonymous Linking
**Goal**: Complete free mock test funnel works end-to-end

**Tasks**
- [ ] `submit-exam-attempt` edge function call → returns `resultId`
- [ ] `ExamResultScreen` — score ring + skill bars + weak skills + CTA section
- [ ] `examResultProvider(attemptId)` — fetch result
- [ ] `TotalScoreHero` — animated ring filling to score on mount
- [ ] `SkillBreakdownChart` — 4 horizontal bars
- [ ] `WeakSkillsList` — chip row
- [ ] `RecommendationCard` — "Bắt đầu với Listening Module 1"
- [ ] `ResultCTASection` — if anonymous → `SignupToSaveCTA`; if auth → `StartLearningCTA`
- [ ] Anonymous result linking: `pendingAttemptId` stored in prefs on result screen; cleared after signup PATCH

**Acceptance criteria**
- Full flow: `/` → intro → exam (skip most questions) → submit → result shows
- Guest → signup → result linked to new user (verify in Supabase)
- Result page shareable URL works (loads result for any user)

---

## Day 8 — Dashboard
**Goal**: Authenticated home screen loads real data

**Tasks**
- [ ] `dashboardProvider` — compose latest result + recommendation + streak + XP + leaderboard preview
- [ ] `DashboardScreen` — all cards laid out, responsive grid on web
- [ ] `DailyGreetingHeader` — user name + exam countdown chip
- [ ] `LatestResultCard` — loads from `exam_results`
- [ ] `RecommendedLessonCard` — static recommendation for MVP (first lesson of weakest module)
- [ ] `StreakCard` — shows `streakDays` from profile
- [ ] `PointsCard` — shows `totalXp` + `weeklyRank`
- [ ] `LeaderboardPreviewCard` — top 3 + own rank
- [ ] `EmptyResultBanner` → "Làm bài thi thử đầu tiên của bạn"
- [ ] `CourseProgressCard` (stub OK: hardcoded course slug for now)

**Acceptance criteria**
- Fresh user → `EmptyResultBanner` shows; "Start mock test" taps to `/mock-test/intro`
- User with result → result card shows correct score
- Streak = 2 → StreakCard shows flame + "2 ngày"

---

## Day 9 — Course + Module + Lesson Structure
**Goal**: Learner can navigate course hierarchy and see lesson list

**Tasks**
- [ ] `CourseOverviewScreen` — `courseDetailProvider(slug)` → header + module list
- [ ] `ModuleCard` — progress ring + lesson count + locked overlay
- [ ] `ModuleDetailScreen` — `moduleDetailProvider(id)` → lesson list
- [ ] `LessonListTile` — status icon (lock/circle/check)
- [ ] `LessonDetailScreen` — `lessonDetailProvider(id)` → 6 block cards
- [ ] `LessonBlockCard` — block type icon + status + "Bắt đầu" CTA
- [ ] `ExerciseProgressFooter` — "3 / 6 hoàn thành"
- [ ] `BonusUnlockSection` — shown disabled until 6/6 done
- [ ] `BreadcrumbBar` (web only): Course → Module → Lesson
- [ ] Mark lesson block complete when exercise attempt submitted: `user_progress` upsert

**Acceptance criteria**
- Navigate: Dashboard → Course → Module → Lesson
- Completed blocks show checkmark icon
- 6/6 done → `BonusUnlockSection` becomes active

---

## Day 10 — Practice Exercise Flow
**Goal**: Full practice session works for non-AI exercise types

**Tasks**
- [ ] `PracticeScreen` — loads exercise by `:exerciseId`, renders via `QuestionShell`
- [ ] `practiceSessionNotifierProvider` — loads, submits, awards XP
- [ ] Wire MCQ, FillBlank, Listening, Reading, Writing types to practice
- [ ] `ExplanationPanel` animates in after correct/incorrect
- [ ] POST `exercise_attempts` on submit → get `isCorrect + xpAwarded`
- [ ] `xpNotifierProvider` — optimistic local XP update
- [ ] `streakProvider` — update `lastActivityDate` → recalculate streak
- [ ] Navigate back to lesson after exercise: `context.pop()` → lesson updates block status

**Acceptance criteria**
- Complete a reading MCQ → explanation shows → XP awarded → block marked done
- Complete wrong answer → marked incorrect, explanation shows, retry available
- XP in `PointsCard` on dashboard reflects new total after lesson

---

## Day 11 — Speaking Recording UI
**Goal**: Microphone permission, recording, waveform, upload to S3 — no AI yet

**Tasks**
- [ ] `SpeakingRecorderExercise` — full UI (prompt + record button + waveform + controls)
- [ ] `speakingSessionNotifierProvider` state machine
- [ ] Mic permission request (iOS: `NSMicrophoneUsageDescription` in `Info.plist`)
- [ ] `WaveformVisualizer` — amplitude bars during recording
- [ ] Record → review → discard or submit
- [ ] `speaking-upload` edge function call → returns `{ attemptId, audioKey }`
- [ ] On upload success → `context.push(AppRoutes.speakingFeedback(attemptId))`
- [ ] Interim "scoring in progress" state on feedback screen

**Acceptance criteria**
- iOS: tap mic → permission dialog → recording starts → waveform animates
- Web: Chrome mic access works; waveform animates
- Upload completes → feedback screen shows "Đang chấm điểm..." state

---

## Day 12 — AI Feedback Screens (Speaking + Writing)
**Goal**: Both feedback screens render real AI output

**Tasks**
- [ ] `speakingFeedbackProvider` — polls `speaking-result/:id` every 3s; max 10 retries
- [ ] `SpeakingFeedbackScreen` — full UI with all metric cards + transcript + corrections
- [ ] `TranscriptBlock` — word-level issues highlighted
- [ ] `WritingInputExercise` → submit text → `writing-submit` edge function
- [ ] `writingFeedbackProvider` — polls `writing-result/:id`
- [ ] `WritingFeedbackScreen` — metrics + `AnnotatedEssayPanel` + corrections
- [ ] `CorrectedAnswerPanel` — AI-improved version shown below
- [ ] Error state: scoring timeout → `scoringError` → "Thử lại" button
- [ ] If AI services unavailable → use `mockFeedbackData` stub (flag in `AppEnv.isDev`)

**Acceptance criteria**
- Speaking: submit audio → poll → result renders within 15s on dev
- Writing: submit text → poll → annotated essay renders
- Both: retry button works when in error state

---

## Day 13 — Retention Screens
**Goal**: Leaderboard, Progress, Notifications, Profile, Teacher Feedback all functional

**Tasks**
- [ ] `LeaderboardScreen` — weekly/all-time tabs + podium + list + own rank sticky
- [ ] `leaderboardProvider` — fetch `leaderboard_weekly` view
- [ ] `ProgressScreen` — `SkillRadarChart` + `StreakCalendarHeatmap` + exam history list
- [ ] `progressProvider` — aggregated from `user_progress` + `exam_attempts`
- [ ] `ProfileScreen` — user info + stats row + settings menu
- [ ] `NotificationSettingsScreen` — toggle + time picker + save
- [ ] `notificationPrefsNotifierProvider` — PATCH `profiles.notification_prefs`
- [ ] `TeacherFeedbackScreen` — fetch `teacher_reviews` + `teacher_comments`
- [ ] `teacherFeedbackProvider(reviewId)`

**Acceptance criteria**
- Leaderboard: own rank row is highlighted; weekly tab shows different data from all-time
- Progress: radar chart arms match skill scores from exam result
- Notifications: toggle on/off persists after app restart
- Teacher feedback: comment list renders; submission preview shown

---

## Day 14 — Polish, States, QA Pass
**Goal**: Pilot-ready. Every screen handles all state variants. No crashes. Design consistent.

**Tasks**

**Loading states**
- [ ] Every data-fetching screen shows shimmer skeleton (not spinner)
- [ ] Exam session: `ExamTopBar` skeleton during `initializing` state
- [ ] Dashboard: `DashboardSkeleton` — placeholder for each card

**Error states**
- [ ] Every `AsyncError` → `ErrorStateCard` with retry that calls `.refresh()`
- [ ] Network down mid-exam → `OfflineBanner` + autosave fallback activates
- [ ] AI polling timeout → `scoringError` state + retry option

**Empty states**
- [ ] Leaderboard first week → empty state with "Trở thành người đầu tiên" copy
- [ ] No teacher feedback → empty state
- [ ] Progress with no exam → empty chart with prompt

**Design consistency pass**
- [ ] All typography uses `AppTypography.*` styles — no raw `fontSize` in widgets
- [ ] All spacing uses `AppSpacing.*` — no raw numbers in padding
- [ ] All border radii use `AppRadius.*`
- [ ] Dark mode: spot-check 10 screens, fix any invisible text

**Cross-platform check**
- [ ] All screens: iOS Safari (web) — no scroll issues, no keyboard overlap
- [ ] All screens: iOS simulator — safe area insets respected
- [ ] All screens: 1440px Chrome — max-width container centred, no full-bleed text

**Acceptance criteria for pilot readiness**
- [ ] Full mock test funnel works: guest → exam → result → signup → dashboard
- [ ] Full lesson flow: dashboard → course → module → lesson → exercise → AI feedback
- [ ] Leaderboard, Progress, Profile, Notifications all load without crash
- [ ] No `print()` statements in production code
- [ ] `flutter analyze` passes with 0 errors

---

## Dependency map

```
Day 1 ──→ Day 2 ──→ Day 3
                       │
                       ├──→ Day 4 ──→ Day 5 ──→ Day 6 ──→ Day 7
                       │
                       └──→ Day 8 ──→ Day 9 ──→ Day 10
                                                    │
                                         Day 11 ──→ Day 12
                                         Day 13 (parallel with 11–12)
                                         Day 14 (final, depends on all)
```

---

## Risk register

| Risk | Mitigation |
|------|-----------|
| AI service not ready by Day 12 | Mock feedback JSON in `AppEnv.isDev`; screens still testable |
| Supabase edge functions complex | Use direct table inserts for MVP; refactor to functions after |
| iOS mic permission rejection | Test on real device Day 11; not simulatable on web |
| GoRouter web back button | Use `canPop` guard on exam session screen Day 5 |
| Anonymous → auth linking race | Lock PATCH to `userId IS NULL AND created_at > now() - interval '24h'` in RLS |
