import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_czech/core/supabase/supabase_config.dart';
import 'package:app_czech/shared/providers/auth_provider.dart';
import 'package:app_czech/features/mock_test/models/mock_test_result.dart';
import 'package:app_czech/features/dashboard/models/dashboard_models.dart';

/// Composes user profile + latest result + leaderboard preview into one payload.
/// Uses FutureProvider.autoDispose (no codegen required).
final dashboardProvider =
    FutureProvider.autoDispose<DashboardData>((ref) async {
  // Use .future to await currentUserProvider instead of .value
  // .value is null while the provider is still loading (AsyncLoading), which
  // causes a false 'Not authenticated' error because GoRouter redirects to
  // dashboard before _fetchProfile() completes after signInWithPassword.
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) throw Exception('Not authenticated');

  // ── Latest exam result ────────────────────────────────────────────────────
  MockTestResult? latestResult;
  try {
    final data = await supabase
        .from('exam_results')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data != null) {
      final raw = Map<String, dynamic>.from(data as Map);
      final rawSections =
          (raw['section_scores'] as Map<String, dynamic>?) ?? {};
      final sectionScores = rawSections.map(
        (k, v) => MapEntry(
          k,
          SectionResult.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      );
      final rawWeak = raw['weak_skills'];
      final weakSkills =
          rawWeak is List ? List<String>.from(rawWeak) : <String>[];
      latestResult = MockTestResult(
        id: raw['id'] as String,
        attemptId: raw['attempt_id'] as String,
        userId: raw['user_id'] as String?,
        totalScore: raw['total_score'] as int? ?? 0,
        passThreshold: raw['pass_threshold'] as int? ?? 60,
        sectionScores: sectionScores,
        weakSkills: weakSkills,
        createdAt: DateTime.parse(raw['created_at'] as String),
      );
    }
  } catch (_) {
    // Non-fatal — dashboard still renders with EmptyResultBanner
  }

  // ── Static recommendation (MVP: first lesson of weakest skill) ────────────
  RecommendedLesson? recommendation;
  if (latestResult != null && latestResult.weakSkills.isNotEmpty) {
    final skill = latestResult.weakSkills.first;
    final skillLabel = _skillLabel(skill);
    recommendation = RecommendedLesson(
      lessonId: 'lesson-$skill-1',
      lessonTitle: 'Bài 1: Giới thiệu $skillLabel',
      moduleTitle: 'Module 1',
      skill: skill,
      courseId: 'course-$skill',
      moduleId: 'module-$skill-1',
      courseSlug: skill,
    );
  }

  // ── Leaderboard preview: top 3 + own rank ────────────────────────────────
  List<LeaderboardRow> leaderboardPreview = [];
  int? ownRank;
  try {
    final rows = await supabase
        .from('leaderboard_weekly')
        .select()
        .order('weekly_xp', ascending: false)
        .limit(3);

    leaderboardPreview = (rows as List).asMap().entries.map((e) {
      final row = Map<String, dynamic>.from(e.value as Map);
      return LeaderboardRow(
        userId: row['user_id'] as String,
        displayName: row['display_name'] as String? ?? 'Người dùng',
        avatarUrl: row['avatar_url'] as String?,
        weeklyXp: row['weekly_xp'] as int? ?? 0,
        rank: e.key + 1,
        isCurrentUser: row['user_id'] == user.id,
      );
    }).toList();

    final ownRow = await supabase
        .from('leaderboard_weekly')
        .select('rank')
        .eq('user_id', user.id)
        .maybeSingle();
    if (ownRow != null) {
      ownRank = (ownRow as Map)['rank'] as int?;
    }
  } catch (_) {
    // Non-fatal
  }

  // ── Stub course progress (Day 9 wires real data) ──────────────────────────
  const activeCourse = CourseProgress(
    courseId: 'course-reading',
    courseSlug: 'reading',
    courseTitle: 'Kỹ năng Đọc hiểu',
    skill: 'reading',
    completedLessons: 0,
    totalLessons: 6,
  );

  return DashboardData(
    user: user,
    latestResult: latestResult,
    recommendation: recommendation,
    leaderboardPreview: leaderboardPreview,
    ownRank: ownRank,
    activeCourse: activeCourse,
  );
});

String _skillLabel(String skill) => switch (skill) {
      'reading' => 'Đọc hiểu',
      'listening' => 'Nghe hiểu',
      'writing' => 'Viết',
      'speaking' => 'Nói',
      _ => skill,
    };
