# Foundation Layer — Developer Notes

## First-time setup

```bash
# 1. Fill in real values (gitignored)
cp env.dev.json env.dev.json   # edit SUPABASE_URL + SUPABASE_ANON_KEY

# 2. Install dependencies
flutter pub get

# 3. Run code generation (freezed models + Riverpod providers + GoRouter)
make gen

# 4. Download Be Vietnam Pro font files into assets/fonts/
#    https://fonts.google.com/specimen/Be+Vietnam+Pro
#    Weights needed: 400, 500, 600, 700

# 5. Run dev
make run-web-dev
```

## Code generation

Any file ending in `.g.dart` or `.freezed.dart` is generated — do not edit manually.
Files that need generation:
- `shared/models/*.dart`  (freezed + json_serializable)
- `shared/providers/*.dart`  (riverpod_generator)
- `core/router/app_router.dart`  (riverpod_generator)

Run after any model or provider change:
```bash
make gen          # one-shot
make gen-watch    # continuous during development
```

## Adding a new screen

1. Create `lib/features/<module>/screens/<name>_screen.dart`
2. Add its path constant to `lib/core/router/app_routes.dart`
3. Add the `GoRoute` entry to `lib/core/router/app_router.dart`
4. Apply guards as needed (`authGuard`, `subscriptionGuard`)

## Adding a new Riverpod provider

```dart
// In your feature file:
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  Future<MyState> build() async { ... }
}
// Then: make gen
```

## Supabase table conventions

| Table | Key columns |
|-------|-------------|
| `profiles` | `id` (= auth.uid), `email`, `display_name`, `avatar_url`, `locale`, `exam_date`, `subscription_tier`, `subscription_expires_at` |
| `questions` | `id`, `type`, `skill`, `difficulty`, `prompt`, `options` (jsonb), `correct_answer`, `explanation`, `points` |
| `exam_sessions` | `id`, `user_id`, `type`, `answers` (jsonb), `score`, `completed_at` |
| `courses` | `id`, `title`, `description`, `skill`, `is_premium` |
| `modules` | `id`, `course_id`, `title`, `order_index` |
| `lessons` | `id`, `module_id`, `title`, `content_type`, `content_url`, `order_index` |
| `user_progress` | `user_id`, `lesson_id`, `completed_at` |
| `streaks` | `user_id`, `current_days`, `last_activity_date` |
| `teacher_threads` | `id`, `user_id`, `type` (speaking/writing), `status` |
| `teacher_messages` | `id`, `thread_id`, `sender_id`, `body`, `created_at` |

## Environment / flavors

| Flavor | Entry point | Env file |
|--------|-------------|----------|
| dev | `lib/main_dev.dart` | `env.dev.json` |
| staging | `lib/main_staging.dart` | `env.staging.json` |
| prod | `lib/main_prod.dart` | `env.prod.json` |

Values are baked in at compile time via `--dart-define-from-file`. Never use `dotenv` at runtime for secrets.

## Adaptive layout breakpoints

| Width | Layout |
|-------|--------|
| < 600px | Single column, bottom nav |
| 600–900px | Two-column grid, bottom nav |
| ≥ 900px | `NavigationRail` side, `maxWidth: 1200` centred |

Breakpoint check: `MediaQuery.sizeOf(context).width >= 900`
