import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_czech/core/router/app_routes.dart';
import 'package:app_czech/core/storage/prefs_storage.dart';
import 'package:app_czech/core/theme/app_colors.dart';
import 'package:app_czech/core/theme/app_spacing.dart';
import 'package:app_czech/core/theme/app_typography.dart';
import 'package:app_czech/shared/widgets/error_state.dart';
import 'package:app_czech/shared/widgets/loading_shimmer.dart';
import 'package:app_czech/shared/widgets/responsive_page_container.dart';
import '../models/mock_test_result.dart';
import '../providers/exam_result_provider.dart';
import '../widgets/result_cta_section.dart';
import '../widgets/skill_breakdown_chart.dart';
import '../widgets/total_score_hero.dart';

class MockTestResultScreen extends ConsumerStatefulWidget {
  const MockTestResultScreen({super.key, required this.attemptId});
  final String attemptId;

  @override
  ConsumerState<MockTestResultScreen> createState() =>
      _MockTestResultScreenState();
}

class _MockTestResultScreenState
    extends ConsumerState<MockTestResultScreen> {
  @override
  void initState() {
    super.initState();
    // Store pending attempt for anonymous linking
    _savePendingAttempt();
  }

  void _savePendingAttempt() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      PrefsStorage.instance.setPendingAttemptId(widget.attemptId);
    }
  }

  bool get _isAuthenticated =>
      Supabase.instance.client.auth.currentSession != null;

  @override
  Widget build(BuildContext context) {
    final resultAsync =
        ref.watch(examResultProvider(widget.attemptId));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Kết quả bài thi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Trang chủ',
            onPressed: () => context.go(AppRoutes.landing),
          ),
        ],
      ),
      body: resultAsync.when(
        loading: () => const _ResultSkeleton(),
        error: (e, _) => ErrorState(
          message: 'Không thể tải kết quả. Vui lòng thử lại.',
          onRetry: () =>
              ref.invalidate(examResultProvider(widget.attemptId)),
        ),
        data: (result) {
          final examIdAsync =
              ref.watch(attemptExamIdProvider(widget.attemptId));
          return _ResultBody(
            result: result,
            isAuthenticated: _isAuthenticated,
            onSignup: () {
              // attemptId is stored in prefs; signup screen will link it
              context.push(AppRoutes.signup);
            },
            onLogin: () => context.push(AppRoutes.login),
            onRetake: () {
              final examId = examIdAsync.valueOrNull;
              final path = examId != null
                  ? '${AppRoutes.mockTestIntro}?examId=$examId'
                  : AppRoutes.mockTestIntro;
              context.go(path);
            },
            onGoToDashboard: () => context.go(AppRoutes.dashboard),
          );
        },
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _ResultBody extends StatelessWidget {
  const _ResultBody({
    required this.result,
    required this.isAuthenticated,
    required this.onSignup,
    required this.onLogin,
    required this.onRetake,
    required this.onGoToDashboard,
  });

  final MockTestResult result;
  final bool isAuthenticated;
  final VoidCallback onSignup;
  final VoidCallback onLogin;
  final VoidCallback onRetake;
  final VoidCallback onGoToDashboard;

  @override
  Widget build(BuildContext context) {
    return ResponsivePageContainer(
      maxWidth: 640,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score hero
            Center(child: TotalScoreHero(result: result)),
            const SizedBox(height: AppSpacing.x6),

            // Skill breakdown
            if (result.sectionScores.isNotEmpty) ...[
              Text('Kết quả từng kỹ năng',
                  style: AppTypography.titleSmall),
              const SizedBox(height: AppSpacing.x4),
              SkillBreakdownChart(
                  sectionScores: result.sectionScores),
              const SizedBox(height: AppSpacing.x5),
            ],

            // Weak skills
            if (result.weakSkills.isNotEmpty) ...[
              _WeakSkillsRow(skills: result.weakSkills),
              const SizedBox(height: AppSpacing.x5),
            ],

            // Recommendation card
            _RecommendationCard(weakSkills: result.weakSkills),
            const SizedBox(height: AppSpacing.x6),

            // CTA section
            ResultCTASection(
              isAuthenticated: isAuthenticated,
              onSignup: onSignup,
              onLogin: onLogin,
              onRetake: onRetake,
              onGoToDashboard: onGoToDashboard,
            ),
            const SizedBox(height: AppSpacing.x8),
          ],
        ),
      ),
    );
  }
}

// ── Weak skills row ────────────────────────────────────────────────────────────

class _WeakSkillsRow extends StatelessWidget {
  const _WeakSkillsRow({required this.skills});
  final List<String> skills;

  static const _labels = {
    'reading':   'Đọc hiểu',
    'listening': 'Nghe hiểu',
    'writing':   'Viết',
    'speaking':  'Nói',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kỹ năng cần cải thiện',
            style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.x3),
        Wrap(
          spacing: AppSpacing.x2,
          runSpacing: AppSpacing.x2,
          children: skills.map((s) {
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x3, vertical: AppSpacing.x1),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: Text(
                _labels[s] ?? s,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Recommendation card ───────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.weakSkills});
  final List<String> weakSkills;

  String get _primarySkill =>
      weakSkills.isNotEmpty ? weakSkills.first : 'reading';

  static const _moduleMap = {
    'reading':   ('Đọc hiểu — Module 1', 'Bắt đầu với các đoạn văn A2 cơ bản'),
    'listening': ('Nghe hiểu — Module 1', 'Luyện nghe hội thoại hằng ngày'),
    'writing':   ('Viết — Module 1', 'Luyện viết câu đơn giản và đơn xin việc'),
    'speaking':  ('Nói — Module 1', 'Luyện phát âm và hội thoại cơ bản'),
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (title, subtitle) =
        _moduleMap[_primarySkill] ?? _moduleMap['reading']!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lightbulb_outline_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gợi ý cho bạn',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.primary)),
                const SizedBox(height: AppSpacing.x1),
                Text(title, style: AppTypography.bodyMedium),
                Text(subtitle,
                    style: AppTypography.bodySmall
                        .copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant, size: 20),
        ],
      ),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _ResultSkeleton extends StatelessWidget {
  const _ResultSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget block({double h = 16, double w = double.infinity}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.x3),
          child: LoadingShimmer(
            child: Container(
              height: h,
              width: w,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.x4),
          Center(
            child: LoadingShimmer(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.surfaceContainerHighest,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          block(h: 16, w: 180),
          block(h: 20),
          block(h: 20),
          block(h: 20),
          block(h: 20),
          const SizedBox(height: AppSpacing.x4),
          block(h: 100),
          const SizedBox(height: AppSpacing.x4),
          block(h: 56),
          block(h: 44),
        ],
      ),
    );
  }
}
