# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project

**Trvalý Prep** — Vietnamese-first exam prep app for the Czech permanent residency (Trvalý pobyt) exam. Flutter Web + iOS, same codebase.

Full implementation documentation lives in `docs/product/`:
- `architecture.md` — stack, startup sequence, routing, DB access patterns, subscription gating
- `data-contract-map.md` — Supabase tables, Dart models, Edge Function API shapes
- `route-map.md` — canonical route list and GoRouter config
- `screen-map.md` — per-screen contracts (file, provider, states, interactions)
- `state-map.md` — Riverpod provider + Freezed state class definitions
- `component-map.md` — widget inventory with file paths and props

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

## Environment setup

Environment values are baked in at compile time via `--dart-define-from-file`. **Never use runtime dotenv.**

Copy and fill in real Supabase credentials:
```bash
cp env.dev.json env.dev.json   # edit SUPABASE_URL + SUPABASE_ANON_KEY
```

| Flavor | Entry point | Env file |
|--------|-------------|----------|
| `dev` | `lib/main_dev.dart` | `env.dev.json` |
| `staging` | `lib/main_staging.dart` | `env.staging.json` |
| `prod` | `lib/main_prod.dart` | `env.prod.json` |

`AppEnv.validate()` asserts both Supabase keys are non-empty on startup.

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

Router: `lib/core/router/app_router.dart` — a single `@riverpod GoRouter` provider. `_RouterNotifier extends ChangeNotifier` bridges Supabase auth state changes → GoRouter `refreshListenable`.

Guard logic in the `redirect` callback:
- `/` (splash) → redirects to `/landing` or `/app/dashboard` depending on auth
- Authenticated users hitting `/auth/**` → redirect to dashboard
- `/app/**` routes → `authGuard` returns login path if no session

Public routes (no auth): `/landing`, `/mock-test/**`, `/auth/**`  
Authenticated shell routes: everything under `/app/**`, wrapped in `ShellRoute` → `AppShell`

### Shell & adaptive layout
`AppShell` (`lib/features/shell/app_shell.dart`) wraps all authenticated routes.

| Width | Layout |
|-------|--------|
| < 900px | `NavigationBar` (bottom) |
| ≥ 900px | `NavigationRail` (left side), content capped at `maxWidth: 1200` |

Breakpoint check: `MediaQuery.sizeOf(context).width >= 900`

Bottom nav is hidden on full-screen flows (exam session, practice, lesson player, AI feedback).

### Design tokens
All design values come from token classes — never raw literals in widget code:
- Colors: `AppColors.*` (`lib/core/theme/app_colors.dart`) — Sahara palette (primary `#c2652a` burnt sienna, bg `#faf5ee` warm linen)
- Typography: `AppTypography.*` (`lib/core/theme/app_typography.dart`) — EB Garamond (headlines) + Manrope (body/labels)
- Spacing: `AppSpacing.*` — 4px base grid (`lib/core/theme/app_spacing.dart`)
- Radii + Shadows: `AppRadius.*` / `AppShadows.*` (`lib/core/theme/app_radius.dart`) — default 8px, ultra-soft warm shadows
- Theme: `AppTheme.light` / `AppTheme.dark` built from the above tokens

### Models — freezed
All domain models in `lib/shared/models/` and `lib/features/<module>/models/` use `@freezed`. Generated files (`.freezed.dart`, `.g.dart`) are gitignored.

Key shared models: `AppUser`, `Question`, `QuestionAnswer`, `ExamResult` — see `docs/product/data-contract-map.md` for full field definitions and Supabase table mappings.

### Supabase integration
`lib/core/supabase/supabase_config.dart` exposes a top-level `supabase` getter (`Supabase.instance.client`). Use this throughout — no need to pass the client as a dependency.

All AI service calls (speaking scoring, writing correction) go through Supabase Edge Functions in `supabase/functions/` — API keys are never on the client. Edge functions: `speaking-upload`, `speaking-result`, `writing-submit`, `writing-result`, `grade-exam`, `question-feedback`.

### Local storage
- `PrefsStorage` (`lib/core/storage/prefs_storage.dart`) — wraps `shared_preferences` for non-sensitive data (e.g. `pendingAttemptId`)
- `SecureStorage` (`lib/core/storage/secure_storage.dart`) — wraps `flutter_secure_storage` for tokens/sensitive values
- Hive — offline caching for questions and progress

### Localisation
`lib/core/l10n/` contains ARB files for `vi` (primary), `cs`, `en`. Generated via `flutter gen-l10n` (configured in `l10n.yaml`). Access strings with `AppLocalizations.of(context)`.

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

### AI feedback polling
Both speaking and writing AI results are polled (not webhook-pushed). Poll every 3s, max 10 retries, then surface `scoringError` state with retry option. See `docs/product/state-map.md` for state machines.

### Anonymous → authenticated session linking
When a guest completes the free mock test, `pendingAttemptId` is stored in `shared_preferences`. On signup success, PATCH `exam_attempts/:id` with the new `user_id` and clear the prefs key.
