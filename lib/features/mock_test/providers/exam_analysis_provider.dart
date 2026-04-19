import 'package:app_czech/core/supabase/supabase_config.dart';
import 'package:app_czech/features/mock_test/models/exam_analysis.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exam_analysis_provider.g.dart';

const _analysisPollRetries = 30;
const _analysisPollInterval = Duration(seconds: 3);

@riverpod
Future<ExamAnalysis?> examAnalysis(
  ExamAnalysisRef ref,
  String attemptId,
) async {
  for (var i = 0; i < _analysisPollRetries; i++) {
    final data = await supabase
        .from('exam_analysis')
        .select()
        .eq('attempt_id', attemptId)
        .maybeSingle();

    if (data != null) {
      final analysis = ExamAnalysis.fromJson(
        Map<String, dynamic>.from(data as Map),
      );

      if (analysis.isReady || analysis.isError) {
        return analysis;
      }
    }

    if (i < _analysisPollRetries - 1) {
      await Future.delayed(_analysisPollInterval);
    }
  }

  return null;
}
