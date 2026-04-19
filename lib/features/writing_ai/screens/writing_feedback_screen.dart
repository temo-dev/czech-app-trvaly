import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_czech/core/router/app_routes.dart';
import 'package:app_czech/core/theme/app_colors.dart';
import 'package:app_czech/core/theme/app_radius.dart';
import 'package:app_czech/core/theme/app_typography.dart';
import 'package:app_czech/features/ai_teacher/models/ai_teacher_review.dart';
import 'package:app_czech/features/ai_teacher/providers/ai_teacher_review_provider.dart';
import 'package:app_czech/features/ai_teacher/widgets/ai_teacher_review_widgets.dart';
import 'package:app_czech/features/course/providers/course_providers.dart';
import 'package:app_czech/features/writing_ai/providers/writing_provider.dart';
import 'package:app_czech/shared/models/question_model.dart';
import 'package:app_czech/shared/widgets/circular_progress_ring.dart';
import 'package:app_czech/shared/widgets/error_state.dart';

/// Writing feedback screen — matches writing_ai_feedback.html Stitch design.
class WritingFeedbackScreen extends ConsumerWidget {
  const WritingFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final attemptId = extra?['attemptId'] as String?;
    final questionId = extra?['questionId'] as String? ?? '';
    final exerciseId = extra?['exerciseId'] as String? ?? '';
    final lessonId = extra?['lessonId'] as String? ?? '';
    final lessonBlockId = extra?['lessonBlockId'] as String? ?? '';
    final courseId = extra?['courseId'] as String? ?? '';
    final moduleId = extra?['moduleId'] as String? ?? '';
    final source = extra?['source'] as String? ??
        (lessonId.isNotEmpty ? 'lesson' : 'practice');

    if (attemptId == null) {
      return _buildShell(context, child: _ScoringInProgress());
    }

    final request = AiTeacherReviewRequest(
      source: source,
      questionId: questionId,
      exerciseId: exerciseId.isNotEmpty ? exerciseId : null,
      lessonId: lessonId.isNotEmpty ? lessonId : null,
      aiAttemptId: attemptId,
      questionType: QuestionType.writing,
    );
    final reviewAsync = ref.watch(aiTeacherReviewEntryProvider(request));

    ref.listen(aiTeacherReviewEntryProvider(request), (_, next) {
      next.whenData((response) {
        if (response.isReady &&
            lessonId.isNotEmpty &&
            lessonBlockId.isNotEmpty &&
            courseId.isNotEmpty &&
            moduleId.isNotEmpty) {
          _syncLessonProgress(
            ref,
            courseId: courseId,
            moduleId: moduleId,
            lessonId: lessonId,
            lessonBlockId: lessonBlockId,
          );
        }
      });
    });

    return _buildShell(
      context,
      child: reviewAsync.when(
        loading: () => _ScoringInProgress(),
        error: (_, __) => ErrorState(
          message: 'Không thể tải kết quả.',
          onRetry: () => ref.invalidate(aiTeacherReviewEntryProvider(request)),
        ),
        data: (response) {
          if (response.isPending) return _ScoringInProgress();
          if (response.isError || response.review == null) {
            return ErrorState(
              message: response.message ?? 'Không thể tải kết quả.',
              onRetry: () =>
                  ref.invalidate(aiTeacherReviewEntryProvider(request)),
            );
          }
          return AiTeacherDetailView(
            review: response.review!,
            title: 'Kết quả Viết',
            subtitle:
                'AI Teacher đang chấm và chỉ ra lỗi trong bài viết của bạn.',
          );
        },
      ),
    );
  }

  Widget _buildShell(BuildContext context, {required Widget child}) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.outlineVariant.withOpacity(0.6),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.onBackground.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.primary,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.dashboard);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Kết quả Viết',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 22,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.history_rounded),
                    color: AppColors.primary,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: child,
    );
  }
}

Future<void> _syncLessonProgress(
  WidgetRef ref, {
  required String courseId,
  required String moduleId,
  required String lessonId,
  required String lessonBlockId,
}) async {
  try {
    await markBlockComplete(
      lessonId: lessonId,
      lessonBlockId: lessonBlockId,
    );
    refreshCourseProgressProviders(
      ref,
      courseId: courseId,
      moduleId: moduleId,
      lessonId: lessonId,
    );
  } catch (error, stackTrace) {
    debugPrint('Failed to sync writing lesson progress: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

// ── Scoring in progress ───────────────────────────────────────────────────────

class _ScoringInProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Đang chấm điểm...',
              style: AppTypography.headlineSmall.copyWith(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'AI đang phân tích bài viết của bạn.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Score Hero ────────────────────────────────────────────────────────────────

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.result});
  final WritingFeedbackResult result;

  @override
  Widget build(BuildContext context) {
    final pct = (result.fraction * 100).round();

    // Try to find task fit metric
    final taskFit = result.metrics
        .where((m) =>
            m.label.toLowerCase().contains('task') ||
            m.label.toLowerCase().contains('nội dung'))
        .firstOrNull;
    final taskFitPct = taskFit != null ? (taskFit.fraction * 100).round() : 85;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.onBackground.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'ĐIỂM TỔNG QUÁT',
            style: AppTypography.labelUppercase.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Score ring
          ScoreHeroRing(
            score: pct,
            maxScore: 100,
            color: AppColors.primary,
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatItem(label: 'Nội dung', value: '$taskFitPct%'),
              Container(
                width: 1,
                height: 40,
                color: AppColors.outlineVariant.withOpacity(0.4),
                margin: const EdgeInsets.symmetric(horizontal: 24),
              ),
              const _StatItem(label: 'Thời gian', value: '—'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelUppercase.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── AI Summary Card ───────────────────────────────────────────────────────────

class _AiSummaryCard extends StatelessWidget {
  const _AiSummaryCard({required this.feedback});
  final String feedback;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                'Nhận xét từ AI',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.primary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feedback,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Writing Error Categories ──────────────────────────────────────────────────

class _WritingErrorCategories extends StatelessWidget {
  const _WritingErrorCategories({required this.result});
  final WritingFeedbackResult result;

  @override
  Widget build(BuildContext context) {
    // Content errors from task/content metric
    final contentErrors = <String>[];
    for (final m in result.metrics) {
      final l = m.label.toLowerCase();
      if ((l.contains('content') ||
              l.contains('nội dung') ||
              l.contains('task')) &&
          m.feedback != null &&
          m.feedback!.isNotEmpty) {
        contentErrors.add(m.feedback!);
      }
    }

    // Grammar + vocab errors: collect feedback from both metrics + annotated spans
    final grammarVocabErrors = <String>[];
    for (final m in result.metrics) {
      final l = m.label.toLowerCase();
      if ((l.contains('grammar') ||
              l.contains('ngữ pháp') ||
              l.contains('vocab') ||
              l.contains('từ vựng')) &&
          m.feedback != null &&
          m.feedback!.isNotEmpty) {
        grammarVocabErrors.add(m.feedback!);
      }
    }
    final spanErrors = result.annotatedSpans
        .where((s) =>
            s.issueType == 'grammar' ||
            s.issueType == 'vocabulary' ||
            s.issueType == 'spelling')
        .map((s) =>
            s.explanation ??
            (s.correction != null
                ? '"${s.text}" → ${s.correction}'
                : '"${s.text}"'))
        .toList();
    grammarVocabErrors.addAll(spanErrors);

    // Format/presentation errors from cohesion/format metric
    final formatErrors = <String>[];
    for (final m in result.metrics) {
      final l = m.label.toLowerCase();
      if ((l.contains('format') ||
              l.contains('hình thức') ||
              l.contains('cohesion') ||
              l.contains('mạch lạc') ||
              l.contains('structure') ||
              l.contains('cấu trúc')) &&
          m.feedback != null &&
          m.feedback!.isNotEmpty) {
        formatErrors.add(m.feedback!);
      }
    }

    return Column(
      children: [
        _WritingErrorCard(
          title: 'Lỗi nội dung',
          icon: Icons.topic_rounded,
          items: contentErrors,
          emptyLabel: 'Nội dung bài viết phù hợp với yêu cầu đề bài.',
        ),
        const SizedBox(height: 12),
        _WritingErrorCard(
          title: 'Lỗi ngữ pháp + từ vựng',
          icon: Icons.spellcheck_rounded,
          items: grammarVocabErrors,
          emptyLabel: 'Không phát hiện lỗi ngữ pháp hoặc từ vựng đáng kể.',
        ),
        const SizedBox(height: 12),
        _WritingErrorCard(
          title: 'Hình thức',
          icon: Icons.format_list_bulleted_rounded,
          items: formatErrors,
          emptyLabel: 'Hình thức và cấu trúc bài viết đạt yêu cầu.',
        ),
      ],
    );
  }
}

class _WritingErrorCard extends StatelessWidget {
  const _WritingErrorCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.emptyLabel,
  });

  final String title;
  final IconData icon;
  final List<String> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final hasErrors = items.isNotEmpty;
    final color = hasErrors ? AppColors.tertiary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headlineSmall.copyWith(fontSize: 18),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hasErrors
                      ? AppColors.tertiaryFixed
                      : AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  hasErrors ? '${items.length} lỗi' : 'Tốt',
                  style: AppTypography.labelUppercase.copyWith(
                    color: hasErrors
                        ? AppColors.onTertiaryFixed
                        : AppColors.onBackground,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasErrors)
            Text(
              emptyLabel,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '●',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Corrected Version Card ────────────────────────────────────────────────────

class _CorrectedVersionCard extends StatelessWidget {
  const _CorrectedVersionCard({required this.result});
  final WritingFeedbackResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bản đã chỉnh sửa',
                style: AppTypography.headlineSmall.copyWith(fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded,
                    size: 18, color: AppColors.onSurfaceVariant),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (result.annotatedSpans.isNotEmpty)
            _AnnotatedText(spans: result.annotatedSpans)
          else if (result.correctedVersion.isNotEmpty)
            Text(
              result.correctedVersion,
              style: AppTypography.bodyMedium.copyWith(height: 1.7),
            ),
        ],
      ),
    );
  }
}

class _AnnotatedText extends StatelessWidget {
  const _AnnotatedText({required this.spans});
  final List<AnnotatedSpan> spans;

  void _showSpanDetail(BuildContext context, AnnotatedSpan span) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '"${span.text}"',
                style: AppTypography.headlineSmall.copyWith(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (span.correction != null) ...[
              Text('Sửa thành:',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(span.correction!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 12),
            ],
            if (span.explanation != null) ...[
              Text('Giải thích:',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(span.explanation!,
                  style: AppTypography.bodySmall.copyWith(height: 1.5)),
              const SizedBox(height: 12),
            ],
            if (span.tip != null && span.tip!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        span.tip!,
                        style: AppTypography.bodySmall.copyWith(
                          color: const Color(0xFF7B5E00),
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: spans.map((span) {
        if (!span.hasIssue) {
          return Text(
            span.text,
            style: AppTypography.bodyMedium.copyWith(height: 1.7),
          );
        }

        final (bg, fg) = switch (span.issueType) {
          'grammar' => (AppColors.primary.withOpacity(0.15), AppColors.primary),
          'vocabulary' => (
              AppColors.tertiary.withOpacity(0.15),
              AppColors.tertiary
            ),
          _ => (AppColors.primary.withOpacity(0.1), AppColors.primary),
        };

        return GestureDetector(
          onTap: () => _showSpanDetail(context, span),
          child: Text(
            span.text,
            style: AppTypography.bodyMedium.copyWith(
              color: fg,
              backgroundColor: bg,
              height: 1.7,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: fg.withOpacity(0.5),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Short Tips Card ───────────────────────────────────────────────────────────

class _ShortTipsCard extends StatelessWidget {
  const _ShortTipsCard({required this.tips});
  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: const Color(0xFFFFE57F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded,
                  color: Color(0xFFF9A825), size: 20),
              const SizedBox(width: 10),
              Text(
                'Gợi ý nhanh từ AI',
                style: AppTypography.headlineSmall.copyWith(
                  fontSize: 16,
                  color: const Color(0xFF7B5E00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Text(
                      tip,
                      style: AppTypography.bodySmall.copyWith(
                        color: const Color(0xFF7B5E00),
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CTAs ──────────────────────────────────────────────────────────────────────

class _CtaRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'Tiếp tục bài học',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.outlineVariant),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            alignment: Alignment.center,
            child: Text(
              'Viết lại',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
