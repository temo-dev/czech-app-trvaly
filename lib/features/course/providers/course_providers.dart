import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_czech/core/supabase/supabase_config.dart';
import 'package:app_czech/features/course/models/course_models.dart';
import 'package:app_czech/shared/providers/auth_provider.dart';

// ── Course detail ─────────────────────────────────────────────────────────────

/// Fetches full course with module list and per-module completion progress.
/// courseId can be a UUID or slug — tries both.
final courseDetailProvider = FutureProvider.autoDispose
    .family<CourseDetail, String>((ref, courseId) async {
  // Try by id, then by slug
  final courseRaw = await _fetchCourse(courseId);
  if (courseRaw == null) throw Exception('Không tìm thấy khóa học.');

  final course = Map<String, dynamic>.from(courseRaw as Map);
  final actualId = course['id'] as String;

  // Fetch modules ordered by index
  final modulesRaw = await supabase
      .from('modules')
      .select()
      .eq('course_id', actualId)
      .order('order_index');

  final moduleIds =
      (modulesRaw as List).map((m) => (m as Map)['id'] as String).toList();

  // Fetch lesson counts per module
  final Map<String, int> lessonCountPerModule = {};
  final Map<String, int> completedCountPerModule = {};

  if (moduleIds.isNotEmpty) {
    final lessonsRaw = await supabase
        .from('lessons')
        .select('id, module_id')
        .inFilter('module_id', moduleIds);

    for (final l in (lessonsRaw as List)) {
      final lm = Map<String, dynamic>.from(l as Map);
      final mId = lm['module_id'] as String;
      lessonCountPerModule[mId] = (lessonCountPerModule[mId] ?? 0) + 1;
    }

    // Fetch user's completed lessons
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      final lessonIds =
          (lessonsRaw).map((l) => (l as Map)['id'] as String).toList();
      if (lessonIds.isNotEmpty) {
        final progressRaw = await supabase
            .from('user_progress')
            .select('lesson_id, lesson_block_id')
            .eq('user_id', userId)
            .inFilter('lesson_id', lessonIds);

        // A lesson is "complete" when it has ≥ 6 block entries
        final Map<String, Set<String>> blocksPerLesson = {};
        for (final p in (progressRaw as List)) {
          final pm = Map<String, dynamic>.from(p as Map);
          final lId = pm['lesson_id'] as String;
          final bId = pm['lesson_block_id'] as String;
          blocksPerLesson.putIfAbsent(lId, () => {}).add(bId);
        }

        // Map lesson → module
        final Map<String, String> lessonToModule = {};
        for (final l in lessonsRaw) {
          final lm2 = Map<String, dynamic>.from(l as Map);
          lessonToModule[lm2['id'] as String] = lm2['module_id'] as String;
        }

        for (final entry in blocksPerLesson.entries) {
          if (entry.value.length >= 6) {
            final mId = lessonToModule[entry.key];
            if (mId != null) {
              completedCountPerModule[mId] =
                  (completedCountPerModule[mId] ?? 0) + 1;
            }
          }
        }
      }
    }
  }

  final modules = (modulesRaw as List).asMap().entries.map((e) {
    final mm = Map<String, dynamic>.from(e.value as Map);
    final mId = mm['id'] as String;
    return ModuleSummary(
      id: mId,
      courseId: actualId,
      title: mm['title'] as String,
      orderIndex: mm['order_index'] as int? ?? e.key,
      lessonCount: lessonCountPerModule[mId] ?? 0,
      completedCount: completedCountPerModule[mId] ?? 0,
      isLocked: mm['is_locked'] as bool? ?? false,
      description: mm['description'] as String?,
    );
  }).toList();

  final total = modules.fold<int>(0, (s, m) => s + m.lessonCount);
  final done = modules.fold<int>(0, (s, m) => s + m.completedCount);

  return CourseDetail(
    id: actualId,
    slug: course['slug'] as String? ?? courseId,
    title: course['title'] as String,
    description: course['description'] as String? ?? '',
    skill: course['skill'] as String? ?? '',
    isPremium: course['is_premium'] as bool? ?? false,
    thumbnailUrl: course['thumbnail_url'] as String?,
    modules: modules,
    overallProgress: total > 0 ? done / total : 0,
    instructorName: course['instructor_name'] as String?,
    instructorBio: course['instructor_bio'] as String?,
    durationDays: course['duration_days'] as int? ?? 30,
  );
});

Future<dynamic> _fetchCourse(String courseId) async {
  final byId = await supabase
      .from('courses')
      .select()
      .eq('id', courseId)
      .maybeSingle();
  if (byId != null) return byId;
  return supabase
      .from('courses')
      .select()
      .eq('slug', courseId)
      .maybeSingle();
}

// ── Module detail ─────────────────────────────────────────────────────────────

/// Fetches module with its lesson list and per-lesson status.
final moduleDetailProvider = FutureProvider.autoDispose
    .family<ModuleDetail, String>((ref, moduleId) async {
  final userId = supabase.auth.currentUser?.id;

  // Fetch module
  final moduleRaw = await supabase
      .from('modules')
      .select()
      .eq('id', moduleId)
      .maybeSingle();
  if (moduleRaw == null) throw Exception('Không tìm thấy module.');

  final module = Map<String, dynamic>.from(moduleRaw as Map);
  final courseId = module['course_id'] as String;

  // Fetch course title for breadcrumb
  final courseRaw =
      await supabase.from('courses').select('title').eq('id', courseId).single();
  final courseTitle = (courseRaw as Map)['title'] as String? ?? '';

  // Fetch lessons ordered
  final lessonsRaw = await supabase
      .from('lessons')
      .select()
      .eq('module_id', moduleId)
      .order('order_index');

  // Fetch user progress block counts per lesson
  final Map<String, int> completedBlocksPerLesson = {};
  final Map<String, int> totalBlocksPerLesson = {};

  if ((lessonsRaw as List).isNotEmpty) {
    final lessonIds =
        lessonsRaw.map((l) => (l as Map)['id'] as String).toList();

    // Count blocks per lesson
    final blocksRaw = await supabase
        .from('lesson_blocks')
        .select('id, lesson_id')
        .inFilter('lesson_id', lessonIds);

    for (final b in (blocksRaw as List)) {
      final bm = Map<String, dynamic>.from(b as Map);
      final lId = bm['lesson_id'] as String;
      totalBlocksPerLesson[lId] = (totalBlocksPerLesson[lId] ?? 0) + 1;
    }

    if (userId != null) {
      final progressRaw = await supabase
          .from('user_progress')
          .select('lesson_id, lesson_block_id')
          .eq('user_id', userId)
          .inFilter('lesson_id', lessonIds);

      for (final p in (progressRaw as List)) {
        final pm = Map<String, dynamic>.from(p as Map);
        final lId = pm['lesson_id'] as String;
        completedBlocksPerLesson[lId] =
            (completedBlocksPerLesson[lId] ?? 0) + 1;
      }
    }
  }

  final isModuleLocked = module['is_locked'] as bool? ?? false;

  final lessons = (lessonsRaw as List).asMap().entries.map((e) {
    final lm = Map<String, dynamic>.from(e.value as Map);
    final lId = lm['id'] as String;
    final completed = completedBlocksPerLesson[lId] ?? 0;
    final total = totalBlocksPerLesson[lId] ?? 6;
    return LessonSummary(
      id: lId,
      moduleId: moduleId,
      title: lm['title'] as String,
      orderIndex: lm['order_index'] as int? ?? e.key,
      status: lessonStatusFromCounts(
        completed,
        total,
        isLocked: isModuleLocked,
      ),
      durationMinutes: lm['duration_minutes'] as int? ?? 15,
    );
  }).toList();

  return ModuleDetail(
    module: ModuleSummary(
      id: moduleId,
      courseId: courseId,
      title: module['title'] as String,
      orderIndex: module['order_index'] as int? ?? 0,
      lessonCount: lessons.length,
      completedCount: lessons
          .where((l) => l.status == LessonStatus.completed)
          .length,
      isLocked: isModuleLocked,
      description: module['description'] as String?,
    ),
    courseTitle: courseTitle,
    lessons: lessons,
  );
});

// ── Lesson detail ─────────────────────────────────────────────────────────────

/// Fetches lesson with its 6 blocks and per-block completion status.
final lessonDetailProvider = FutureProvider.autoDispose
    .family<LessonDetail, String>((ref, lessonId) async {
  final userId = supabase.auth.currentUser?.id;

  // Fetch lesson
  final lessonRaw = await supabase
      .from('lessons')
      .select()
      .eq('id', lessonId)
      .maybeSingle();
  if (lessonRaw == null) throw Exception('Không tìm thấy bài học.');

  final lesson = Map<String, dynamic>.from(lessonRaw as Map);
  final moduleId = lesson['module_id'] as String;

  // Fetch module + course for breadcrumbs
  final moduleRaw = await supabase
      .from('modules')
      .select('id, course_id, title')
      .eq('id', moduleId)
      .single();
  final moduleMeta = Map<String, dynamic>.from(moduleRaw as Map);
  final courseId = moduleMeta['course_id'] as String;

  final courseRaw = await supabase
      .from('courses')
      .select('id, title, skill')
      .eq('id', courseId)
      .single();
  final courseMeta = Map<String, dynamic>.from(courseRaw as Map);

  // Fetch blocks ordered, joining exercises to get prompt for AI screens
  final blocksRaw = await supabase
      .from('lesson_blocks')
      .select('*, exercises(content_json)')
      .eq('lesson_id', lessonId)
      .order('order_index');

  // Fetch user block progress
  final Set<String> completedBlockIds = {};
  if (userId != null && (blocksRaw as List).isNotEmpty) {
    final blockIds =
        blocksRaw.map((b) => (b as Map)['id'] as String).toList();
    final progressRaw = await supabase
        .from('user_progress')
        .select('lesson_block_id')
        .eq('user_id', userId)
        .inFilter('lesson_block_id', blockIds);

    for (final p in (progressRaw as List)) {
      final pm = Map<String, dynamic>.from(p as Map);
      completedBlockIds.add(pm['lesson_block_id'] as String);
    }
  }

  final blocks = (blocksRaw as List).asMap().entries.map((e) {
    final bm = Map<String, dynamic>.from(e.value as Map);
    final blockId = bm['id'] as String;
    // Extract prompt from joined exercise content_json
    final exerciseData = bm['exercises'] as Map?;
    final contentJson = exerciseData?['content_json'] as Map?;
    final prompt = contentJson?['prompt'] as String?;
    return LessonBlock(
      id: blockId,
      lessonId: lessonId,
      type: blockTypeFromString(bm['type'] as String? ?? 'reading'),
      exerciseId: bm['exercise_id'] as String? ?? '',
      orderIndex: bm['order_index'] as int? ?? e.key + 1,
      status: completedBlockIds.contains(blockId)
          ? BlockStatus.completed
          : BlockStatus.pending,
      prompt: prompt,
    );
  }).toList();

  final allDone =
      blocks.isNotEmpty && blocks.every((b) => b.status == BlockStatus.completed);

  return LessonDetail(
    lesson: LessonInfo(
      id: lessonId,
      moduleId: moduleId,
      title: lesson['title'] as String,
      skill: courseMeta['skill'] as String? ?? '',
      orderIndex: lesson['order_index'] as int? ?? 0,
      description: lesson['description'] as String?,
      durationMinutes: lesson['duration_minutes'] as int? ?? 15,
    ),
    courseId: courseId,
    courseTitle: courseMeta['title'] as String? ?? '',
    moduleId: moduleId,
    moduleTitle: moduleMeta['title'] as String? ?? '',
    blocks: blocks,
    bonusUnlocked: lesson['bonus_unlocked'] as bool? ?? allDone,
    bonusXpCost: lesson['bonus_xp_cost'] as int? ?? 50,
  );
});

// ── Mark block complete ───────────────────────────────────────────────────────

/// Upserts a user_progress row to mark a lesson block as done.
/// Call from practiceSessionNotifier after a successful exercise submission.
/// After calling, invalidate [lessonDetailProvider(lessonId)] to refresh UI.
Future<void> markBlockComplete({
  required String lessonId,
  required String lessonBlockId,
}) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  await supabase.from('user_progress').upsert(
    {
      'user_id': userId,
      'lesson_id': lessonId,
      'lesson_block_id': lessonBlockId,
      'completed_at': DateTime.now().toIso8601String(),
    },
    onConflict: 'user_id,lesson_block_id',
  );
}

// ── Course list (catalog) ─────────────────────────────────────────────────────

/// Fetches all available courses ordered by skill.
final courseListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data =
      await supabase.from('courses').select().order('skill').order('title');
  return (data as List)
      .map((c) => Map<String, dynamic>.from(c as Map))
      .toList();
});

// ── Unlock bonus ──────────────────────────────────────────────────────────────

/// Calls the unlock_lesson_bonus RPC: deducts XP and marks lesson.bonus_unlocked = true.
/// Throws 'insufficient_xp' if user doesn't have enough XP.
/// After success, invalidates lessonDetailProvider and currentUserProvider.
final unlockBonusProvider =
    FutureProvider.autoDispose.family<void, String>((ref, lessonId) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('Chưa đăng nhập.');

  await supabase.rpc('unlock_lesson_bonus', params: {
    'p_lesson_id': lessonId,
    'p_user_id': userId,
  });

  ref.invalidate(lessonDetailProvider(lessonId));
  ref.invalidate(currentUserProvider);
});
