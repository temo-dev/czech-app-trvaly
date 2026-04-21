# Architecture Overview

High-level decisions and runtime topology for Trvalý Prep.

Operational runbook cho AI flows nằm ở [ai-ops.md](/Users/daniel.dev/Desktop/app-czech/docs/product/ai-ops.md).

---

## Stack

| Layer | Technology |
|---|---|
| Client | Flutter 3.24+ (Web + iOS, same codebase) |
| State | Riverpod 2 (riverpod_annotation codegen) |
| Navigation | GoRouter 14 |
| Backend | Supabase (Postgres, Auth, Storage, Edge Functions, Realtime) |
| AI scoring | OpenAI GPT-4o Transcribe (transcription) + GPT-5 mini (interactive grading) via Edge Functions |
| Admin CMS | Next.js (service_role key, bypasses RLS) in `cms/` |
| Offline cache | Hive |
| Secure storage | flutter_secure_storage |
| Models | Freezed + json_serializable |

Model selection is env-overridable at the Edge Function layer. Current defaults:
- `OPENAI_SPEAKING_TRANSCRIBE_MODEL` → `gpt-4o-transcribe`
- `OPENAI_SPEAKING_AUDIO_MODEL` → `gpt-audio-mini`
- `OPENAI_SPEAKING_SCORING_MODEL` → `gpt-5-mini` (fallback transcript-only scoring)
- `OPENAI_WRITING_SCORING_MODEL` → `gpt-5-mini`
- `OPENAI_QUESTION_FEEDBACK_MODEL` → `gpt-5-mini`
- `OPENAI_OBJECTIVE_REVIEW_MODEL` → `gpt-5-mini`
- `OPENAI_EXAM_SYNTHESIS_MODEL` → `gpt-5.1`
- `OPENAI_DEFAULT_CHAT_MODEL` → `gpt-4.1-mini` (fallback only)

---

## Startup Sequence

```
main_<flavor>.dart
  └── AppEnv.validate()            // asserts SUPABASE_URL + SUPABASE_ANON_KEY non-empty
  └── PrefsStorage.init()          // initializes shared_preferences
  └── initSupabase()               // Supabase.initialize(...)
  └── runApp(ProviderScope(
        child: App()               // ConsumerWidget → MaterialApp.router
      ))
```

Environment is baked at compile time via `--dart-define-from-file=env.<flavor>.json`. Never loaded at runtime.

---

## Routing Architecture

```
GoRouter (appRouterProvider)
  ├── _RouterNotifier               // ChangeNotifier bridging Supabase auth + subscriptionStatusProvider
  ├── redirect()                    // splash → landing/dashboard; auth guard for /app/**
  ├── Public routes                 // /landing, /auth/**, /mock-test/**, /onboarding
  └── ShellRoute → AppShell
        └── /app/** (authenticated)
```

`authGuard()` checks `supabase.auth.currentSession`. On fail, redirects to `/auth/login?from=<encoded_path>` preserving deep-link.

---

## State Management Pattern

All providers use `riverpod_annotation` codegen. Three patterns in use:

| Pattern | Use case | Example |
|---|---|---|
| `AsyncNotifier<T>` | Async data + mutations | `DashboardNotifier`, `CourseDetailNotifier` |
| `Notifier<T>` | Sync state machine | `ExamSessionNotifier`, `SpeakingNotifier` |
| `StreamProvider` | Realtime / auth stream | `authSessionProvider`, `chatRoomProvider` |

Run `make gen` after any change to `@riverpod` annotated code.

---

## Database Access Patterns

- **Client reads**: direct Supabase PostgREST calls with RLS enforced via anon key
- **Anonymous ownership**: client sends stable `x-guest-token` header on every Supabase request; guest-owned rows persist the same token and RLS/Edge Functions check it before read/update
- **AI scoring writes**: service_role key inside Edge Functions only — client never holds service_role key
- **Lesson progress writes**: current client flow marks `user_progress` idempotently (`SELECT` by `(user_id, lesson_block_id)` first, then `INSERT` only when missing) so repeated ready/rebuild events do not rewrite the same row
- **Admin CMS**: service_role key in Next.js server-side — bypasses all RLS
- **RPC calls**: `increment_xp`, `unlock_lesson_bonus`, `find_or_create_dm` — SECURITY DEFINER functions invoked by authenticated client

Access the client anywhere: `import 'package:app_czech/core/supabase/supabase_config.dart'; supabase.from(...)`.

---

## AI Pipeline (Speaking, Writing, Exam Analysis)

```
Client                          Edge Function              OpenAI
  │── POST speaking-upload ──►  INSERT ai_speaking_attempts (status: processing)
  │                             background task:
  │                               transcribeAudio() ─────► GPT-4o Transcribe
  │                               chatCompleteWithAudio() ► GPT Audio (preferred, wav/mp3)
  │                               fallback chatComplete() ► GPT-5 mini
  │                               UPDATE ai_speaking_attempts (ready/error)
  │◄── { attempt_id } ─────────
  │
  │── POST speaking-result ──► SELECT ai_speaking_attempts WHERE id = attempt_id
  │◄── { status: pending|ready|error }
  │    (poll every 3s, max 10 retries)
  │
  │── POST writing-submit ───► resolve question_id/exercise_id
  │                             INSERT ai_writing_attempts (status: processing)
  │                             background task:
  │                               chatComplete() ────────► GPT-5 mini
  │                               UPDATE ai_writing_attempts (ready/error)
  │◄── { attempt_id } ─────────
  │
  │── POST writing-result ───► SELECT ai_writing_attempts WHERE id = attempt_id
  │◄── { status: pending|ready|error }
  │    (poll every 3s, max 10 retries)
  │
  │── POST grade-exam ───────► INSERT exam_results
  │                           fire-and-forget analyze-exam()
  │                           ├─ objective questions → cache/GPT-5 mini via question-feedback
  │                           ├─ speaking/writing → hydrate from ai_*_attempts
  │                           └─ 1 synthesis GPT-5.1 call → INSERT/UPDATE exam_analysis
  │
  │── result screen ─────────► poll exam_analysis until ready/error
  │◄── preload per-question feedback + skill insights + recommendations
```

Czech language enforcement: speaking grading prompt explicitly classifies whether the spoken answer is Czech. If the model returns `is_czech: false` → all metric scores are zeroed and the learner gets a Vietnamese explanation.

Speaking scoring contract: transcript is still generated and stored for review UX, but the authoritative speaking score now prefers audio-native grading when the uploaded format is supported (`wav`/`mp3`). This unified scoring core is used for both speaking exam and speaking exercise flows. For supported formats, `speaking-upload` now starts transcription and audio-native grading in parallel, then persists the final attempt only after both branches complete. If audio-native grading is unavailable, the edge function falls back to transcript-based scoring while preserving the same response shape.

Language contract for AI feedback: all user-facing AI explanations, summaries, tips, suggestions, and review labels must be returned in Vietnamese. Czech may appear only inside quoted examples, transcripts, or corrected answers where the exam domain requires it.

Vietnamese guardrail: if a model response still contains suspicious English in user-facing feedback fields, Edge Functions run a final JSON normalization pass (`OPENAI_VIETNAMESE_GUARD_MODEL`, default `gpt-5-mini`) before persisting or returning the payload. This pass preserves Czech learner content such as transcripts, corrected answers, and original text spans.

Operational logging: the guard emits structured log events with `event: "vietnamese_guard"` whenever it is triggered. Logs include only metadata such as `context`, `context_group`, `context_slug`, model name, suspicious field paths/counts, rewrite result, and fallback errors; they do not include learner transcript or feedback text. Speaking background processing also emits structured latency logs containing `audio_format`, `review_mode`, `scoring_mode`, `transcription_ms`, `scoring_ms`, `guard_ms`, `guard_triggered`, and `total_ms` so latency regressions can be isolated by stage.

Quick monitoring workflow:
- Tất cả event guard: lọc `event="vietnamese_guard"`
- Lỗi/timeout guard: lọc thêm `status="fallback"`
- Rewrite chưa sạch hoàn toàn: lọc `status="partial"`
- Theo luồng nghiệp vụ: lọc `context_group` (`speaking`, `writing`, `question_feedback`, `objective_review`, `exam_analysis`)
- Theo caller cụ thể: lọc `context_slug`
- Ưu tiên điều tra nếu `suspicious_count` cao, `remaining_count > 0`, hoặc `changed=false` dù status là `rewritten`

Writing reference resolution: mock test sends real `question_id` from `questions`, while lesson/practice writing can send `exercise_id` from `exercises`. `writing-submit` normalizes these references server-side and also tolerates older clients that accidentally send an exercise UUID through `question_id`, preventing FK violation `23503` on `ai_writing_attempts.question_id`.

Objective review write sequence: `ai-review-submit` inserts the `ai_teacher_reviews` row with `status: 'processing'` and `result_payload: null`, calls `gpt-5-mini`, then does a single UPDATE to `status: 'ready'` with the full payload atomically. This ensures the row is never visible as `ready` with a null payload if the update fails.

AI Teacher polling note: `ai-review-result` can now return a pending `message` plus optional `processing_stage` (`transcribing`, `scoring`, `hydrating_review`) so review cards can distinguish between “đang nhận transcript”, “đang chấm”, and “đang hoàn thiện review”. Flutter review providers auto-poll again while the response remains pending, using a faster cadence for subjective speaking/writing reviews.

Exam vs exercise review split:
- `exercise` / lesson / practice keep the per-question AI Teacher flow via `ai-review-submit` and `ai-review-result`.
- `mock_test` review no longer starts AI Teacher per question from the result screen. `analyze-exam` materializes both summary feedback (`question_feedbacks`) and full subjective review payloads (`teacher_reviews_by_question`) into `exam_analysis`.
- Mock test detail screens read those materialized payloads directly from `exam_analysis`, so the learner sees one whole-exam grading state and then the full review set together.
- While `exam_results.ai_grading_pending = true`, the app treats `exam_results` as provisional only. Final score, pass/fail, weak skills, and per-skill official breakdown must stay hidden until subjective attempts finish.
- When a mock-test speaking or writing attempt reaches `ready` or `error`, the edge function triggers `grade-exam` again for the same `exam_attempt_id`, which refreshes `exam_results` and re-triggers `analyze-exam`.

Guest security: anonymous mock-test and AI rows (`exam_attempts`, `exam_results`, `exam_analysis`, `ai_*_attempts`, `ai_teacher_reviews`) are scoped by persisted `guest_token`. Edge Functions using service-role also re-check ownership against `user_id` or `guest_token` instead of trusting raw UUIDs.

**Edge Function JWT config — critical:** This project uses ES256 JWT signing. The Supabase edge runtime only supports HS256 for its built-in pre-verification step, so all functions must be deployed with `verify_jwt = false`. Auth is handled manually inside each function via `assertCanAccessExamAttempt` / `getAuthUserId` in `_shared/guest_access.ts`. `config.toml` declares `verify_jwt = false` for every function. When adding a new edge function, always add the entry to `config.toml` and deploy with `--no-verify-jwt`:

```bash
supabase functions deploy <function-name> --no-verify-jwt
```

Omitting this causes a 401 `UNAUTHORIZED_UNSUPPORTED_TOKEN_ALGORITHM` before any function code runs.

---

## Adaptive Layout

`AppShell` applies breakpoint at 900px:

| Viewport | Layout |
|---|---|
| < 900px (mobile) | `NavigationBar` bottom; content full-width |
| ≥ 900px (tablet/web) | `NavigationRail` left; content container `maxWidth: 1200` |

Rule: one codebase, one logical flow. Web gets wider containers, not different widgets or screens.

Full-screen flows that hide `AppShell` nav: lesson player, simulator question, speaking recording, speaking/writing feedback, exercise question/explanation.

Subjective lesson flows (speaking/writing) only sync `user_progress` after the AI Teacher review reaches `ready`.

---

## Three User Roles

| Role | Access |
|---|---|
| `learner` (default) | Own data; public content; no admin UI |
| `teacher` | Can insert `teacher_comments` on any review thread |
| `admin` | Full CMS access; `is_admin()` used in all content-table RLS policies |

Role is stored in `profiles.role`. Checked server-side via `is_admin()` RPC in RLS policies — never trusted from client.

---

## Subscription Gating

`isPremiumProvider` (derived from `currentUserProvider`) gates:
- Full simulator (`/app/simulator/**`)
- Speaking AI (`/app/speaking/**`)
- Writing AI (`/app/writing/**`)

Subscription state: `SubscriptionStatus { active, expired, free }` from `profiles.subscription_tier` + `profiles.subscription_expires_at`.

Screens show a locked state with upgrade CTA when `isPremium == false`. Router does not redirect — gating is at screen level.

---

## Offline / Connectivity

`connectivityProvider` (StreamProvider via `connectivity_plus`) emits `online/offline`. `AppShell` shows `OfflineBanner` when offline. Hive caches question content and progress for offline reading; write operations queue or fail gracefully.

---

## Localisation

ARB files in `lib/core/l10n/`. Primary language: Vietnamese (`vi`). Also: Czech (`cs`), English (`en`).

Generated via `flutter gen-l10n` (configured in `l10n.yaml`). Access: `AppLocalizations.of(context)`.

UI copy is Vietnamese-first. Czech exam terms appear in Czech. Explanations and feedback from AI are always in Vietnamese.

---

## CMS (`cms/`)

Next.js admin app. Authenticated with Supabase service_role key (server-side only). Provides CRUD for: courses, modules, lessons, lesson blocks, exercises, questions, exams, and teacher review management. Stats via `cms_dashboard_stats()` RPC.

See `cms/AGENTS.md` — this Next.js version has breaking changes from standard patterns. Read before modifying.
