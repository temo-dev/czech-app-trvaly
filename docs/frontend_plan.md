# Frontend Implementation Plan — Czech Trvalý Exam Prep App
> Platform: Flutter Web + iOS  
> Language priority: Vietnamese-first (i18n from day 1)  
> Generated: 2026-04-08

---

## 1. Screen Inventory

| ID | Screen | Module | Description |
|----|--------|--------|-------------|
| S01 | Landing / Home (guest) | `landing` | Hero, value prop, CTA to register / try free test |
| S02 | Free Mock Test — Intro | `mock_test` | Rules, time limit, section overview before starting |
| S03 | Free Mock Test — Question | `mock_test` | Single-question view; timer; MCQ / fill-in / audio |
| S04 | Free Mock Test — Review | `mock_test` | Flag & navigate between questions before submit |
| S05 | Free Mock Test — Result | `result` | Score breakdown, section scores, CTA to upgrade |
| S06 | Sign Up | `auth` | Email + password or social (Google/Apple) |
| S07 | Log In | `auth` | Email / social login |
| S08 | Forgot Password | `auth` | Email entry → reset link sent |
| S09 | Reset Password | `auth` | New password form (deep-link entry) |
| S10 | Onboarding Wizard | `onboarding` | Goal, exam date, daily study minutes (3 steps) |
| S11 | Dashboard | `dashboard` | Streak, daily goal ring, quick-access modules, recent activity |
| S12 | Course Catalog | `course` | List of all courses/skill areas |
| S13 | Course Detail | `course` | Module list, progress bar, unlock state |
| S14 | Module Detail | `course` | Lesson list with completion badges |
| S15 | Lesson Player | `course` | Content viewer: text / video / audio / PDF embed |
| S16 | Exercise Practice — Intro | `exercise` | Skill filter (Reading / Listening / Writing / Speaking / Vocabulary / Grammar), difficulty picker |
| S17 | Exercise Practice — Question | `exercise` | Question render; MCQ, fill-in-blank, matching, ordering |
| S18 | Exercise Practice — Explanation | `exercise` | Post-answer explanation with correct answer highlight |
| S19 | Exam Simulator — Intro | `simulator` | Full-exam setup: timed, all sections, real conditions |
| S20 | Exam Simulator — Section Transition | `simulator` | Between-section countdown / instructions |
| S21 | Exam Simulator — Question | `simulator` | Same renderer as exercise but locked navigation until time |
| S22 | Exam Simulator — Result | `result` | Full score report, section breakdown, time per question |
| S23 | Result Detail / Answer Review | `result` | Per-question review with explanations |
| S24 | Speaking AI — Prompt | `speaking_ai` | Prompt display + record button |
| S25 | Speaking AI — Recording | `speaking_ai` | Waveform visualizer, stop/cancel |
| S26 | Speaking AI — Feedback | `speaking_ai` | Transcript, pronunciation score, fluency score, suggestions |
| S27 | Writing AI — Prompt | `writing_ai` | Task prompt + text editor |
| S28 | Writing AI — Feedback | `writing_ai` | Annotated essay, scores (coherence, grammar, vocabulary) |
| S29 | Leaderboard | `leaderboard` | Weekly / all-time tabs; top-N list; own rank card |
| S30 | Progress / Analytics | `progress` | Skill radar, streak calendar, weak areas, time studied |
| S31 | Notifications Center | `notifications` | List of system + teacher + milestone notifications |
| S32 | Teacher Feedback — Inbox | `teacher_feedback` | Threads list (writing/speaking submissions) |
| S33 | Teacher Feedback — Thread | `teacher_feedback` | Chat-style view of submission + teacher comments |
| S34 | Profile | `profile` | Avatar, display name, exam date, stats summary |
| S35 | Settings | `profile` | Language, notifications, subscription, account actions |
| S36 | Subscription / Paywall | `subscription` | Plan comparison, CTA, pricing (web: Stripe; iOS: IAP) |
| S37 | Error / Offline | `shell` | Generic error boundary + offline banner |
| S38 | Splash / Bootstrap | `shell` | App init, auth token check |

---

## 2. Route Map

Uses **GoRouter** with nested `ShellRoute` for bottom-nav scaffold.

```
/                               → S38 Splash (redirect logic)
/landing                        → S01 Landing
/auth
  /login                        → S07 Log In
  /signup                       → S06 Sign Up
  /forgot-password              → S08 Forgot Password
  /reset-password               → S09 Reset Password  [deep link: ?token=]
/onboarding                     → S10 Onboarding Wizard
/mock-test
  /intro                        → S02 Free Mock Test Intro
  /question/:index              → S03 Free Mock Test Question
  /review                       → S04 Free Mock Test Review
  /result                       → S05 Free Mock Test Result

# Shell (bottom nav: Dashboard | Learn | Practice | Progress | Profile)
/app [ShellRoute]
  /dashboard                    → S11 Dashboard
  /courses                      → S12 Course Catalog
    /:courseId                  → S13 Course Detail
      /modules/:moduleId        → S14 Module Detail
        /lessons/:lessonId      → S15 Lesson Player
  /practice
    /intro                      → S16 Exercise Practice Intro
    /question/:index            → S17 Exercise Practice Question
    /explanation                → S18 Exercise Practice Explanation
  /simulator
    /intro                      → S19 Exam Simulator Intro
    /transition/:section        → S20 Section Transition
    /question/:index            → S21 Simulator Question
    /result                     → S22 Simulator Result
      /review                   → S23 Answer Review
  /speaking
    /prompt                     → S24 Speaking Prompt
    /recording                  → S25 Speaking Recording
    /feedback                   → S26 Speaking Feedback
  /writing
    /prompt                     → S27 Writing Prompt
    /feedback                   → S28 Writing Feedback
  /leaderboard                  → S29 Leaderboard
  /progress                     → S30 Progress Analytics
  /notifications                → S31 Notifications
  /teacher
    /inbox                      → S32 Teacher Feedback Inbox
    /thread/:threadId           → S33 Teacher Feedback Thread
  /profile                      → S34 Profile
    /settings                   → S35 Settings
  /subscribe                    → S36 Subscription / Paywall

/error                          → S37 Error / Offline
```

**Guards:**
- `/app/**` → requires `AuthGuard` (redirect to `/auth/login`)
- `/mock-test/**` → `GuestOrAuthGuard` (allowed without login, capped at 1 attempt)
- `/app/simulator/**`, `/app/speaking/**`, `/app/writing/**` → `SubscriptionGuard` (redirect to `/app/subscribe`)
- `/onboarding` → fires once post-signup, stored in user preferences

---

## 3. Component Inventory

### 3a. Navigation & Shell
| Component | Description |
|-----------|-------------|
| `AppShell` | Responsive shell: bottom nav (mobile) ↔ side rail (web ≥ 900px) |
| `BottomNavBar` | 5-tab bar with active indicators and notification badge |
| `SideRailNav` | Collapsible left rail for web |
| `AppTopBar` | Context-aware title, back arrow, action icons |
| `BreadcrumbBar` | Web-only; course → module → lesson path |

### 3b. Question Rendering
| Component | Description |
|-----------|-------------|
| `QuestionCard` | Container: question text + media + answer area |
| `McqOptionTile` | Single-choice or multi-choice option with state (idle/selected/correct/wrong) |
| `FillBlankField` | Inline text input within a sentence |
| `MatchingGrid` | Left/right column drag-connect or tap-select |
| `OrderingList` | Drag-to-reorder list |
| `AudioPlayerWidget` | Play/pause/scrub bar for listening questions |
| `ImageZoomable` | Pinch-zoom image for reading exhibits |
| `QuestionTimer` | Circular countdown (per-question or section) |
| `QuestionProgressBar` | Linear indicator: answered / flagged / remaining |
| `FlagButton` | Toggle flag on question for review |
| `NavigatorDrawer` | Grid of question numbers with status dots (review screen) |
| `ExplanationPanel` | Expandable panel with correct answer and rationale |

### 3c. Course & Lesson
| Component | Description |
|-----------|-------------|
| `CourseCard` | Thumbnail + title + progress ring + lock overlay |
| `ModuleListTile` | Module row with lesson count + completion badge |
| `LessonListTile` | Lesson row with type icon (video/text/audio) + done checkmark |
| `LessonContentViewer` | Switches: `MarkdownView` / `VideoPlayer` / `AudioLesson` / `PdfViewer` |
| `ProgressRing` | Animated circular progress widget (reused across app) |
| `LockedOverlay` | Blur + lock icon + "Upgrade" CTA over locked content |

### 3d. AI Feedback
| Component | Description |
|-----------|-------------|
| `RecordButton` | Large mic FAB with press-and-hold / tap-to-toggle |
| `WaveformVisualizer` | Real-time amplitude bars during recording |
| `TranscriptBlock` | Word-highlighted transcript with pronunciation issues underlined |
| `ScoreBadge` | Circular score chip (0–100, color-coded) |
| `FeedbackAnnotation` | Inline text annotation (writing: hover/tap to reveal comment) |
| `WritingEditor` | Multi-line text field with word count and character limit |
| `AIFeedbackCard` | Structured card: criterion name + score + explanation |

### 3e. Progress & Gamification
| Component | Description |
|-----------|-------------|
| `StreakCounter` | Flame icon + day count |
| `DailyGoalRing` | Large animated ring + XP today / goal |
| `SkillRadarChart` | 4–6 axis radar (Reading/Listening/Writing/Speaking/Vocab/Grammar) |
| `CalendarHeatmap` | Monthly grid colored by study activity |
| `WeakAreaChip` | Tag chip linking to targeted practice |
| `LeaderboardTile` | Rank number + avatar + name + score |
| `OwnRankCard` | Sticky bottom card showing user's own rank |
| `AchievementBadge` | Unlocked/locked badge with tooltip |

### 3f. Auth & Onboarding
| Component | Description |
|-----------|-------------|
| `EmailPasswordForm` | Validated email + password fields with show/hide |
| `SocialAuthButton` | Google / Apple branded button |
| `OnboardingStepIndicator` | Dot or numbered stepper |
| `ExamDatePicker` | Calendar date picker scoped to future dates |
| `DailyGoalSlider` | Slider: 5 / 10 / 20 / 30 min presets |

### 3g. Notifications & Feedback
| Component | Description |
|-----------|-------------|
| `NotificationTile` | Icon + title + body + timestamp + read dot |
| `TeacherMessageBubble` | Chat bubble (teacher vs student variant) |
| `SubmissionPreviewCard` | Linked speaking/writing snippet in thread |

### 3h. Subscription
| Component | Description |
|-----------|-------------|
| `PlanCard` | Monthly vs annual card with feature list + CTA |
| `FeatureComparisonRow` | Free / Premium columns with check/cross |
| `PurchaseButton` | Platform-adaptive: Stripe Checkout (web), StoreKit (iOS) |

### 3i. Shared Utility
| Component | Description |
|-----------|-------------|
| `EmptyState` | Illustration + heading + optional CTA |
| `ErrorState` | Icon + message + retry button |
| `LoadingShimmer` | Skeleton placeholder matching component shape |
| `SnackBarMessage` | Success / warning / error toasts |
| `ConfirmDialog` | Two-button alert dialog |
| `BottomSheet` | Modal sheet used for filters, share, actions |
| `TagChip` | Pill chip with color variants (skill, difficulty, status) |
| `SectionHeader` | Section title + optional "see all" link |
| `AvatarWidget` | Circular avatar with fallback initials |

---

## 4. Shared Design System Inventory

### 4a. Color Tokens
```dart
// Brand
colorPrimary        // Czech flag red #D7141A
colorSecondary      // Deep navy #1A2D5A
colorAccent         // Gold / XP yellow #F5A623

// Semantic
colorSuccess        // #27AE60
colorWarning        // #F39C12
colorError          // #E74C3C
colorInfo           // #2980B9

// Surface
colorBackground     // #F8F9FC (light) / #0F1117 (dark)
colorSurface        // #FFFFFF / #1C1F2A
colorSurfaceVariant // #F0F2F7 / #252836
colorBorder         // #E2E8F0 / #2E3347
colorScrim          // rgba(0,0,0,0.5)

// Text
colorOnBackground   // #111827 / #F1F5F9
colorOnSurface      // #374151 / #CBD5E1
colorOnSurfaceMuted // #9CA3AF / #64748B
colorOnPrimary      // #FFFFFF
```

### 4b. Typography
```dart
// Font: Be Vietnam Pro (Latin + Vietnamese support)
// Fallback: system-ui

displayLarge    // 57sp / -0.25 / W700
displayMedium   // 45sp / 0    / W700
headlineLarge   // 32sp / 0    / W700
headlineMedium  // 28sp / 0    / W600
headlineSmall   // 24sp / 0    / W600
titleLarge      // 22sp / 0    / W600
titleMedium     // 16sp / +0.15/ W500
titleSmall      // 14sp / +0.1 / W500
bodyLarge       // 16sp / +0.5 / W400
bodyMedium      // 14sp / +0.25/ W400
bodySmall       // 12sp / +0.4 / W400
labelLarge      // 14sp / +0.1 / W500  ← buttons
labelMedium     // 12sp / +0.5 / W500
labelSmall      // 11sp / +0.5 / W500
```

### 4c. Spacing Scale
```dart
// 4px base grid
space4   = 4.0
space8   = 8.0
space12  = 12.0
space16  = 16.0
space20  = 20.0
space24  = 24.0
space32  = 32.0
space40  = 40.0
space48  = 48.0
space64  = 64.0

// Semantic aliases
pagePaddingH    = space16 (mobile) / space24 (tablet) / space40 (web)
cardPadding     = space16
sectionGap      = space32
itemGap         = space12
```

### 4d. Elevation & Radius
```dart
// Border Radius
radiusXS = 4.0
radiusSM = 8.0
radiusMD = 12.0
radiusLG = 16.0
radiusXL = 24.0
radiusFull = 999.0  // pill

// Elevation (Material 3)
elevationLevel0 = 0
elevationLevel1 = 1   // cards
elevationLevel2 = 3   // raised buttons
elevationLevel3 = 6   // drawers, side sheets
elevationLevel4 = 8   // modals, dialogs
elevationLevel5 = 12  // floating elements
```

### 4e. Icon Set
- Primary: **Material Symbols** (variable font, rounded style)
- Supplemental: custom SVG for Czech-specific imagery (flag, Prague, etc.)
- AI badge icons: mic, pen, robot — custom 24×24 SVGs

### 4f. Motion & Animation
```dart
durationFast    = 150ms   // micro interactions (button press)
durationMedium  = 300ms   // page transitions, card expand
durationSlow    = 500ms   // onboarding, result reveal
durationXSlow   = 800ms   // score count-up animation

curveStandard   = Curves.easeInOut
curveDecelerate = Curves.decelerate    // elements entering
curveAccelerate = Curves.easeIn        // elements leaving
curveSpring     = SpringDescription(mass: 1, stiffness: 180, damping: 20)
```

### 4g. Breakpoints (Adaptive Layout)
```dart
mobile   < 600px   → bottom nav, single column
tablet   600–900px → bottom nav, 2-column grid
web      > 900px   → side rail, max-width 1200px centered
```

### 4h. Localization Tokens
- All user-facing strings via `AppLocalizations` (arb files)
- Locales: `vi` (primary), `cs`, `en`
- RTL: not required (all target languages LTR)
- Date/number formatting: `intl` package with locale-aware formatters

---

## 5. State Variants per Screen

| Screen | Loading | Empty | Error | Populated | Edge Cases |
|--------|---------|-------|-------|-----------|------------|
| S01 Landing | Shimmer hero | — | Offline banner | Full hero + CTAs | Guest vs returning user variant |
| S02–S04 Mock Test | Question shimmer | — | Network error + resume prompt | Question active | Timer paused (backgrounded), 0 questions remaining |
| S05 Mock Test Result | Score calculating animation | — | Submission failed + retry | Score cards | First-time (celebration) vs repeat attempt |
| S07 Log In | Button loading spinner | — | Wrong credentials, account locked | Form idle | Biometric unlock (iOS) |
| S10 Onboarding | — | — | Save failed | Step 1/2/3 | Skip button (optional exam date) |
| S11 Dashboard | Skeleton layout | First day (no data) | Offline cached | Streak active/broken, goal met/not met | Subscription expired banner |
| S12 Course Catalog | Shimmer grid | No courses available | Fetch error | Grid of courses | Locked (free user) overlay on premium courses |
| S13 Course Detail | Shimmer list | — | Fetch error | Module list | All completed (celebration state), locked modules |
| S15 Lesson Player | Content loading | — | Load failed + retry | Content rendered | Offline-saved lesson, video buffering |
| S16–S18 Exercise | Question loading | No exercises for filter | Fetch error | Question active | All exercises completed for difficulty |
| S19–S22 Simulator | Loading sections | — | Start failed | Exam active | Time's up auto-submit, backgrounded → paused |
| S24–S26 Speaking AI | Mic permission request | — | STT/AI timeout | Recording / processing / feedback | No mic hardware (web fallback), low audio |
| S27–S28 Writing AI | — | — | AI timeout, submission failed | Editor / feedback | Word limit exceeded, empty submission |
| S29 Leaderboard | Shimmer list | No scores yet | Fetch error | Ranked list | User not on list (rank card shows N/A) |
| S30 Progress | Skeleton charts | No activity yet | Fetch error | Charts populated | Date range empty, all skills at 0 |
| S31 Notifications | Shimmer list | All caught up (zero state) | Fetch error | List with unread badges | Real-time new notification arrival |
| S32–S33 Teacher Feedback | Thread loading | No submissions yet | — | Thread list / chat view | Awaiting review (no reply yet), teacher typing indicator |
| S34 Profile | Shimmer | — | Update failed | Profile data | Avatar upload in-progress |
| S36 Subscription | Loading plans | — | Price fetch error | Plan cards | Restore purchase, already subscribed redirect |

---

## 6. Feature Module Ownership

```
lib/
├── core/
│   ├── router/          # GoRouter config, guards
│   ├── theme/           # Design tokens, ThemeData
│   ├── l10n/            # ARB files, AppLocalizations
│   ├── network/         # Dio client, interceptors, error models
│   ├── storage/         # SecureStorage, SharedPreferences wrappers
│   └── utils/           # Date helpers, validators, extensions
│
├── shared/
│   ├── widgets/         # All §3i shared utility components
│   ├── models/          # Shared domain models (User, Score, Question)
│   └── services/        # Auth service, Analytics, Push notification
│
└── features/
    ├── shell/            # S37 Error, S38 Splash, AppShell, BottomNavBar
    ├── landing/          # S01
    ├── auth/             # S06–S09
    ├── onboarding/       # S10
    ├── dashboard/        # S11
    ├── course/           # S12–S15  (CourseCard, LessonPlayer)
    ├── exercise/         # S16–S18  (QuestionCard, all question widgets)
    ├── mock_test/        # S02–S04  (reuses exercise widgets)
    ├── simulator/        # S19–S21  (reuses exercise widgets)
    ├── result/           # S05, S22–S23  (shared result + review)
    ├── speaking_ai/      # S24–S26
    ├── writing_ai/       # S27–S28
    ├── leaderboard/      # S29
    ├── progress/         # S30
    ├── notifications/    # S31
    ├── teacher_feedback/ # S32–S33
    ├── profile/          # S34–S35
    └── subscription/     # S36
```

**State management:** Riverpod (AsyncNotifier pattern per feature)  
**Data layer:** Repository pattern — each feature owns its repo + data models; shared models live in `shared/models/`

---

## 7. Implementation Priority Order

### Phase 0 — Foundation (blocker for everything)
| # | Deliverable | Screens |
|---|-------------|---------|
| 0.1 | Project scaffold: Flutter web+iOS, Riverpod, GoRouter, flavors (dev/staging/prod) | — |
| 0.2 | Design system: theme tokens, typography, color, spacing | — |
| 0.3 | Core: Dio client, error handling, SecureStorage, l10n scaffold (vi/cs/en) | — |
| 0.4 | AppShell + BottomNavBar + adaptive layout (mobile/web) | S37, S38 |

### Phase 1 — Acquisition & Auth (MVP gate)
| # | Deliverable | Screens |
|---|-------------|---------|
| 1.1 | Landing page (guest) | S01 |
| 1.2 | Auth flows: sign up, log in, forgot/reset password | S06–S09 |
| 1.3 | Onboarding wizard | S10 |
| 1.4 | Free mock test (3 sections, MCQ only) | S02–S04 |
| 1.5 | Mock test result + paywall CTA | S05, S36 |

### Phase 2 — Core Learning Loop (retention)
| # | Deliverable | Screens |
|---|-------------|---------|
| 2.1 | Dashboard with streak + daily goal | S11 |
| 2.2 | Course catalog + course detail + module detail | S12–S14 |
| 2.3 | Lesson player (text + audio content types) | S15 |
| 2.4 | Exercise practice (MCQ + fill-blank question types) | S16–S18 |
| 2.5 | Progress / analytics (streak calendar + skill radar) | S30 |

### Phase 3 — Exam Readiness (core paid feature)
| # | Deliverable | Screens |
|---|-------------|---------|
| 3.1 | Full exam simulator (timed, all sections) | S19–S21 |
| 3.2 | Exam result + answer review | S22–S23 |
| 3.3 | Subscription / paywall (Stripe web + StoreKit iOS) | S36 |
| 3.4 | Remaining exercise question types (matching, ordering) | S16–S18 |
| 3.5 | Video lesson type in lesson player | S15 |

### Phase 4 — AI Features (differentiation)
| # | Deliverable | Screens |
|---|-------------|---------|
| 4.1 | Speaking AI: record → transcribe → AI feedback | S24–S26 |
| 4.2 | Writing AI: prompt → submit → annotated feedback | S27–S28 |
| 4.3 | Teacher feedback inbox + thread | S32–S33 |

### Phase 5 — Community & Retention (growth)
| # | Deliverable | Screens |
|---|-------------|---------|
| 5.1 | Leaderboard (weekly + all-time) | S29 |
| 5.2 | Notifications center + push notification integration | S31 |
| 5.3 | Profile + settings + account management | S34–S35 |
| 5.4 | Achievement badges + XP animations | shared |

---

## Key Cross-Cutting Decisions

| Concern | Decision |
|---------|----------|
| State management | Riverpod 2.x — `AsyncNotifierProvider` per feature |
| Routing | GoRouter with `redirect` guards; path-based deep links |
| Data fetching | Repository pattern; Dio + `retrofit` codegen |
| Offline | Hive for cached lessons + last exam state; question answers buffered locally |
| Audio recording | `record` package (cross-platform); fallback upload for web via `web_audio_api` |
| AI calls | Server-side proxy (never expose keys client-side); streaming responses for writing feedback |
| Payments | `flutter_stripe` (web); `in_app_purchase` (iOS); server-side entitlement check |
| Analytics | Custom event wrapper over Firebase Analytics / PostHog; fire on route change + key actions |
| Error boundaries | `ErrorWidget.builder` override + GoRouter `errorBuilder` |
| Accessibility | Semantics labels on all interactive widgets; min touch target 48×48dp |
