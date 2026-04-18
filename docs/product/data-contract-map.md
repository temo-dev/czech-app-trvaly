# Data Contract Map

Source of truth for Supabase tables, Dart models, and Edge Function API shapes.

---

## Supabase Tables

### `profiles`
FK → `auth.users(id)` ON DELETE CASCADE. Auto-created by `handle_new_user()` trigger.

| Column | Type | Default | Notes |
|---|---|---|---|
| id | uuid PK | | mirrors auth.users.id |
| email | text NOT NULL | | |
| display_name | text | | |
| avatar_url | text | | |
| locale | text NOT NULL | `'vi'` | |
| role | text NOT NULL | `'learner'` | CHECK IN ('learner','teacher','admin') |
| exam_date | date | | target exam date |
| daily_goal_minutes | int NOT NULL | `15` | |
| current_streak_days | int NOT NULL | `0` | |
| last_activity_date | date | | used for streak calculation |
| total_xp | int NOT NULL | `0` | |
| weekly_xp | int NOT NULL | `0` | auto-synced to leaderboard_weekly |
| subscription_tier | text NOT NULL | `'free'` | |
| subscription_expires_at | timestamptz | | |
| notification_prefs | jsonb | `{"enabled":true,"reminder_hour":20,"timezone":"Asia/Ho_Chi_Minh"}` | |
| created_at | timestamptz NOT NULL | `now()` | |

RLS: own row select/update; `is_admin()` full access.
View: `public_profiles (id, display_name, avatar_url, total_xp)` — readable by authenticated users.

---

### `exams`

| Column | Type | Default |
|---|---|---|
| id | uuid PK | uuid_generate_v4() |
| title | text NOT NULL | |
| duration_minutes | int NOT NULL | `90` |
| is_active | bool NOT NULL | `true` |
| created_at | timestamptz NOT NULL | `now()` |

RLS: public read; admin full CRUD.

---

### `exam_sections`

| Column | Type | Default | Notes |
|---|---|---|---|
| id | uuid PK | | |
| exam_id | uuid NOT NULL | | FK → exams(id) ON DELETE CASCADE |
| skill | text NOT NULL | | CHECK IN ('reading','listening','writing','speaking') |
| label | text NOT NULL | | Vietnamese display label |
| question_count | int NOT NULL | | |
| section_duration_minutes | int | NULL | NULL = uses global timer |
| order_index | int NOT NULL | `0` | |

Index: `idx_exam_sections_exam_id`. RLS: public read; admin full CRUD.

---

### `questions`

| Column | Type | Default | Notes |
|---|---|---|---|
| id | uuid PK | | |
| section_id | uuid | | FK → exam_sections(id) ON DELETE SET NULL |
| type | text NOT NULL | | CHECK IN ('mcq','fill_blank','matching','ordering','reading_mcq','listening_mcq','speaking','writing') |
| skill | text NOT NULL | | |
| prompt | text NOT NULL | | |
| intro_text | text | | context/passage shown above prompt |
| intro_image_url | text | | image shown above prompt |
| audio_url | text | | |
| image_url | text | | |
| passage_text | text | | |
| correct_answer | text | | |
| explanation | text NOT NULL | `''` | |
| points | int NOT NULL | `1` | |
| order_index | int NOT NULL | `0` | |
| created_at | timestamptz NOT NULL | `now()` | |

Index: `idx_questions_section_id`. RLS: public read; admin full CRUD.

---

### `question_options`

| Column | Type | Default |
|---|---|---|
| id | uuid PK | |
| question_id | uuid NOT NULL | FK → questions(id) ON DELETE CASCADE |
| text | text NOT NULL | |
| image_url | text | |
| is_correct | bool NOT NULL | `false` |
| order_index | int NOT NULL | `0` |

Index: `idx_question_options_question`. RLS: public read; admin full CRUD.

---

### `exam_attempts`

| Column | Type | Default | Notes |
|---|---|---|---|
| id | uuid PK | | |
| exam_id | uuid NOT NULL | | FK → exams(id) |
| user_id | uuid | NULL | FK → profiles(id) ON DELETE SET NULL; NULL = anonymous |
| status | text NOT NULL | `'in_progress'` | CHECK IN ('in_progress','submitted','abandoned') |
| answers | jsonb NOT NULL | `'{}'` | key: `q_${globalIdx}`, value: option UUID or text |
| remaining_seconds | int NOT NULL | `0` | |
| started_at | timestamptz NOT NULL | `now()` | |
| submitted_at | timestamptz | | |

Indexes: `idx_exam_attempts_user_id`, `idx_exam_attempts_exam_id`. RLS: own or anonymous rows; admin read.

---

### `exam_results`

| Column | Type | Default | Notes |
|---|---|---|---|
| id | uuid PK | | |
| attempt_id | uuid NOT NULL | | FK → exam_attempts(id) ON DELETE CASCADE |
| user_id | uuid | | FK → profiles(id) ON DELETE SET NULL |
| total_score | int NOT NULL | `0` | 0–100 |
| pass_threshold | int NOT NULL | `60` | |
| section_scores | jsonb NOT NULL | `'{}'` | `{ skill: { score, total } }` |
| weak_skills | text[] NOT NULL | `'{}'` | skills below 60% |
| created_at | timestamptz NOT NULL | `now()` | |

Indexes: `idx_exam_results_user_id`, `idx_exam_results_attempt_id`. RLS: own/anon read; admin read.

---

### `courses`

| Column | Type | Default |
|---|---|---|
| id | uuid PK | |
| slug | text UNIQUE NOT NULL | |
| title | text NOT NULL | |
| description | text NOT NULL | `''` |
| skill | text NOT NULL | |
| is_premium | bool NOT NULL | `false` |
| thumbnail_url | text | |
| order_index | int NOT NULL | `0` |
| instructor_name | text | |
| instructor_bio | text | |
| duration_days | int NOT NULL | `30` |
| created_at | timestamptz NOT NULL | `now()` |

RLS: public read; admin full CRUD.

---

### `modules`

| Column | Type | Default |
|---|---|---|
| id | uuid PK | |
| course_id | uuid NOT NULL | FK → courses(id) ON DELETE CASCADE |
| title | text NOT NULL | |
| description | text | |
| order_index | int NOT NULL | `0` |
| is_locked | bool NOT NULL | `false` |
| created_at | timestamptz NOT NULL | `now()` |

Index: `idx_modules_course_id`. RLS: public read; admin full CRUD.

---

### `lessons`

| Column | Type | Default |
|---|---|---|
| id | uuid PK | |
| module_id | uuid NOT NULL | FK → modules(id) ON DELETE CASCADE |
| title | text NOT NULL | |
| description | text | |
| order_index | int NOT NULL | `0` |
| duration_minutes | int NOT NULL | `15` |
| bonus_unlocked | bool NOT NULL | `false` |
| bonus_xp_cost | int NOT NULL | `500` |
| created_at | timestamptz NOT NULL | `now()` |

Index: `idx_lessons_module_id`. RLS: public read; admin full CRUD.

---

### `lesson_blocks`

| Column | Type | Default | Notes |
|---|---|---|---|
| id | uuid PK | | |
| lesson_id | uuid NOT NULL | | FK → lessons(id) ON DELETE CASCADE |
| type | text NOT NULL | | CHECK IN ('vocab','grammar','reading','listening','speaking','writing') |
| order_index | int NOT NULL | `0` | 1–6 |

Index: `idx_lesson_blocks_lesson`. RLS: public read; admin full CRUD.
Note: `exercise_id` column was dropped in migration 20260417000004 — replaced by `lesson_block_exercises` junction.

---

### `lesson_block_exercises` (junction)

| Column | Type | Default |
|---|---|---|
| id | uuid PK | |
| block_id | uuid NOT NULL | FK → lesson_blocks(id) ON DELETE CASCADE |
| exercise_id | uuid NOT NULL | FK → exercises(id) ON DELETE CASCADE |
| order_index | int NOT NULL | `0` |
| UNIQUE | (block_id, exercise_id) | |

Index: `idx_lesson_block_exercises_block`. RLS: public read; admin full CRUD.

---

### `exercises`

| Column | Type | Default | Notes |
|---|---|---|---|
| id | uuid PK | | |
| type | text NOT NULL | | 'fill_blank','mcq','reading','listening','speaking','writing' |
| skill | text | NULL | nullable — vocab/grammar blocks have no specific skill |
| difficulty | text NOT NULL | `'intermediate'` | |
| points | int NOT NULL | `10` | |
| content_json | jsonb NOT NULL | `'{}'` | `{prompt, explanation, correct_answer, options:[{id,text,is_correct}], audio_url}` |
| asset_urls | text[] NOT NULL | `'{}'` | |
| xp_reward | int NOT NULL | `10` | |
| created_at | timestamptz NOT NULL | `now()` | |

RLS: public read; admin full CRUD.

---

### `exercise_attempts`

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| exercise_id | uuid NOT NULL | FK → exercises(id) |
| user_id | uuid NOT NULL | FK → profiles(id) ON DELETE CASCADE |
| lesson_block_id | uuid | FK → lesson_blocks(id) ON DELETE SET NULL |
| answer | jsonb NOT NULL | |
| is_correct | bool NOT NULL | |
| xp_awarded | int NOT NULL | |
| attempted_at | timestamptz NOT NULL | |

Indexes: `idx_exercise_attempts_user`, `idx_exercise_attempts_exercise`. RLS: own rows.

---

### `user_progress`

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| user_id | uuid NOT NULL | FK → profiles(id) ON DELETE CASCADE |
| lesson_id | uuid NOT NULL | FK → lessons(id) ON DELETE CASCADE |
| lesson_block_id | uuid | FK → lesson_blocks(id) ON DELETE SET NULL |
| completed_at | timestamptz NOT NULL | |
| UNIQUE | (user_id, lesson_block_id) | |

Indexes: `idx_user_progress_user`, `idx_user_progress_lesson`. RLS: own rows.

---

### `ai_speaking_attempts`

| Column | Type | Default | Notes |
|---|---|---|---|
| id | uuid PK | | |
| user_id | uuid | | FK → profiles(id) ON DELETE SET NULL; nullable (anon) |
| exercise_id | uuid | | FK → exercises(id) ON DELETE SET NULL |
| audio_key | text | | Storage path |
| status | text NOT NULL | `'processing'` | CHECK IN ('processing','ready','error') |
| overall_score | int | | 0–100 |
| metrics | jsonb | | `{pronunciation,fluency,vocabulary,task_achievement, *_feedback,*_tip, overall_feedback, short_tips}` |
| transcript | text | | |
| issues | jsonb | | `[{word, type?, suggestion}]` |
| strengths | text[] | | |
| improvements | text[] | | |
| corrected_answer | text | | |
| error_message | text | | |
| created_at | timestamptz NOT NULL | `now()` | |
| updated_at | timestamptz NOT NULL | `now()` | |

Index: `idx_ai_speaking_user`. RLS: own rows; service_role full access.

---

### `ai_writing_attempts`

| Column | Type | Default | Notes |
|---|---|---|---|
| id | uuid PK | | |
| user_id | uuid | | FK → profiles(id) ON DELETE SET NULL; nullable |
| exercise_id | uuid | | FK → exercises(id) ON DELETE SET NULL |
| prompt_text | text | | |
| answer_text | text | | |
| rubric_type | text | | CHECK IN ('letter','essay','form') |
| status | text NOT NULL | `'processing'` | CHECK IN ('processing','ready','error') |
| overall_score | int | | 0–100 |
| metrics | jsonb | | `{grammar,vocabulary,coherence,task_achievement, *_feedback, overall_feedback, short_tips}` |
| grammar_notes | jsonb | | annotated_spans `[{text, issue_type, correction?, explanation?, tip?}]` |
| vocabulary_notes | jsonb | | `[{overall_feedback}]` |
| corrected_essay | text | | |
| error_message | text | | |
| created_at | timestamptz NOT NULL | `now()` | |
| updated_at | timestamptz NOT NULL | `now()` | |

Index: `idx_ai_writing_user`. RLS: own rows; service_role full access.

---

### `teacher_reviews`

| Column | Type | Default |
|---|---|---|
| id | uuid PK | |
| user_id | uuid NOT NULL | FK → profiles(id) ON DELETE CASCADE |
| skill | text NOT NULL | CHECK IN ('writing','speaking') |
| status | text NOT NULL | `'pending'` CHECK IN ('pending','reviewed','closed') |
| preview_text | text | |
| unread_count | int NOT NULL | `0` |
| created_at | timestamptz NOT NULL | `now()` |

Index: `idx_teacher_reviews_user`. RLS: learner sees own; admin full CRUD.

---

### `teacher_comments`

| Column | Type | Default |
|---|---|---|
| id | uuid PK | |
| review_id | uuid NOT NULL | FK → teacher_reviews(id) ON DELETE CASCADE |
| body | text NOT NULL | |
| is_teacher | bool NOT NULL | `false` |
| author_name | text | |
| created_at | timestamptz NOT NULL | `now()` |

Index: `idx_teacher_comments_review`. RLS: learner reads own thread; teacher role can insert; admin full CRUD.

---

### `leaderboard_weekly`

| Column | Type | Default | Notes |
|---|---|---|---|
| id | uuid PK | | |
| user_id | uuid NOT NULL | | FK → profiles(id) ON DELETE CASCADE |
| display_name | text NOT NULL | | |
| avatar_url | text | | |
| weekly_xp | int NOT NULL | `0` | |
| week_start | date NOT NULL | `date_trunc('week',now())::date` | |
| UNIQUE | (user_id, week_start) | | |

Index: `idx_leaderboard_weekly_xp` on `weekly_xp DESC`. RLS: public read.
Auto-populated via `trg_sync_profile_to_leaderboard` trigger — no manual writes needed.

---

### `friendships`

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| requester_id | uuid NOT NULL | FK → auth.users(id) ON DELETE CASCADE |
| addressee_id | uuid NOT NULL | FK → auth.users(id) ON DELETE CASCADE |
| status | text NOT NULL | CHECK IN ('pending','accepted','declined') DEFAULT 'pending' |
| created_at | timestamptz NOT NULL | |
| UNIQUE | (requester_id, addressee_id) | |
| CHECK | requester_id <> addressee_id | |

Indexes: `idx_friendships_requester`, `idx_friendships_addressee`. Realtime: enabled.
RLS: view if requester or addressee; insert if requester; update if addressee; delete if either party.

---

### `dm_rooms` / `dm_members` / `dm_messages`

**`dm_rooms`**: `id, created_at`. RLS: visible only to members.

**`dm_members`**: `(room_id, user_id)` composite PK; `last_read_at`, `joined_at`. Index: `idx_dm_members_user`. Realtime: enabled.

**`dm_messages`**: `id, room_id, sender_id, message_type CHECK IN ('text','image','file'), body (1–4000 chars for text), attachment_url/name/size/mime, created_at`. Index: `idx_dm_messages_room` on `(room_id, created_at DESC)`. Realtime: enabled.

---

## RPCs & Functions

| Name | Signature | Purpose |
|---|---|---|
| `handle_new_user()` | trigger | Auto-creates profile on auth signup. SECURITY DEFINER. |
| `increment_xp` | `(p_user_id uuid, p_amount int) → void` | Atomic XP increment on profiles. |
| `refresh_leaderboard_weekly` | `() → void` | Batch upsert profiles.weekly_xp → leaderboard_weekly. |
| `sync_profile_to_leaderboard` | trigger | Auto-upserts to leaderboard_weekly on profile INSERT or UPDATE of weekly_xp/display_name/avatar_url. |
| `unlock_lesson_bonus` | `(p_lesson_id uuid, p_user_id uuid) → void` | Deducts XP, marks lesson.bonus_unlocked = true. Raises: 'lesson_not_found', 'insufficient_xp'. |
| `find_or_create_dm` | `(other_user_id uuid) → uuid` | Checks friendship is 'accepted', finds or creates DM room. Raises: 'not_friends'. SECURITY DEFINER. |
| `is_admin` | `() → boolean STABLE` | Returns profiles.role = 'admin' for current user. Used in all admin RLS policies. |
| `cms_dashboard_stats` | `() → jsonb` | Aggregate stats for CMS dashboard. Admin-only. |

---

## Storage Buckets

| Bucket | Public | Max size | MIME | Upload policy |
|---|---|---|---|---|
| `chat-attachments` | true | — | any | Authenticated upload to `{user_id}/{room_id}/{uuid}_{filename}` |
| `cms-assets` | true | 10 MB | image/*, audio/*, video/* | Admin upload/update/delete |

---

## Dart Models

### `AppUser` — `lib/shared/models/user_model.dart` (Freezed)

```dart
String id, email
String? displayName, avatarUrl
String locale              // default 'vi'
DateTime? examDate
int dailyGoalMinutes       // default 0
int currentStreakDays       // default 0
int totalXp, weeklyXp      // default 0
DateTime? lastActivityDate
SubscriptionTier subscriptionTier  // .free
DateTime? subscriptionExpiresAt
DateTime? createdAt
```

Enum `SubscriptionTier { free, premium }`.
Extensions: `isPremium`, `hasExamDate`, `initials`.

---

### `Question` — `lib/shared/models/question_model.dart` (Freezed)

```dart
String id, prompt, explanation
QuestionType type
SkillArea skill
Difficulty difficulty
String? introText, introImageUrl, audioUrl, imageUrl, correctAnswer
List<QuestionOption> options          // default []
List<MatchPair> matchPairs            // default []
List<String> orderItems               // default []
int points                            // default 0
```

Sub-models:
- `QuestionOption { id, text, imageUrl?, isCorrect }`
- `MatchPair { leftId, leftText, rightId, rightText }`
- `QuestionAnswer { questionId, selectedOptionId?, writtenAnswer?, audioKey?, selectedOptionIds, orderedIds, matchedPairs, isFlagged, timeSpentSeconds? }`

Enums:
- `QuestionType { mcq, fillBlank, matching, ordering, speaking, writing }`
- `SkillArea { reading, listening, writing, speaking, vocabulary, grammar }`
- `Difficulty { beginner, intermediate, advanced }`

---

### `ExamResult` — `lib/shared/models/exam_result_model.dart` (Freezed)

```dart
String id, userId
ExamType type
int totalScore             // 0–100
int totalQuestions, correctAnswers
Map<String, int> sectionScores, sectionTotals
List<QuestionAnswer> answers
DateTime completedAt
int passThreshold          // default 60
List<String> weakSkills
String? recommendation
int? totalTimeSeconds
```

Enums: `ExamType { mockTest, fullSimulator, practiceSet }`, `ScoreBand { excellent, good, fair, poor }`.
Extensions: `passed`, `band`, `accuracy`.

---

### `Exercise` — `lib/features/exercise/models/exercise_model.dart` (Freezed)

```dart
String id
QuestionType type
SkillArea skill
Difficulty difficulty
String contentJson         // raw JSON string — deserialize to access prompt/options/etc.
List<String> assetUrls
int xpReward
DateTime? createdAt
```

Sub-model: `ExerciseAttempt { id, exerciseId, userId, answer (QuestionAnswer), isCorrect, xpAwarded, attemptedAt }`.

---

### `ExamAttempt` — `lib/features/mock_test/models/exam_attempt.dart` (Freezed)

```dart
String id, examId
String? userId             // null = anonymous
String status              // 'in_progress' | 'submitted'
Map<String, dynamic> answers
int? remainingSeconds
DateTime? startedAt, submittedAt
```

---

### `ExamMeta` — `lib/features/mock_test/models/exam_meta.dart` (Freezed)

```dart
String id, title
int durationMinutes
List<SectionMeta> sections
// computed: totalQuestions
```

`SectionMeta { id, skill, label, questionCount, sectionDurationMinutes?, orderIndex }`.

---

### `MockTestResult` — `lib/features/mock_test/models/mock_test_result.dart` (Freezed)

```dart
String id, attemptId
String? userId
int totalScore             // 0–100
int passThreshold
Map<String, SectionResult> sectionScores
List<String> weakSkills
DateTime createdAt
// computed: passed, band
```

`SectionResult { score, total }` — computed: `percentage`.

---

### Course Models — `lib/features/course/models/course_models.dart` (plain Dart)

| Class | Key fields |
|---|---|
| `CourseDetail` | id, slug, title, description, skill, isPremium, modules, overallProgress, thumbnailUrl?, instructorName?, instructorBio?, durationDays |
| `ModuleSummary` | id, courseId, title, orderIndex, lessonCount, completedCount, isLocked, description? — computed: `progressFraction` |
| `ModuleDetail` | module, courseTitle, lessons |
| `LessonSummary` | id, moduleId, title, orderIndex, status (LessonStatus), durationMinutes |
| `LessonDetail` | lesson, courseId, courseTitle, moduleId, moduleTitle, blocks, bonusUnlocked, bonusXpCost — computed: `completedBlockCount`, `allBlocksDone` |
| `LessonBlock` | id, lessonId, type (BlockType), exerciseIds (List\<String\>), orderIndex, status (BlockStatus), prompt? — computed: `hasExercises` |

Enums: `LessonStatus { locked, available, inProgress, completed }`, `BlockType { vocab, grammar, reading, listening, speaking, writing }`, `BlockStatus { pending, inProgress, completed }`.

---

### Dashboard Models — `lib/features/dashboard/models/dashboard_models.dart` (plain Dart)

| Class | Key fields |
|---|---|
| `LeaderboardRow` | userId, displayName, avatarUrl?, weeklyXp, rank, isCurrentUser |
| `RecommendedLesson` | lessonId, lessonTitle, moduleTitle, skill, courseId, moduleId, courseSlug |
| `CourseProgress` | courseId, courseSlug, courseTitle, skill, completedLessons, totalLessons — computed: `progressFraction` |
| `DashboardData` | user (AppUser), latestResult?, recommendation?, leaderboardPreview, ownRank?, activeCourse? — computed: `hasResult` |

---

### Chat Models — `lib/features/chat/models/` (plain Dart)

**`DmConversation`**: `roomId, peerId, peerName, peerAvatarUrl?, lastMessage?, unreadCount, lastActivityAt?`

**`ChatMessage`**: `id, roomId, senderId, messageType (MessageType), body?, attachmentUrl?, attachmentName?, attachmentSize?, attachmentMime?, createdAt, senderName?, seerAvatarUrl?` — helper: `previewText`.

**`Friendship`**: `id, requesterId, addresseeId, status (FriendshipStatus), createdAt`.

**`UserProfile`** (friend search): `id, displayName, avatarUrl?, totalXp, friendshipStatus?, friendshipId?, isRequester?` — helpers: `isFriend`, `isPending`.

Enums: `MessageType { text, image, file }`, `FriendshipStatus { pending, accepted, declined }`.

---

## Edge Function API Shapes

All functions are Deno-based, deployed at `/functions/v1/<name>`. Authentication via Bearer token header (`supabase.auth.currentSession?.accessToken`).

### `grade-exam`
**POST** `{ attempt_id: string }`
**Response** `{ success, attempt_id, total_score, section_scores: {[skill]: {score, total}}, weak_skills: string[] }`

Grading rules: MCQ → option UUID match; fill_blank → case-insensitive trim; matching/ordering → 50% credit; speaking/writing → 50% if answered.

---

### `question-feedback`
**POST** `{ question_text, options?, correct_answer_text, user_answer_text, section_skill? }`
**Response** `{ error_analysis, correct_explanation, short_tip, key_concept }` (all in Vietnamese)

---

### `speaking-upload`
**POST** `{ lesson_id?, question_id, audio_b64? }`
**Response** `{ attempt_id: string }`

Creates `ai_speaking_attempts` row, transcribes via Whisper, scores via GPT-4.1-mini. Czech enforcement: if Whisper language ≠ Czech OR GPT `is_czech=false` → all scores zero.
Poll `speaking-result` for final result.

---

### `speaking-result`
**POST** `{ attempt_id: string }`
**Response (processing)** `{ status: 'pending' }`
**Response (error)** `{ status: 'error', message }`
**Response (ready)**
```json
{
  "status": "ready",
  "attempt_id": "...",
  "total_score": 75,
  "max_score": 100,
  "metrics": [
    { "label": "Phát âm", "score": 80, "max_score": 100, "feedback": "...", "tip": "..." },
    { "label": "Lưu loát", "score": 70, "max_score": 100, "feedback": "...", "tip": "..." },
    { "label": "Từ vựng", "score": 75, "max_score": 100, "feedback": "...", "tip": "..." },
    { "label": "Ngữ pháp", "score": 75, "max_score": 100, "feedback": "...", "tip": "..." }
  ],
  "transcript": "...",
  "transcript_words": [{ "word": "...", "issue": "...", "suggestion": "..." }],
  "corrections": "...",
  "short_tips": ["..."],
  "overall_feedback": "..."
}
```

---

### `writing-submit`
**POST** `{ text, question_id, lesson_id? }`
**Response** `{ attempt_id: string }`

Detects rubric_type: 'letter' (dopis/email/napište), 'form' (formulář/form), else 'essay'.
Poll `writing-result` for final result.

---

### `writing-result`
**POST** `{ attempt_id: string }`
**Response (ready)**
```json
{
  "status": "ready",
  "attempt_id": "...",
  "total_score": 72,
  "max_score": 100,
  "metrics": [
    { "label": "Ngữ pháp", "score": 70, "max_score": 100, "feedback": "..." },
    { "label": "Từ vựng", "score": 75, "max_score": 100, "feedback": "..." },
    { "label": "Mạch lạc & Hình thức", "score": 70, "max_score": 100, "feedback": "..." },
    { "label": "Nội dung", "score": 72, "max_score": 100, "feedback": "..." }
  ],
  "annotated_spans": [{ "text": "...", "issue_type": "...", "correction": "...", "explanation": "...", "tip": "..." }],
  "short_tips": ["..."],
  "corrected_version": "...",
  "overall_feedback": "..."
}
```
