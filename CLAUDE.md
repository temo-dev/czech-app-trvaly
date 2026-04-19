# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

When this file and product docs disagree, follow `docs/product/*`.

---

## Project

**Trvalý Prep** — Vietnamese-first exam prep app for the Czech permanent residency (Trvalý pobyt) exam. Flutter Web + iOS, same codebase.

Full implementation documentation lives in `docs/product/`:
- `architecture.md` — stack, runtime topology, routing, DB access patterns, AI pipeline, subscription gating
- `data-contract-map.md` — Supabase tables, Dart models, Edge Function API shapes
- `route-map.md` — canonical route list and GoRouter config
- `screen-map.md` — per-screen contracts (file, provider, states, interactions)
- `state-map.md` — Riverpod provider + Freezed state class definitions, AI polling pattern
- `component-map.md` — widget inventory with file paths and props
- `content-authoring.md` — how to seed and replace exam/course content via migrations

---

## Commands

```bash
# First-time setup
flutter pub get
make gen                    # run build_runner (freezed + Riverpod codegen)

# Run
make run-web-dev            # Chrome, dev flavor
make run-dev                # connected device, dev flavor
make run-staging

# Build
make build-web-prod
make build-ios-prod

# Code generation (required after editing any model or @riverpod provider)
make gen                    # one-shot
make gen-watch              # watch mode during active development

# Full reset
make clean                  # flutter clean + pub get + gen

# Tests
flutter test                                          # all tests
make test-unit                                        # unit tests only
make test-widget                                      # widget tests only
make test-integration-web                             # integration tests on Chrome (headless, staging)
make test-integration-ios                             # integration tests on iPhone 15 Pro simulator
make test-coverage                                    # run tests + open HTML coverage report
flutter test test/features/auth/login_test.dart       # single file

# Lint
flutter analyze
```

---

## Environment Setup

Environment values are baked in at compile time via `--dart-define-from-file`. **Never use runtime dotenv.**

| Flavor | Entry point | Env file |
|--------|-------------|----------|
| `dev` | `lib/main_dev.dart` | `env.dev.json` |
| `staging` | `lib/main_staging.dart` | `env.staging.json` |
| `prod` | `lib/main_prod.dart` | `env.prod.json` |

`AppEnv.validate()` asserts both `SUPABASE_URL` and `SUPABASE_ANON_KEY` are non-empty on startup.

Font files must be manually placed in `assets/fonts/` — download from Google Fonts:
- **EB Garamond** (weights 400, 500, 600, 700 + Italic 400) → headlines/display
- **Manrope** (weights 400, 500, 600, 700) → body, labels, buttons

---

## Architecture

### Startup sequence
`main_<flavor>.dart` → `AppEnv.validate()` → `PrefsStorage.init()` → `initSupabase()` → `runApp(ProviderScope(child: App()))`.

`App` (`lib/app.dart`) is a `ConsumerWidget` that reads `appRouterProvider` and constructs `MaterialApp.router`.

### State management — Riverpod
All providers use the `riverpod_annotation` codegen pattern. After adding or modifying any `@riverpod` annotated class or function, run `make gen`.

- `AsyncNotifier<T>` — for async data with mutations (screens, features)
- `Notifier<T>` — for sync state machines (form state, recording state)
- `StreamProvider` — for real-time streams (auth session, connectivity)

Provider files live in `features/<module>/providers/` or `shared/providers/`. State classes are `@freezed`.

### Routing — GoRouter
Route constants: `lib/core/router/app_routes.dart` — always use `AppRoutes.*`, never hardcode strings.

Router: `lib/core/router/app_router.dart` — a single `@riverpod GoRouter` provider. `_RouterNotifier extends ChangeNotifier` bridges Supabase auth state changes and `subscriptionStatusProvider` → GoRouter `refreshListenable`.

Guard logic in the `redirect` callback:
- `/` (splash) → redirects to `/landing` or `/app/dashboard` depending on auth
- Authenticated users hitting `/auth/**` → redirect to dashboard
- `/app/**` routes → `authGuard` returns `/auth/login?from=<encoded_path>` if no session

Public routes (no auth): `/landing`, `/mock-test/**`, `/auth/**`, `/onboarding`
Authenticated shell routes: everything under `/app/**`, wrapped in `ShellRoute` → `AppShell`

### Shell & adaptive layout
`AppShell` (`lib/features/shell/app_shell.dart`) wraps all authenticated routes.

| Width | Layout |
|-------|--------|
| < 900px | `NavigationBar` (bottom) |
| ≥ 900px | `NavigationRail` (left side), content capped at `maxWidth: 1200` |

Full-screen flows that hide shell nav: lesson player, simulator question, exercise question/explanation, speaking recording, speaking/writing feedback.

### Design tokens
All design values come from token classes — never raw literals in widget code:
- Colors: `AppColors.*` (`lib/core/theme/app_colors.dart`) — Sahara palette (primary `#c2652a` burnt sienna, bg `#faf5ee` warm linen)
- Typography: `AppTypography.*` (`lib/core/theme/app_typography.dart`) — EB Garamond (headlines) + Manrope (body/labels)
- Spacing: `AppSpacing.*` — 4px base grid (`lib/core/theme/app_spacing.dart`)
- Radii + Shadows: `AppRadius.*` / `AppShadows.*` (`lib/core/theme/app_radius.dart`) — default 8px, ultra-soft warm shadows
- Theme: `AppTheme.light` / `AppTheme.dark` built from the above tokens

### Models — Freezed
All domain models in `lib/shared/models/` and `lib/features/<module>/models/` use `@freezed`. Generated files (`.freezed.dart`, `.g.dart`) are gitignored.

Key shared models: `AppUser`, `Question`, `QuestionAnswer`, `ExamResult`, `ExamAttempt`, `Exercise` — see `docs/product/data-contract-map.md` for full field definitions and Supabase table mappings.

### Three user roles

| Role | Access |
|------|--------|
| `learner` (default) | Own data; public content; no admin UI |
| `teacher` | Can insert `teacher_comments` on any review thread |
| `admin` | Full CMS access; `is_admin()` used in all content-table RLS policies |

Role is stored in `profiles.role`. Checked server-side via `is_admin()` RPC — never trusted from client.

### Subscription gating
`isPremiumProvider` (derived from `currentUserProvider`) gates full simulator, speaking AI, and writing AI. Gating is at screen level — the router does not redirect. Screens show a locked state with upgrade CTA when `isPremium == false`.

---

## Supabase Integration

Access the client anywhere:
```dart
import 'package:app_czech/core/supabase/supabase_config.dart';
supabase.from(...)
```

Database access patterns:
- **Client reads**: direct PostgREST with RLS enforced via anon key
- **Anonymous ownership**: client sends stable `x-guest-token` header; guest-owned rows are scoped by this token; RLS and Edge Functions validate it before any read/update
- **AI scoring writes**: service_role key inside Edge Functions only — client never holds service_role key
- **Lesson progress writes**: idempotent — `SELECT user_progress WHERE (user_id, lesson_block_id)` first, then `INSERT` only when missing; do not use upsert in new code
- **Admin CMS**: service_role key in Next.js server-side in `cms/` — bypasses all RLS
- **RPC calls**: `increment_xp`, `unlock_lesson_bonus`, `find_or_create_dm` — SECURITY DEFINER functions invoked by authenticated client

### Edge Functions

All functions deployed in `supabase/functions/`. API keys are never on the client.

| Function | Purpose |
|----------|---------|
| `speaking-upload` | Transcribes audio via Whisper, scores via GPT-4.1-mini |
| `speaking-result` | Polls `ai_speaking_attempts` status |
| `writing-submit` | Scores writing via GPT-4.1-mini |
| `writing-result` | Polls `ai_writing_attempts` status |
| `grade-exam` | Grades submitted exam, writes `exam_results`, triggers `analyze-exam` |
| `analyze-exam` | Batch AI analysis → writes `exam_analysis` |
| `question-feedback` | Per-question AI feedback with cache (`question_ai_feedback`) |
| `ai-review-submit` | Submits AI Teacher review request |
| `ai-review-result` | Polls `ai_teacher_reviews` status |

### JWT config — critical

This project uses ES256 JWT signing. The Supabase edge runtime only supports HS256 for its built-in pre-verification step, so **all functions must be deployed with `verify_jwt = false`**. Auth is handled manually inside each function via helpers in `supabase/functions/_shared/guest_access.ts`. `config.toml` declares `verify_jwt = false` for every function.

When adding a new edge function, always add the entry to `config.toml` and deploy with:
```bash
supabase functions deploy <function-name> --no-verify-jwt
```

Omitting this causes a 401 `UNAUTHORIZED_UNSUPPORTED_TOKEN_ALGORITHM` before any function code runs.

---

## AI Flows

### Speaking / Writing (polling)
Submit → `attempt_id` → poll every 3s, max 10 retries → `ready` or `error`/`scoring_timeout`.

Mock test context: `exam_attempt_id` **must** be passed to `speaking-upload` / `writing-submit` so `grade-exam` can JOIN AI scores. If AI is still processing when `grade-exam` runs, that question scores 0 and `exam_results.ai_grading_pending = true` — the result screen shows a pending banner.

Speaking FK-safety rule: only send `question_id` (from `questions` table). Do NOT send `exercise_id` when `question_id` is a real questions-table UUID — the edge function clears `exercise_id` when `question_id` resolves, preventing FK violation `23503`.

Writing reference resolution: mock test sends real `question_id`; lesson/practice sends `exercise_id`. The edge function handles backward-compat if an older client sends an exercise UUID via `question_id`.

Czech enforcement: if Whisper detects non-Czech OR GPT returns `is_czech: false` → all metric scores zeroed, Vietnamese explanation returned.

### Exam analysis
After `grade-exam` inserts `exam_results`, it fire-and-forgets `analyze-exam`, which:
- reuses `question-feedback` cache for objective questions
- hydrates speaking/writing from existing AI attempt rows
- calls one synthesis GPT pass → `skill_insights` + `overall_recommendations`
- writes `exam_analysis` (status: `processing` → `ready`/`error`)

Result screens poll `exam_analysis` every 3s until ready/error.

### Subjective lesson progress
Speaking and writing lesson flows only sync `user_progress` after the AI Teacher review reaches `ready`. Progress sync is wrapped defensively so an RLS error does not crash the screen.

---

## Local Storage

- `PrefsStorage` (`lib/core/storage/prefs_storage.dart`) — wraps `shared_preferences` for non-sensitive data (guest token, `pendingAttemptId`)
- `SecureStorage` (`lib/core/storage/secure_storage.dart`) — wraps `flutter_secure_storage` for sensitive values
- Hive — offline caching for questions and progress

### Anonymous → authenticated session linking
1. Guest submits mock test → `exam_attempts.user_id = null`; after `grade-exam` → `pendingAttemptId` stored in `PrefsStorage`
2. User signs up → link `exam_attempts`, `exam_results`, `exam_analysis`, `ai_speaking_attempts`, `ai_writing_attempts` by `exam_attempt_id`; clear `pendingAttemptId`

---

## Localisation
`lib/core/l10n/` contains ARB files for `vi` (primary), `cs`, `en`. Generated via `flutter gen-l10n` (configured in `l10n.yaml`). Access strings with `AppLocalizations.of(context)`. UI and AI explanations are Vietnamese-first; Czech terms appear in exam content only.

---

## Conventions

### Adding a screen
1. Create `lib/features/<module>/screens/<name>_screen.dart`
2. Add path constant to `lib/core/router/app_routes.dart`
3. Add `GoRoute` to `lib/core/router/app_router.dart`
4. Register in `docs/product/screen-map.md`

### Adding a provider
```dart
@riverpod
class MyFeatureNotifier extends _$MyFeatureNotifier {
  @override
  Future<MyState> build() async { ... }
}
// Then: make gen
```

### State variants every screen must handle
`loading` (shimmer skeleton, not spinner) · `success` · `empty` · `error` (with retry that calls `.refresh()`)

### Responsive rule
Mobile-first. Web gets wider containers — not different flows or separate widgets. One codebase, one logical flow.

### Progress idempotency rule
Lesson block completion must be idempotent. Use `markBlockComplete(lessonId, lessonBlockId)` in `lib/features/course/providers/course_providers.dart` — it does a `SELECT` check before inserting to avoid duplicate `user_progress` rows. Do not use `upsert` for this.

### Documentation rule
If behavior changes in routing, AI flows, progress sync, Edge Function payloads, or Supabase schemas, update the matching file in `docs/product/`.

### Content authoring
Exam and course content is seeded via Supabase migration files in `supabase/migrations/`. See `docs/product/content-authoring.md` for the full schema, UUID strategy, block structure, and workflow for replacing content.

Key schema note: `lesson_blocks` does **not** have an `exercise_id` column. Exercises are linked via the `lesson_block_exercises` junction table.
