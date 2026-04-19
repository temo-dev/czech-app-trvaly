import 'package:app_czech/core/supabase/supabase_config.dart';
import 'package:app_czech/features/ai_teacher/models/ai_teacher_review.dart';
import 'package:app_czech/features/mock_test/providers/exam_result_provider.dart';
import 'package:app_czech/shared/models/question_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiTeacherReviewController {
  const AiTeacherReviewController(this.request);

  final AiTeacherReviewRequest request;

  static const _pollRetries = 10;
  static const _pollInterval = Duration(seconds: 3);

  Future<String?> submit() async {
    final response = await supabase.functions.invoke(
      'ai-review-submit',
      body: request.toBody(),
    );
    final data = response.data as Map<String, dynamic>?;
    return data?['review_id'] as String?;
  }

  Future<AiTeacherReviewResponse> fetch(String reviewId) async {
    final response = await supabase.functions.invoke(
      'ai-review-result',
      body: {'review_id': reviewId},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return AiTeacherReviewResponse.fromJson(data);
  }

  Future<AiTeacherReviewResponse> fetchOrSubmit() async {
    final reviewId = await submit();
    if (reviewId == null) {
      return const AiTeacherReviewResponse(
        status: AiTeacherReviewStatus.error,
        reviewId: null,
        message: 'Không thể tạo teacher review.',
      );
    }

    for (var i = 0; i < _pollRetries; i++) {
      final result = await fetch(reviewId);
      if (!result.isPending) return result;
      if (i < _pollRetries - 1) {
        await Future.delayed(_pollInterval);
      }
    }

    return AiTeacherReviewResponse(
      status: AiTeacherReviewStatus.pending,
      reviewId: reviewId,
      message: 'AI Teacher vẫn đang chuẩn bị nhận xét.',
    );
  }
}

final aiTeacherReviewControllerProvider =
    Provider.family<AiTeacherReviewController, AiTeacherReviewRequest>(
  (_, request) => AiTeacherReviewController(request),
);

final aiTeacherReviewProvider = FutureProvider.autoDispose
    .family<AiTeacherReviewResponse, String>((ref, reviewId) async {
  final response = await supabase.functions.invoke(
    'ai-review-result',
    body: {'review_id': reviewId},
  );
  final data = Map<String, dynamic>.from(response.data as Map);
  return AiTeacherReviewResponse.fromJson(data);
});

final aiTeacherReviewEntryProvider = FutureProvider.autoDispose
    .family<AiTeacherReviewResponse, AiTeacherReviewRequest>((ref, request) {
  final controller = ref.watch(aiTeacherReviewControllerProvider(request));
  return controller.fetchOrSubmit();
});

final aiTeacherReviewBatchProvider =
    FutureProvider.autoDispose.family<Map<String, String>, String>(
  (ref, attemptId) async {
    final reviewItems = await ref.watch(examReviewProvider(attemptId).future);
    final reviewIds = <String, String>{};

    for (final item in reviewItems) {
      final request = _buildBatchRequest(item);
      if (request == null) continue;
      try {
        final reviewId =
            await ref.read(aiTeacherReviewControllerProvider(request)).submit();
        if (reviewId != null) {
          reviewIds[item.question.id] = reviewId;
        }
      } catch (_) {
        // Best-effort pre-generation only.
      }
    }

    return reviewIds;
  },
);

AiTeacherReviewRequest? _buildBatchRequest(QuestionReviewItem item) {
  final question = item.question;

  switch (question.type) {
    case QuestionType.writing:
    case QuestionType.speaking:
      if (!item.isAnswered || item.aiAttemptId == null) return null;
      return AiTeacherReviewRequest(
        source: 'mock_test',
        questionId: question.id,
        examAttemptId: item.attemptId,
        aiAttemptId: item.aiAttemptId,
        questionType: question.type,
      );
    case QuestionType.mcq:
    case QuestionType.fillBlank:
    case QuestionType.matching:
    case QuestionType.ordering:
      if (!item.isAnswered || item.isCorrect) return null;
      return AiTeacherReviewRequest(
        source: 'mock_test',
        questionId: question.id,
        examAttemptId: item.attemptId,
        selectedOptionId: item.selectedOption?.id,
        writtenAnswer: item.userAnswer,
        questionType: question.type,
      );
  }
}
