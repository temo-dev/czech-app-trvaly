# Route Map — Trvalý Prep MVP
> GoRouter · Flutter Web + iOS · Guards defined below

---

## Route constants file
`lib/core/router/app_routes.dart`

---

## Public routes (no auth required)

| Constant | Path | Screen |
|----------|------|--------|
| `AppRoutes.landing` | `/` | LandingScreen |
| `AppRoutes.mockTestIntro` | `/mock-test/intro` | MockTestIntroScreen |
| `AppRoutes.mockTestSession` | `/mock-test/session/:attemptId` | ExamSessionScreen |
| `AppRoutes.mockTestResult` | `/mock-test/result/:attemptId` | ExamResultScreen |
| `AppRoutes.login` | `/auth/login` | LoginScreen |
| `AppRoutes.signup` | `/auth/signup` | SignupScreen |
| `AppRoutes.forgotPassword` | `/auth/forgot-password` | ForgotPasswordScreen |
| `AppRoutes.resetPassword` | `/auth/reset-password` | ResetPasswordScreen (deep link `?token=`) |

---

## Authenticated routes (ShellRoute — persistent nav)

| Constant | Path | Screen | Guard |
|----------|------|--------|-------|
| `AppRoutes.dashboard` | `/dashboard` | DashboardScreen | `authGuard` |
| `AppRoutes.courseDetail` | `/course/:courseSlug` | CourseOverviewScreen | `authGuard` |
| `AppRoutes.moduleDetail` | `/module/:moduleId` | ModuleDetailScreen | `authGuard` |
| `AppRoutes.lessonDetail` | `/lesson/:lessonId` | LessonDetailScreen | `authGuard` |
| `AppRoutes.practice` | `/practice/:exerciseId` | PracticeScreen | `authGuard` |
| `AppRoutes.speakingFeedback` | `/ai-feedback/speaking/:attemptId` | SpeakingFeedbackScreen | `authGuard` |
| `AppRoutes.writingFeedback` | `/ai-feedback/writing/:attemptId` | WritingFeedbackScreen | `authGuard` |
| `AppRoutes.leaderboard` | `/leaderboard` | LeaderboardScreen | `authGuard` |
| `AppRoutes.progress` | `/progress` | ProgressScreen | `authGuard` |
| `AppRoutes.notificationSettings` | `/settings/notifications` | NotificationSettingsScreen | `authGuard` |
| `AppRoutes.profile` | `/profile` | ProfileScreen | `authGuard` |
| `AppRoutes.teacherFeedback` | `/teacher-feedback/:reviewId` | TeacherFeedbackScreen | `authGuard` |

---

## Route guard rules

```
anonymous user
  → can access: /, /mock-test/**, /auth/**
  → redirect to /auth/login if hitting /dashboard or any authenticated route

authenticated user hitting /auth/**
  → redirect to /dashboard

unknown route
  → GoRouter errorBuilder → ErrorScreen with back button

deep link /auth/reset-password?token=<jwt>
  → extract token, call supabase.auth.verifyOTP
  → on success: redirect to /dashboard
```

---

## GoRouter configuration (reference)

```dart
// lib/core/router/app_router.dart

GoRouter(
  initialLocation: '/',
  refreshListenable: _RouterNotifier(ref),
  redirect: (context, state) {
    final authed = supabase.auth.currentSession != null;
    final loc = state.uri.toString();

    // Redirect authed user away from auth screens
    if (authed && (loc.startsWith('/auth') || loc == '/')) {
      return '/dashboard';
    }

    // Protect all non-public routes
    final publicPrefixes = ['/', '/mock-test', '/auth'];
    final isPublic = publicPrefixes.any((p) => loc.startsWith(p));
    if (!authed && !isPublic) {
      return '/auth/login?from=${Uri.encodeComponent(loc)}';
    }

    return null;
  },
  routes: [
    // ── Public
    GoRoute(path: '/', builder: ...),
    GoRoute(path: '/mock-test/intro', builder: ...),
    GoRoute(path: '/mock-test/session/:attemptId', builder: ...),
    GoRoute(path: '/mock-test/result/:attemptId', builder: ...),
    GoRoute(path: '/auth/login', builder: ...),
    GoRoute(path: '/auth/signup', builder: ...),
    GoRoute(path: '/auth/forgot-password', builder: ...),
    GoRoute(path: '/auth/reset-password', builder: ...),

    // ── Authenticated (wrapped in ShellRoute for persistent nav)
    ShellRoute(
      builder: (_, __, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: ...),
        GoRoute(path: '/course/:courseSlug', builder: ...),
        GoRoute(path: '/module/:moduleId', builder: ...),
        GoRoute(path: '/lesson/:lessonId', builder: ...),
        GoRoute(path: '/practice/:exerciseId', builder: ...),
        GoRoute(path: '/ai-feedback/speaking/:attemptId', builder: ...),
        GoRoute(path: '/ai-feedback/writing/:attemptId', builder: ...),
        GoRoute(path: '/leaderboard', builder: ...),
        GoRoute(path: '/progress', builder: ...),
        GoRoute(path: '/settings/notifications', builder: ...),
        GoRoute(path: '/profile', builder: ...),
        GoRoute(path: '/teacher-feedback/:reviewId', builder: ...),
      ],
    ),
  ],
)
```

---

## Path helpers

```dart
abstract final class AppRoutes {
  static const landing = '/';
  static const mockTestIntro = '/mock-test/intro';
  static String mockTestSession(String id) => '/mock-test/session/$id';
  static String mockTestResult(String id) => '/mock-test/result/$id';
  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const dashboard = '/dashboard';
  static String courseDetail(String slug) => '/course/$slug';
  static String moduleDetail(String id) => '/module/$id';
  static String lessonDetail(String id) => '/lesson/$id';
  static String practice(String id) => '/practice/$id';
  static String speakingFeedback(String id) => '/ai-feedback/speaking/$id';
  static String writingFeedback(String id) => '/ai-feedback/writing/$id';
  static const leaderboard = '/leaderboard';
  static const progress = '/progress';
  static const notificationSettings = '/settings/notifications';
  static const profile = '/profile';
  static String teacherFeedback(String id) => '/teacher-feedback/$id';
}
```

---

## Navigation shell tabs

| Tab index | Label (vi) | Route |
|-----------|-----------|-------|
| 0 | Trang chủ | `/dashboard` |
| 1 | Học | `/course/:lastSlug` or course list |
| 2 | Luyện tập | `/practice` (intro picker) |
| 3 | Tiến trình | `/progress` |
| 4 | Hồ sơ | `/profile` |

Bottom nav visible on: `/dashboard`, `/progress`, `/leaderboard`, `/profile`  
Bottom nav hidden on: exam session, practice, lesson player, AI feedback screens

---

## Deep link + web URL behaviour

| Scenario | URL | Behaviour |
|----------|-----|-----------|
| Share result | `/mock-test/result/:id` | Render result read-only for public |
| Teacher review link | `/teacher-feedback/:id` | Requires auth; redirect to login with `?from=` |
| Email reset | `/auth/reset-password?token=x` | Supabase JWT exchange |
| App reopen (iOS) | Last known path from prefs | GoRouter restores state |
