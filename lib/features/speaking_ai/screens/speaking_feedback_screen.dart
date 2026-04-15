import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_czech/core/router/app_routes.dart';
import 'package:app_czech/core/theme/app_colors.dart';
import 'package:app_czech/core/theme/app_radius.dart';
import 'package:app_czech/core/theme/app_typography.dart';
import 'package:app_czech/features/speaking_ai/providers/speaking_feedback_provider.dart';
import 'package:app_czech/shared/widgets/circular_progress_ring.dart';
import 'package:app_czech/shared/widgets/error_state.dart';
import 'package:app_czech/shared/widgets/responsive_page_container.dart';

/// Speaking feedback screen — matches speaking_ai_feedback.html Stitch design.
class SpeakingFeedbackScreen extends ConsumerWidget {
  const SpeakingFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final attemptId = extra?['attemptId'] as String? ?? '';

    if (attemptId.isEmpty) {
      return _buildShell(context, child: _ScoringInProgress());
    }

    final state = ref.watch(speakingFeedbackProvider(attemptId));

    return _buildShell(
      context,
      child: switch (state.status) {
        SpeakingFeedbackStatus.pending ||
        SpeakingFeedbackStatus.scoring =>
          _ScoringInProgress(),
        SpeakingFeedbackStatus.completed when state.result != null =>
          _FeedbackBody(result: state.result!),
        SpeakingFeedbackStatus.error => ErrorState(
            message: state.errorMessage ?? 'Không thể tải kết quả.',
            onRetry: () =>
                ref.read(speakingFeedbackProvider(attemptId).notifier).retry(),
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
                    'Speaking Analysis',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 22,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
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
            _PulsingRing(),
            const SizedBox(height: 32),
            Text(
              'Đang chấm điểm...',
              style: AppTypography.headlineSmall.copyWith(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'AI đang phân tích bài nói của bạn.\nThường mất 10–30 giây.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingRing extends StatefulWidget {
  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mic_rounded, size: 44, color: AppColors.primary),
      ),
    );
  }
}

// ── Feedback body ─────────────────────────────────────────────────────────────

class _FeedbackBody extends StatelessWidget {
  const _FeedbackBody({required this.result});
  final SpeakingFeedbackResult result;

  @override
  Widget build(BuildContext context) {
    final pct = (result.fraction * 100).round();

    return SingleChildScrollView(
      child: ResponsivePageContainer(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero score
              _ScoreHero(score: pct),
              const SizedBox(height: 32),

              // Metrics bento grid
              if (result.metrics.isNotEmpty) ...[
                _MetricsGrid(metrics: result.metrics),
                const SizedBox(height: 32),
              ],

              // AI Feedback card
              if (result.overallFeedback.isNotEmpty) ...[
                _AiFeedbackCard(feedback: result.overallFeedback),
                const SizedBox(height: 24),
              ],

              // Strengths / Improvements 2-col
              _StrengthsImprovements(
                corrections: result.corrections,
              ),
              const SizedBox(height: 24),

              // Sample answer card
              _SampleAnswerCard(),
              const SizedBox(height: 32),

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
  const _ScoreHero({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScoreHeroRing(
          score: score,
          maxScore: 100,
          color: AppColors.primary,
        ),
        const SizedBox(height: 20),
        Text(
          'Kết quả luyện tập',
          style: AppTypography.headlineMedium.copyWith(fontSize: 26),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Bạn đang làm rất tốt! Hãy xem các phân tích chi tiết bên dưới.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Metrics Grid ──────────────────────────────────────────────────────────────

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});
  final List<SpeakingMetric> metrics;

  @override
  Widget build(BuildContext context) {
    // Show up to 4 metrics in a 2x2 grid
    final visible = metrics.take(4).toList();
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: visible.length,
      itemBuilder: (_, i) => _MetricCard(metric: visible[i]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});
  final SpeakingMetric metric;

  @override
  Widget build(BuildContext context) {
    final pct = (metric.fraction * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$pct%',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.label.toUpperCase(),
            style: AppTypography.labelUppercase.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── AI Feedback Card ──────────────────────────────────────────────────────────

class _AiFeedbackCard extends StatelessWidget {
  const _AiFeedbackCard({required this.feedback});
  final String feedback;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Text(
                'Phản hồi từ AI',
                style: AppTypography.headlineSmall.copyWith(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            feedback,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Strengths & Improvements ──────────────────────────────────────────────────

class _StrengthsImprovements extends StatelessWidget {
  const _StrengthsImprovements({required this.corrections});
  final List<String> corrections;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    const strengths = [
      'Sử dụng từ vựng chuyên ngành chính xác trong ngữ cảnh.',
      'Ngữ điệu tự nhiên, có sự nhấn nhá ở các từ khóa quan trọng.',
    ];

    final improvements = corrections.isNotEmpty
        ? corrections
        : [
            'Phát âm âm cuối (ending sounds) như /s/ và /t/ chưa đều.',
            'Lỗi chia động từ ở các câu điều kiện loại 2.',
          ];

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: _FeedbackSection(
                  title: 'Ưu điểm',
                  icon: Icons.task_alt_rounded,
                  color: AppColors.primary,
                  items: strengths)),
          const SizedBox(width: 24),
          Expanded(
              child: _FeedbackSection(
                  title: 'Cần cải thiện',
                  icon: Icons.error_outline_rounded,
                  color: AppColors.tertiary,
                  items: improvements)),
        ],
      );
    }

    return Column(
      children: [
        _FeedbackSection(
            title: 'Ưu điểm',
            icon: Icons.task_alt_rounded,
            color: AppColors.primary,
            items: strengths),
        const SizedBox(height: 16),
        _FeedbackSection(
            title: 'Cần cải thiện',
            icon: Icons.error_outline_rounded,
            color: AppColors.tertiary,
            items: improvements),
      ],
    );
  }
}

class _FeedbackSection extends StatelessWidget {
  const _FeedbackSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onBackground.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTypography.headlineSmall.copyWith(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '●',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Sample Answer Card ────────────────────────────────────────────────────────

class _SampleAnswerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Câu trả lời gợi ý',
                    style: AppTypography.headlineSmall.copyWith(fontSize: 20),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle_filled_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Nghe mẫu',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withOpacity(0.6),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.05),
              ),
            ),
            child: Text(
              '"Tôi tin rằng phát triển bền vững không còn là sự lựa chọn mà đã trở thành điều cần thiết cho thế hệ của chúng ta..."',
              style: AppTypography.bodyMedium.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.onBackground,
                fontWeight: FontWeight.w500,
                height: 1.7,
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
              'Luyện tập lại',
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
