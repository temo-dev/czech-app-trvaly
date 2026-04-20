# Route Map

Canonical route list for GoRouter. All constants live in `lib/core/router/app_routes.dart`. Router defined in `lib/core/router/app_router.dart`.

---

## Auth & Redirect Logic

1. `/` (splash) → if unauthenticated: `/landing`; if authenticated: `/app/dashboard`
2. Authenticated user visiting `/auth/**` or `/landing` → redirect to `/app/dashboard`
3. Any `/app/**` route → `authGuard()`: if no session → `/auth/login?from=<encoded_path>`

`_RouterNotifier` bridges `subscriptionStatusProvider` + `supabase.auth.onAuthStateChange` → GoRouter `refreshListenable`.

---

## Public Routes (no auth required)

| Path | Screen | Notes |
|---|---|---|
| `/` | (splash redirect) | Bootstrap only — immediately redirects |
| `/landing` | `LandingScreen` | |
| `/auth/login` | `LoginScreen` | |
| `/auth/signup` | `SignupScreen` | |
| `/auth/forgot-password` | `ForgotPasswordScreen` | |
| `/auth/reset-password` | (deep link) | `?token=` query param |
| `/mock-test/intro` | `MockTestIntroScreen` | `?examId=` query param |
| `/mock-test/question/:attemptId` | `MockTestQuestionScreen` | guest accessible |
| `/mock-test/result/:attemptId` | `MockTestResultScreen` | guest accessible |

---

## Authenticated Shell Routes (`/app/**`)

Wrapped by `ShellRoute` → `AppShell`. Bottom nav shown unless on full-screen flows.

### Dashboard
| Path | Screen |
|---|---|
| `/app/dashboard` | `DashboardScreen` |

### Courses
| Path | Screen | Notes |
|---|---|---|
| `/app/courses` | `CourseCatalogScreen` | |
| `/app/courses/:courseId` | `CourseDetailScreen` | |
| `/app/courses/:courseId/modules/:moduleId` | `ModuleDetailScreen` | |
| `/app/courses/:courseId/modules/:moduleId/lessons/:lessonId` | `LessonPlayerScreen` | hides bottom nav |

### Exam Catalog
| Path | Screen |
|---|---|
| `/app/exams` | `ExamCatalogScreen` |

### Practice (Exercise Flow)
| Path | Screen | Notes |
|---|---|---|
| `/app/practice/exercise/:exerciseId` | `PracticeScreen` | extra: `{lessonId, lessonBlockId}` |
| `/app/practice/intro` | `ExerciseIntroScreen` | hides bottom nav |
| `/app/practice/question/:index` | `ExerciseQuestionScreen` | hides bottom nav |
| `/app/practice/explanation` | `ExerciseExplanationScreen` | hides bottom nav |

### Full Simulator (subscription-gated)
| Path | Screen | Notes |
|---|---|---|
| `/app/simulator/intro` | `SimulatorIntroScreen` | subscription check at screen level |
| `/app/simulator/question/:index` | `SimulatorQuestionScreen` | hides bottom nav |
| `/app/simulator/result` | `SimulatorResultScreen` | |

### Speaking AI (subscription-gated)
| Path | Screen | Notes |
|---|---|---|
| `/app/speaking/prompt` | `SpeakingPromptScreen` | subscription check at screen level |
| `/app/speaking/recording` | `SpeakingRecordingScreen` | hides bottom nav |
| `/app/speaking/feedback` | `SpeakingFeedbackScreen` | standalone — no shell nav |

### Writing AI (subscription-gated)
| Path | Screen | Notes |
|---|---|---|
| `/app/writing/prompt` | `WritingPromptScreen` | subscription check at screen level |
| `/app/writing/feedback` | `WritingFeedbackScreen` | standalone — no shell nav |

### Social & Chat
| Path | Screen | Notes |
|---|---|---|
| `/app/leaderboard` | `LeaderboardScreen` | |
| `/app/chat` | `InboxScreen` | |
| `/app/chat/:roomId` | `ChatRoomScreen` | extra: `{peerName, peerAvatarUrl}` |
| `/app/teacher/inbox` | `TeacherInboxScreen` | |
| `/app/teacher/thread/:threadId` | `TeacherThreadScreen` | |

### Progress & Profile
| Path | Screen |
|---|---|
| `/app/progress` | `ProgressScreen` |
| `/app/notifications` | `NotificationsScreen` |
| `/app/profile` | `ProfileScreen` |
| `/app/profile/settings` | `SettingsScreen` |
| `/app/unlock-bonus/:lessonId` | `UnlockBonusScreen` |

### Error
| Path | Notes |
|---|---|
| `/error` | `errorBuilder` fallback |

---

## Shell Navigation Items

Bottom nav (< 900px) / Side rail (≥ 900px):

| Tab | Path | Icon |
|---|---|---|
| Học | `/app/dashboard` | home |
| Khóa học | `/app/courses` | menu_book |
| Thi thử | `/app/exams` | quiz |
| Bảng xếp hạng | `/app/leaderboard` | leaderboard |
| Hồ sơ | `/app/profile` | person |

Bottom nav is hidden on: lesson player, simulator question/result, speaking recording, writing/speaking feedback, exercise question/explanation.
