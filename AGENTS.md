# AGENTS.md

This file provides guidance to Codex when working with code in this repository.

---

## Project

**Trvalý Prep** — Vietnamese-first exam prep app for the Czech permanent residency exam. Flutter Web + iOS from one shared codebase.

Canonical implementation docs live in `docs/product/`:
- `architecture.md` — stack, runtime topology, routing, DB access patterns, AI pipeline
- `data-contract-map.md` — Supabase tables, key models, Edge Function payloads
- `route-map.md` — canonical route list and GoRouter config
- `screen-map.md` — screen-level contracts, states, and actions
- `state-map.md` — provider/state-machine definitions and operational notes
- `component-map.md` — widget inventory

When this file and product docs disagree, follow `docs/product/*`.

---

## Commands

```bash
# Setup
flutter pub get
make gen

# Run
make run-web-dev
make run-dev
make run-staging

# Build
make build-web-prod
make build-ios-prod

# Codegen
make gen
make gen-watch

# Reset
make clean

# Tests
flutter test
make test-unit
make test-widget
make test-integration-web
make test-integration-ios
make test-coverage
flutter test test/features/auth/login_test.dart

# Lint
flutter analyze
```

---

## Environment Setup

Environment values are compile-time only via `--dart-define-from-file=env.<flavor>.json`.

| Flavor | Entry point | Env file |
|---|---|---|
| `dev` | `lib/main_dev.dart` | `env.dev.json` |
| `staging` | `lib/main_staging.dart` | `env.staging.json` |
| `prod` | `lib/main_prod.dart` | `env.prod.json` |

`AppEnv.validate()` asserts `SUPABASE_URL` and `SUPABASE_ANON_KEY` are non-empty before app startup.

Do not add runtime dotenv loading.

Fonts must exist in `assets/fonts/`:
- **EB Garamond** — display/headlines
- **Manrope** — body, labels, buttons

---

## Architecture

### Startup Sequence

`main_<flavor>.dart` → `AppEnv.validate()` → `PrefsStorage.init()` → `initSupabase()` → `runApp(ProviderScope(child: App()))`

`App` in `lib/app.dart` is a `ConsumerWidget` that reads `appRouterProvider` and builds `MaterialApp.router`.

### State Management

All providers use `riverpod_annotation` codegen. Run `make gen` after changing any `@riverpod` provider or Freezed model.

- `AsyncNotifier<T>` — async data + mutations
- `Notifier<T>` — sync state machines
- `StreamProvider` — auth/realtime/connectivity streams

### Routing

Use route constants from `lib/core/router/app_routes.dart`. Never hardcode route strings.

Router lives in `lib/core/router/app_router.dart` as a single `@riverpod GoRouter` provider. `_RouterNotifier` bridges Supabase auth changes and subscription state into GoRouter refreshes.

High-level routing rules:
- `/` redirects to `/landing` or `/app/dashboard`
- authenticated users are redirected away from `/auth/**`
- `/app/**` uses `authGuard`
- public surface includes `/landing`, `/auth/**`, `/mock-test/**`, `/onboarding`

### Adaptive Layout

`AppShell` wraps authenticated routes.

| Width | Layout |
|---|---|
| `< 900px` | bottom `NavigationBar` |
| `>= 900px` | left `NavigationRail`, content capped to `maxWidth: 1200` |

Full-screen flows that hide shell nav include lesson player, simulator question, exercise question/explanation, speaking recording, and speaking/writing feedback.

### Design Tokens

Never scatter raw design literals in widget code.

- Colors: `AppColors.*`
- Typography: `AppTypography.*`
- Spacing: `AppSpacing.*`
- Radius/Shadows: `AppRadius.*`, `AppShadows.*`
- Theme: `AppTheme.light` / `AppTheme.dark`

### Models

Domain models in `lib/shared/models/` and `lib/features/<module>/models/` use Freezed and JSON serialization. Generated files are gitignored.

---

## Supabase Integration

Use the top-level client from `lib/core/supabase/supabase_config.dart`.

Access patterns:
- client reads use PostgREST with RLS
- anonymous ownership uses persisted `x-guest-token`
- privileged AI writes happen only inside Edge Functions via service-role
- admin CMS uses service-role server-side
- lesson progress writes are idempotent in the current client path: `SELECT` existing `user_progress` row by `(user_id, lesson_block_id)` first, then `INSERT` only if missing

Important RLS note:
- `user_progress` still keeps an `UPDATE` policy for backward compatibility with legacy clients/flows that used `upsert`
- compatibility migration: `20260419204926_user_progress_update_policy.sql`

### Edge Functions

Main functions:
- `speaking-upload`
- `speaking-result`
- `writing-submit`
- `writing-result`
- `grade-exam`
- `analyze-exam`
- `question-feedback`
- `ai-review-submit`
- `ai-review-result`

### JWT Config

This project uses ES256 JWT signing. Supabase Edge pre-verification only supports HS256, so functions must be deployed with `verify_jwt = false`.

Rules:
- every function must be declared in `supabase/config.toml`
- deploy new/updated functions with `--no-verify-jwt`
- auth is checked manually inside functions via shared helpers in `supabase/functions/_shared/guest_access.ts`

Example:

```bash
supabase functions deploy <function-name> --no-verify-jwt
```

If you forget this, functions can fail before your code runs with `UNAUTHORIZED_UNSUPPORTED_TOKEN_ALGORITHM`.

---

## AI Flows

### Speaking / Writing

Speaking and writing are polling-based, not webhook-pushed.

- submit/upload → returns `attempt_id`
- poll every 3s
- max 10 retries
- final states: `ready` or `error`

Subjective lesson progress rule:
- speaking/writing lesson flows only sync `user_progress` after AI Teacher review reaches `ready`

### Writing Reference Resolution

`writing-submit` accepts:
- mock test: real `question_id` from `questions`
- lesson/practice: `exercise_id` from `exercises`, with `question_id` omitted

Backward compatibility rule:
- if an older client sends an exercise UUID via `question_id`, the edge function resolves it server-side and treats it as `exercise_id`
- this avoids FK violation `23503` on `ai_writing_attempts.question_id`

### Czech Enforcement

If Whisper or GPT determines a speaking answer is not Czech, scores are zeroed and the learner gets a Vietnamese explanation.

### Exam Analysis

`grade-exam` writes `exam_results`, then triggers `analyze-exam`.

`analyze-exam`:
- reuses objective feedback via `question-feedback`
- hydrates speaking/writing from existing AI attempt rows
- synthesizes exam-level insights
- writes `exam_analysis`

Result screens poll `exam_analysis` until it becomes ready/error.

---

## Local Storage

- `PrefsStorage` — shared preferences for non-sensitive state such as guest token and `pendingAttemptId`
- `SecureStorage` — sensitive storage
- Hive — offline caches

### Guest → Auth Linking

When a guest completes the free mock test:
- `pendingAttemptId` is stored locally
- after signup success, the app links `exam_attempts`, `exam_results`, `exam_analysis`, `ai_speaking_attempts`, and `ai_writing_attempts` by `exam_attempt_id`
- then clears the pending key

---

## Localisation

ARB files live in `lib/core/l10n/` for:
- `vi` primary
- `cs`
- `en`

Generated via `flutter gen-l10n` with `l10n.yaml`.

UI and AI explanations are Vietnamese-first. Czech terms appear where required by the exam domain.

---

## Conventions

### Adding a Screen

1. Create `lib/features/<module>/screens/<name>_screen.dart`
2. Add route constant to `lib/core/router/app_routes.dart`
3. Register `GoRoute` in `lib/core/router/app_router.dart`
4. Update `docs/product/screen-map.md`

### Adding a Provider

```dart
@riverpod
class MyFeatureNotifier extends _$MyFeatureNotifier {
  @override
  Future<MyState> build() async { ... }
}
```

Then run `make gen`.

### Screen States

Every screen should explicitly handle:
- `loading` with shimmer/skeleton, not spinner-only
- `success`
- `empty`
- `error` with retry

### Responsive Rule

Mobile-first. Web gets wider containers, not separate flows.

### Progress Rule

Lesson block completion should be idempotent. Avoid re-writing `user_progress` for the same `(user_id, lesson_block_id)` when the block is already complete.

### Documentation Rule

If behavior changes in routing, AI flows, progress sync, Edge Function payloads, or Supabase schemas, update the matching files in `docs/product/`.

