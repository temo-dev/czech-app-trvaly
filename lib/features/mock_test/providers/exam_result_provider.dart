import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app_czech/core/supabase/supabase_config.dart';
import 'package:app_czech/core/storage/prefs_storage.dart';
import '../models/mock_test_result.dart';

part 'exam_result_provider.g.dart';

@riverpod
Future<MockTestResult> examResult(ExamResultRef ref, String attemptId) async {
  final data = await supabase
      .from('exam_results')
      .select()
      .eq('attempt_id', attemptId)
      .order('created_at', ascending: false)
      .limit(1)
      .single();

  final raw = Map<String, dynamic>.from(data as Map);

  // Parse section_scores: { skill: { score, total } }
  final rawSections =
      (raw['section_scores'] as Map<String, dynamic>?) ?? {};
  final sectionScores = rawSections.map(
    (k, v) => MapEntry(
      k,
      SectionResult.fromJson(Map<String, dynamic>.from(v as Map)),
    ),
  );

  // Parse weak_skills: stored as List in Postgres
  final rawWeak = raw['weak_skills'];
  final weakSkills = rawWeak is List
      ? List<String>.from(rawWeak)
      : <String>[];

  return MockTestResult(
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

/// Links an anonymous attempt to the newly authenticated user.
/// Called right after a successful signup if a pendingAttemptId exists.
Future<void> linkPendingAttempt(String userId) async {
  final pendingId = PrefsStorage.instance.pendingAttemptId;
  if (pendingId == null) return;

  try {
    await supabase
        .from('exam_attempts')
        .update({'user_id': userId})
        .eq('id', pendingId)
        .isFilter('user_id', null); // only link if still anonymous

    await supabase
        .from('exam_results')
        .update({'user_id': userId})
        .eq('attempt_id', pendingId)
        .isFilter('user_id', null);

    await PrefsStorage.instance.clearPendingAttemptId();
  } catch (_) {
    // Non-fatal: attempt stays anonymous, user can still see result
  }
}

/// Fetches the examId for a given attemptId from exam_attempts.
/// No codegen needed — uses classic Riverpod family API.
final attemptExamIdProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, attemptId) async {
  try {
    final row = await supabase
        .from('exam_attempts')
        .select('exam_id')
        .eq('id', attemptId)
        .single();
    return row['exam_id'] as String?;
  } catch (_) {
    return null;
  }
});
