# Implementation Spec — Trvalý Prep MVP
> Single source of truth for product scope, architecture decisions, and platform rules.
> Decisions marked ✅ are locked. Decisions marked ⚠️ need confirmation before Day 1.

---

## 1. Product summary

| | |
|---|---|
| **Product name** | Trvalý Prep |
| **Goal** | Help Vietnamese learners pass the Czech Trvalý pobyt exam faster |
| **Platforms** | Flutter Web · iOS (same codebase) |
| **Language priority** | Vietnamese-first · Czech · English |
| **Backend** | Supabase (auth + database + edge functions) |
| **Media storage** | AWS S3 (audio recordings, listening assets, images) |
| **AI features** | Speaking scoring · Writing correction (separate AI service, server-side) |
| **Roles** | `learner` · `teacher` |
| **Key acquisition flow** | Free full mock test without login → result by skill → signup → guided path |

---

## 2. Architecture decisions ✅

| Concern | Decision | Rationale |
|---------|----------|-----------|
| State management | Riverpod 2.x (`AsyncNotifier` pattern) | Compile-safe, testable, no boilerplate |
| Routing | GoRouter with ShellRoute + redirect guards | Deep link support, web URL correctness |
| API / networking | Supabase client (primary) + Dio for AI service | Supabase handles auth headers automatically |
| Model generation | `freezed` + `json_serializable` | Immutable models, `copyWith`, JSON codegen |
| Local storage | `shared_preferences` for lightweight flags + fallback answer buffer | No SQLite for MVP |
| Design tokens source | Derived from Stitch-approved UI designs | Single source of truth |
| Font | Be Vietnam Pro (Vietnamese + Latin glyphs) | |
| AI key exposure | Never client-side — all AI calls go through Supabase edge functions | Security |
| Forms | Simple controlled forms (no form library) | MVP speed |
| Responsive rule | Mobile-first; web gets wider containers, NOT different flows | Maintain one codebase |
| Theming | Material 3, `ThemeMode.system`, full dark mode | |
| Codegen entrypoint | `make gen` (build_runner) | Documented in Makefile |

---

## 3. MVP scope

### Included ✅
- Landing page
- Free mock test intro + full exam simulator
- Exam result page (with anonymous → auth linking)
- Signup / Login / Forgot password
- Learner dashboard
- Course overview / Module detail / Lesson detail (6-block structure)
- Practice exercise renderer (MCQ, fill-blank, matching, listening, reading, writing, speaking)
- Speaking AI submission + feedback screen
- Writing AI submission + feedback screen
- Streak + XP gamification
- Leaderboard (weekly + all-time)
- Progress screen (radar chart + streak calendar + exam history)
- Notification settings
- Profile
- Teacher feedback viewer

### Excluded from MVP ⛔
- Live class booking
- Full teacher portal (teacher can insert reviews via Supabase Dashboard for MVP)
- Advanced adaptive learning engine
- Full admin CMS
- Multi-language UI switcher (Vietnamese only for MVP launch)
- Android (Phase 2)
- Subscription / paywall (Phase 2)

---

## 4. Product principles

1. **Exam-first** — every feature exists to improve exam score, not to be a general learning app
2. **Mobile-first** — design and test on 375px first; web is an enhancement
3. **Vietnamese-first UX** — all copy, error messages, and AI prompts in Vietnamese
4. **Short sessions** — lesson structure supports 10–15 min daily study
5. **Clear next best action** — dashboard always shows one primary CTA
6. **Fast MVP** — 14 working days to pilot-ready frontend shell

---

## 5. Route authority

The canonical route list is in [`route-map.md`](route-map.md).  
Route constants are in `lib/core/router/app_routes.dart`.  
**Never hardcode route strings in widgets — always use `AppRoutes.*`.**

---

## 6. Screen authority

The canonical screen list is in [`screen-map.md`](screen-map.md).  
Each screen entry defines its file path, provider, state variants, and data contract.

---

## 7. Component authority

The canonical component list is in [`component-map.md`](component-map.md).  
Naming rule: one widget class per file, suffixed `Screen` (screens) or descriptive (widgets).

---

## 8. Data authority

The canonical model and API shape definitions are in [`data-contract-map.md`](data-contract-map.md).  
Supabase table schemas must match the model definitions there.

---

## 9. State authority

The canonical provider + state class definitions are in [`state-map.md`](state-map.md).  
All new providers must follow the `AsyncNotifier` pattern with a `@freezed` state class.

---

## 10. Build order authority

The canonical day-by-day build plan is in [`build-order-14-days.md`](build-order-14-days.md).  
Each day has acceptance criteria that must pass before moving to the next day.

---

## 11. Environment config

| Flavor | Entry point | Env file |
|--------|-------------|----------|
| `dev` | `lib/main_dev.dart` | `env.dev.json` (gitignored) |
| `staging` | `lib/main_staging.dart` | `env.staging.json` (gitignored) |
| `prod` | `lib/main_prod.dart` | `env.prod.json` (gitignored) |

Run: `make run-web-dev` / `make run-dev` / `make build-web-prod`

---

## 12. Open questions ⚠️

| # | Question | Owner | Needed by |
|---|----------|-------|-----------|
| 1 | What is the AI service base URL for speaking/writing? | Backend | Day 11 |
| 2 | Does speaking scoring support Vietnamese accent specifically? | AI team | Day 12 |
| 3 | What rubric types does writing AI support? (`letter` / `essay` / `form`) | AI team | Day 12 |
| 4 | Is the Supabase `leaderboard_weekly` view pre-built or needs building? | Backend | Day 13 |
| 5 | Teacher review flow for MVP: manual Supabase insert or teacher-facing UI? | Product | Day 13 |
| 6 | Apple Sign-In required for App Store submission (mandatory if any social auth)? | Product | Day 3 |
