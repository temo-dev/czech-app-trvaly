import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_czech/core/router/app_routes.dart';
import 'package:app_czech/core/theme/app_colors.dart';
import 'package:app_czech/core/theme/app_radius.dart';
import 'package:app_czech/core/theme/app_typography.dart';
import 'package:app_czech/features/writing_ai/providers/writing_provider.dart';
import 'package:app_czech/shared/widgets/circular_progress_ring.dart';
import 'package:app_czech/shared/widgets/error_state.dart';
import 'package:app_czech/shared/widgets/responsive_page_container.dart';

/// Writing feedback screen — matches writing_ai_feedback.html Stitch design.
class WritingFeedbackScreen extends ConsumerWidget {
  const WritingFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final attemptId = extra?['attemptId'] as String?;

    if (attemptId == null) {
      return _buildShell(context, child: _ScoringInProgress());
    }

    final state = ref.watch(writingSessionProvider);

    return _buildShell(
      context,
      child: switch (state.status) {
        WritingFeedbackStatus.submitting ||
        WritingFeedbackStatus.pending ||
        WritingFeedbackStatus.scoring =>
          _ScoringInProgress(),
        WritingFeedbackStatus.completed when state.result != null =>
          _FeedbackBody(result: state.result!),
        WritingFeedbackStatus.error => ErrorState(
            message: state.errorMessage ?? 'Không thể tải kết quả.',
            onRetry: () => ref.read(writingSessionProvider.notifier).retry(),
          ),
        _ => _ScoringInProgress(),
      },
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
                    'Writing Feedback',
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

// ── Feedback body ─────────────────────────────────────────────────────────────

class _FeedbackBody extends StatelessWidget {
  const _FeedbackBody({required this.result});
  final WritingFeedbackResult result;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ResponsivePageContainer(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Score overview hero
              _ScoreHero(result: result),
              const SizedBox(height: 24),

              // AI Summary card
              if (result.overallFeedback.isNotEmpty) ...[
                _AiSummaryCard(feedback: result.overallFeedback),
                const SizedBox(height: 24),
              ],

              // Detailed feedback bento
              if (result.metrics.isNotEmpty) ...[
                _FeedbackBento(metrics: result.metrics),
                const SizedBox(height: 24),
              ],

              // Corrected version
              if (result.correctedVersion.isNotEmpty ||
                  result.annotatedSpans.isNotEmpty) ...[
                _CorrectedVersionCard(result: result),
                const SizedBox(height: 32),
              ],

              // CTAs
              _CtaRow(),
            ],
          ),
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
        .where((m) => m.label.toLowerCase().contains('task') ||
            m.label.toLowerCase().contains('nội dung'))
        .firstOrNull;
    final taskFitPct = taskFit != null
        ? (taskFit.fraction * 100).round()
        : 85;

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
              _StatItem(label: 'Task Fit', value: '$taskFitPct%'),
              Container(
                width: 1,
                height: 40,
                color: AppColors.outlineVariant.withOpacity(0.4),
                margin: const EdgeInsets.symmetric(horizontal: 24),
              ),
              const _StatItem(label: 'Time', value: '14:20'),
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

// ── Feedback Bento Grid ───────────────────────────────────────────────────────

class _FeedbackBento extends StatelessWidget {
  const _FeedbackBento({required this.metrics});
  final List<WritingMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final visible = metrics.take(3).toList();

    if (isWide) {
      return Row(
        children: visible.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: i > 0 ? 12 : 0,
              ),
              child: _MetricCard(metric: m),
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: visible.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MetricCard(metric: m),
          )).toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});
  final WritingMetric metric;

  bool get _needsImprovement => metric.fraction < 0.7;

  @override
  Widget build(BuildContext context) {
    final pct = (metric.fraction * 100).round();
    final (icon, label) = _iconAndLabel(metric.label);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon,
                  color: _needsImprovement
                      ? AppColors.tertiary
                      : AppColors.primary,
                  size: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _needsImprovement
                      ? AppColors.tertiaryFixed
                      : AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  _needsImprovement ? 'CẦN CẢI THIỆN' : 'KHÁ TỐT',
                  style: AppTypography.labelUppercase.copyWith(
                    color: _needsImprovement
                        ? AppColors.onTertiaryFixed
                        : AppColors.onBackground,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTypography.headlineSmall.copyWith(fontSize: 20),
          ),
          if (metric.feedback != null) ...[
            const SizedBox(height: 4),
            Text(
              metric.feedback!,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: metric.fraction,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                _needsImprovement ? AppColors.tertiary : AppColors.primary,
              ),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$pct / ${metric.maxScore.round()}',
            style: AppTypography.labelSmall.copyWith(
              color: _needsImprovement ? AppColors.tertiary : AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String) _iconAndLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('grammar') || lower.contains('ngữ pháp')) {
      return (Icons.spellcheck_rounded, 'Ngữ pháp');
    }
    if (lower.contains('vocab') || lower.contains('từ vựng')) {
      return (Icons.menu_book_rounded, 'Từ vựng');
    }
    if (lower.contains('coheren') || lower.contains('mạch lạc')) {
      return (Icons.format_align_left_rounded, 'Mạch lạc');
    }
    if (lower.contains('task') || lower.contains('nội dung')) {
      return (Icons.task_alt_rounded, 'Nội dung');
    }
    return (Icons.rate_review_rounded, label);
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

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: spans.map((span) {
          if (!span.hasIssue) {
            return TextSpan(
              text: span.text,
              style: AppTypography.bodyMedium.copyWith(height: 1.7),
            );
          }

          final (bg, fg) = switch (span.issueType) {
            'grammar' => (
                AppColors.primary.withOpacity(0.15),
                AppColors.primary
              ),
            'vocabulary' => (
                AppColors.tertiary.withOpacity(0.15),
                AppColors.tertiary
              ),
            _ => (AppColors.primary.withOpacity(0.1), AppColors.primary),
          };

          return TextSpan(
            text: span.text,
            style: AppTypography.bodyMedium.copyWith(
              color: fg,
              backgroundColor: bg,
              height: 1.7,
              fontWeight: FontWeight.w600,
            ),
          );
        }).toList(),
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
