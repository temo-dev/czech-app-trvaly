import 'package:app_czech/features/ai_teacher/models/ai_teacher_review.dart';
import 'package:app_czech/features/mock_test/models/exam_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExamAnalysis.fromJson', () {
    test('parses subjective teacher review payloads from exam_analysis', () {
      final analysis = ExamAnalysis.fromJson({
        'id': 'analysis-1',
        'attempt_id': 'attempt-1',
        'status': 'ready',
        'question_feedbacks': {
          'question-1': {
            'verdict': 'partial',
            'summary': 'Bạn trả lời đúng ý chính nhưng còn thiếu chi tiết.',
            'criteria': [
              {
                'label': 'Nội dung',
                'score': 60,
                'max_score': 100,
                'feedback': 'Đã có ý chính.',
                'tip': 'Thêm ví dụ cụ thể hơn.',
              },
            ],
            'short_tips': ['Bổ sung thêm chi tiết phụ trợ.'],
            'skipped': false,
          },
        },
        'skill_insights': {
          'speaking': {
            'summary': 'Bạn đã giao tiếp được ý chính.',
            'main_issue': 'Cần nói đầy câu hơn.',
          },
        },
        'overall_recommendations': [
          {
            'title': 'Luyện nói đủ câu',
            'detail': 'Tập trả lời trọn câu trước khi tăng tốc độ.',
          },
        ],
        'teacher_reviews_by_question': {
          'question-1': {
            'review_id': 'review-1',
            'status': 'ready',
            'modality': 'speaking',
            'source': 'mock_test',
            'verdict': 'partial',
            'summary': 'Bạn nói rõ ý chính nhưng còn thiếu độ trôi chảy.',
            'reinforcement': '',
            'criteria': [
              {
                'title': 'Lưu loát',
                'score': 58,
                'max_score': 100,
                'feedback': 'Bạn có ngắt nhịp vài lần.',
                'tip': 'Tập nối câu ngắn thành cụm ý hoàn chỉnh.',
              },
            ],
            'mistakes': [
              {
                'title': 'Phát âm / diễn đạt',
                'explanation': 'Một vài từ bị ngắt quãng.',
                'correction': '',
                'tip': 'Nói chậm hơn ở phần mở đầu.',
              },
            ],
            'suggestions': [
              {
                'title': 'Lưu ý 1',
                'detail': 'Mở đầu bằng một câu đầy đủ rồi mới thêm ý phụ.',
              },
            ],
            'corrected_answer':
                'Dobrý den, dnes bych chtěl mluvit o své práci.',
            'artifacts': {
              'transcript': 'Dobrý den...',
              'transcript_issues': [
                {
                  'token': 'práci',
                  'issue': 'pronunciation',
                  'suggestion': 'Kéo dài âm cuối rõ hơn.',
                },
              ],
              'short_tips': ['Mở đầu rõ chủ ngữ và động từ.'],
            },
            'is_premium': true,
          },
        },
      });

      expect(analysis.isReady, isTrue);
      expect(
        analysis.questionFeedbacks['question-1']?.summary,
        'Bạn trả lời đúng ý chính nhưng còn thiếu chi tiết.',
      );
      expect(analysis.skillInsights.single.skill, 'speaking');
      expect(analysis.overallRecommendations.single.title, 'Luyện nói đủ câu');

      final review = analysis.teacherReviewForQuestion('question-1');
      expect(review, isNotNull);
      expect(review?.reviewId, 'review-1');
      expect(review?.modality, AiTeacherReviewModality.speaking);
      expect(review?.verdict, AiTeacherReviewVerdict.partial);
      expect(
          review?.summary, 'Bạn nói rõ ý chính nhưng còn thiếu độ trôi chảy.');
      expect(review?.criteria.single.title, 'Lưu loát');
      expect(review?.artifacts.transcript, 'Dobrý den...');
      expect(review?.artifacts.shortTips, ['Mở đầu rõ chủ ngữ và động từ.']);
    });

    test('returns null when no materialized review exists for question', () {
      final analysis = ExamAnalysis.fromJson({
        'id': 'analysis-2',
        'attempt_id': 'attempt-2',
        'status': 'processing',
      });

      expect(analysis.isProcessing, isTrue);
      expect(analysis.teacherReviewForQuestion('missing-question'), isNull);
      expect(analysis.teacherReviewsByQuestion, isEmpty);
    });
  });
}
