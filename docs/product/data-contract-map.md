# Data Contract Map — Trvalý Prep MVP
> Dart model classes · Supabase tables · AI service endpoints
> All models use `freezed` + `json_serializable`.
> File paths relative to `lib/`

---

## Supabase table reference

| Table | Primary purpose |
|-------|----------------|
| `profiles` | User account data, XP, streak, prefs |
| `exams` | Exam metadata (title, duration, section config) |
| `exam_sections` | Section definitions per exam |
| `questions` | Question bank |
| `question_options` | MCQ options per question |
| `exam_attempts` | One row per exam session (anon or authed) |
| `exam_answers` | Per-question answers within an attempt |
| `courses` | Course catalogue |
| `modules` | Modules within a course |
| `lessons` | Lessons within a module |
| `lesson_blocks` | 6 ordered blocks per lesson (links to exercises) |
| `exercises` | Exercise content (type + content_json + assets) |
| `exercise_attempts` | Per-exercise submission history |
| `ai_speaking_attempts` | Speaking submissions → AI feedback |
| `ai_writing_attempts` | Writing submissions → AI feedback |
| `leaderboard_weekly` | Materialised view — refreshed nightly |
| `user_progress` | Per-lesson completion state |
| `teacher_reviews` | Teacher manual feedback records |
| `teacher_comments` | Comment rows per review |
| `notification_prefs` | Per-user reminder config |

---

## Core models

### AppUser
```dart
// lib/shared/models/user_model.dart
@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String id,                    // = auth.uid
    required String email,
    String? displayName,
    String? avatarUrl,
    @Default('vi') String locale,
    @Default(UserRole.learner) UserRole role,
    DateTime? examDate,
    @Default(0) int totalXp,
    @Default(0) int weeklyXp,
    @Default(0) int streakDays,
    DateTime? lastActivityDate,
    NotificationPrefs? notificationPrefs,
    DateTime? createdAt,
  }) = _AppUser;
  factory AppUser.fromJson(Map<String, dynamic> json) => ...;
}
enum UserRole { learner, teacher }
```
**Supabase table**: `profiles`  
**Fetch**: `supabase.from('profiles').select().eq('id', userId).single()`

---

### ExamMeta
```dart
// lib/features/mock_test/models/exam_meta.dart
@freezed
class ExamMeta with _$ExamMeta {
  const factory ExamMeta({
    required String id,
    required String title,
    required int durationMinutes,
    required List<SectionMeta> sections,
  }) = _ExamMeta;
}

@freezed
class SectionMeta with _$SectionMeta {
  const factory SectionMeta({
    required String id,
    required String skill,               // 'reading' | 'listening' | 'writing' | 'speaking'
    required String label,
    required int questionCount,
    int? sectionDurationMinutes,         // null = shared global timer
  }) = _SectionMeta;
}
```
**Supabase**: `exams` JOIN `exam_sections`

---

### ExamAttempt (session state)
```dart
// lib/features/mock_test/models/exam_attempt.dart
@freezed
class ExamAttempt with _$ExamAttempt {
  const factory ExamAttempt({
    required String id,
    required String examId,
    String? userId,                      // null if anonymous
    required String status,              // 'in_progress' | 'submitted'
    required Map<String, Answer> answers,
    required int remainingSeconds,
    DateTime? startedAt,
    DateTime? submittedAt,
  }) = _ExamAttempt;
}
```

**Create attempt**
```
POST /functions/v1/create-exam-attempt
Body: { examId: string, anonymousSessionId?: string }
Returns: { attemptId: string, examData: ExamSession }
```

**Autosave answers**
```
PATCH exam_attempts/:id
Body: { answers: { [questionId]: Answer }, remaining_seconds: int }
```

**Submit**
```
POST /functions/v1/submit-exam-attempt
Body: { attemptId: string }
Returns: { resultId: string }
```

---

### ExamResult
```dart
// lib/shared/models/exam_result_model.dart
@freezed
class ExamResult with _$ExamResult {
  const factory ExamResult({
    required String id,
    required String attemptId,
    required int totalScore,             // 0–100
    required int passThreshold,          // 60 for Trvalý
    required Map<String, SectionScore> sectionScores,
    required List<String> weakSkills,
    RecommendationSummary? recommendation,
    required DateTime completedAt,
  }) = _ExamResult;
}

@freezed
class SectionScore with _$SectionScore {
  const factory SectionScore({
    required int score,
    required int total,
  }) = _SectionScore;
}
```
**Fetch**: `supabase.from('exam_results').select().eq('attempt_id', attemptId).single()`

---

### Question
```dart
// lib/shared/models/question_model.dart
@freezed
class Question with _$Question {
  const factory Question({
    required String id,
    required QuestionType type,
    required String skill,
    required String prompt,
    String? audioUrl,                    // S3 key for listening
    String? imageUrl,                    // S3 key for reading exhibit
    String? passageText,                 // for reading_mcq
    @Default([]) List<QuestionOption> options,
    String? correctAnswer,               // fill_blank, speaking rubric ref
    required String explanation,
    @Default(1) int points,
  }) = _Question;
}

enum QuestionType { mcq, fillBlank, matching, ordering, readingMcq, listeningMcq, speaking, writing }

@freezed
class QuestionOption with _$QuestionOption {
  const factory QuestionOption({
    required String id,
    required String text,
    String? imageUrl,
    @Default(false) bool isCorrect,      // only present server-side; stripped for client before answer
  }) = _QuestionOption;
}
```

---

### Answer
```dart
// lib/shared/models/answer_model.dart
@freezed
class Answer with _$Answer {
  const factory Answer({
    required String questionId,
    String? selectedOptionId,            // mcq
    List<String>? selectedOptionIds,     // multi-select
    String? writtenText,                 // fill_blank / writing
    List<String>? orderedIds,           // ordering
    Map<String, String>? matches,       // matching: { leftId: rightId }
    String? audioKey,                   // speaking: S3 key
    @Default(false) bool isFlagged,
    int? timeSpentSeconds,
  }) = _Answer;
}
```

---

### Course / Module / Lesson
```dart
// lib/features/course/models/

@freezed
class Course with _$Course {
  const factory Course({
    required String id,
    required String slug,
    required String title,
    required String description,
    required String skill,
    @Default(false) bool isPremium,
    String? thumbnailUrl,
  }) = _Course;
}

@freezed
class ModuleSummary with _$ModuleSummary {
  const factory ModuleSummary({
    required String id,
    required String courseId,
    required String title,
    required int orderIndex,
    required int lessonCount,
    required int completedCount,
    @Default(false) bool isLocked,
  }) = _ModuleSummary;
}

@freezed
class LessonSummary with _$LessonSummary {
  const factory LessonSummary({
    required String id,
    required String moduleId,
    required String title,
    required LessonStatus status,
    required int orderIndex,
  }) = _LessonSummary;
}

enum LessonStatus { locked, available, inProgress, completed }

@freezed
class LessonBlock with _$LessonBlock {
  const factory LessonBlock({
    required String id,
    required String lessonId,
    required BlockType type,
    required String exerciseId,
    required int orderIndex,            // 1–6
    @Default(BlockStatus.pending) BlockStatus status,
  }) = _LessonBlock;
}

enum BlockType { vocab, grammar, reading, listening, speaking, writing }
enum BlockStatus { pending, inProgress, completed }
```

---

### Exercise
```dart
// lib/features/exercise/models/exercise.dart
@freezed
class Exercise with _$Exercise {
  const factory Exercise({
    required String id,
    required QuestionType type,
    required String skill,
    required Map<String, dynamic> contentJson,   // parsed by exercise renderer
    List<String>? assetUrls,                     // presigned S3 URLs
    int? xpReward,
  }) = _Exercise;
}
```

**Fetch**: `supabase.from('exercises').select().eq('id', exerciseId).single()`  
Asset URLs: `supabase.functions.invoke('get-exercise-assets', body: { exerciseId })`

---

### ExerciseAttempt
```dart
@freezed
class ExerciseAttempt with _$ExerciseAttempt {
  const factory ExerciseAttempt({
    required String id,
    required String exerciseId,
    required String userId,
    required Answer answer,
    required bool isCorrect,
    required int xpAwarded,
    required DateTime attemptedAt,
  }) = _ExerciseAttempt;
}
```

**Submit**
```
POST exercise_attempts
Body: { exerciseId, lessonBlockId, answer: Answer }
Returns: { isCorrect, explanation, xpAwarded, nextBlockId? }
```

---

## AI service contracts

### Speaking AI

**Upload audio**
```
POST /functions/v1/speaking-upload
Content-Type: multipart/form-data
Body: { file: audioFile, exerciseId, userId }
Returns: { attemptId: string, audioKey: string }
```

**Poll for result**
```
GET /functions/v1/speaking-result/:attemptId
Returns (processing): { status: 'processing' }
Returns (ready):
{
  status: 'ready',
  attemptId: string,
  overallScore: int,           // 0–100
  metrics: {
    pronunciation: int,
    fluency: int,
    vocabulary: int,
  },
  transcript: string,
  issues: [{ word: string, suggestion: string }],
  strengths: string[],
  improvements: string[],
  correctedAnswer: string,
}
Returns (error): { status: 'error', message: string }
```

**Poll interval**: every 3s, max 10 attempts  
**Supabase table**: `ai_speaking_attempts`

---

### Writing AI

**Submit writing**
```
POST /functions/v1/writing-submit
Body: {
  exerciseId: string,
  userId: string,
  promptText: string,
  answerText: string,
  rubricType: 'letter' | 'essay' | 'form',
}
Returns: { attemptId: string }
```

**Poll for result**
```
GET /functions/v1/writing-result/:attemptId
Returns (ready):
{
  status: 'ready',
  attemptId: string,
  overallScore: int,
  metrics: {
    grammar: int,
    vocabulary: int,
    coherence: int,
    taskAchievement: int,
  },
  grammarNotes: [{ original: string, corrected: string, explanation: string }],
  vocabularyNotes: [{ original: string, suggestion: string }],
  correctedEssay: string,
  processingStatus: 'ready',
}
```
**Supabase table**: `ai_writing_attempts`

---

## Teacher feedback contracts

### TeacherReview
```dart
@freezed
class TeacherReview with _$TeacherReview {
  const factory TeacherReview({
    required String id,
    required String reviewerName,
    required String submissionType,    // 'speaking' | 'writing'
    required String submissionRef,     // attemptId reference
    required int score,
    required List<TeacherComment> comments,
    required DateTime submittedAt,
    required DateTime reviewedAt,
  }) = _TeacherReview;
}

@freezed
class TeacherComment with _$TeacherComment {
  const factory TeacherComment({
    required String id,
    required String body,
    required DateTime createdAt,
  }) = _TeacherComment;
}
```

**Fetch**: `supabase.from('teacher_reviews').select('*, teacher_comments(*)').eq('id', reviewId).single()`

---

## Gamification contracts

### XP award flow
```
// Called after any exercise_attempt POST
POST /functions/v1/award-xp
Body: { userId, eventType: 'exercise' | 'lesson' | 'exam', referenceId }
Returns: { xpAwarded, newTotal, streakDays, rankChange? }
```

### Anonymous → authenticated session linking
```
// Called on signup if pendingAttemptId in shared_preferences
PATCH exam_attempts/:attemptId
Body: { user_id: string }
// RLS: only allowed if userId is null AND within 24h of creation
```

---

## Notification preferences
```dart
// lib/features/notifications/models/notification_prefs.dart
@freezed
class NotificationPrefs with _$NotificationPrefs {
  const factory NotificationPrefs({
    @Default(true) bool enabled,
    @Default(20) int reminderHour,
    @Default('Asia/Ho_Chi_Minh') String timezone,
  }) = _NotificationPrefs;
}
```
**Supabase**: `profiles.notification_prefs` (jsonb column)  
**Update**: `supabase.from('profiles').update({ 'notification_prefs': prefs.toJson() }).eq('id', userId)`

---

## Row Level Security (RLS) summary

| Table | Read | Write |
|-------|------|-------|
| `profiles` | own row only | own row only |
| `exams`, `questions` | all | admin only |
| `exam_attempts` | own + anon by session | own + anon by session |
| `exercise_attempts` | own | own |
| `ai_speaking_attempts` | own | via edge function |
| `ai_writing_attempts` | own | via edge function |
| `leaderboard_weekly` | all (public) | edge function only |
| `teacher_reviews` | own (learner) | teacher role |
| `teacher_comments` | own (learner) | teacher role |
| `user_progress` | own | own |
