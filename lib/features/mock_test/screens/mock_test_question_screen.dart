import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_czech/core/router/app_routes.dart';
import 'package:app_czech/core/theme/app_colors.dart';
import 'package:app_czech/core/theme/app_spacing.dart';
import 'package:app_czech/core/theme/app_typography.dart';
import 'package:app_czech/shared/models/question_model.dart';
import 'package:app_czech/shared/widgets/app_button.dart';
import 'package:app_czech/shared/widgets/error_state.dart';
import 'package:app_czech/shared/widgets/loading_shimmer.dart';
import '../../exercise/widgets/question_shell.dart';
import '../providers/exam_questions_provider.dart';
import '../providers/exam_session_notifier.dart';
import '../widgets/confirm_submit_dialog.dart';
import '../widgets/exam_top_bar.dart';
import '../widgets/question_nav_panel.dart';
import '../widgets/section_transition_card.dart';

class MockTestQuestionScreen extends ConsumerStatefulWidget {
  const MockTestQuestionScreen({super.key, required this.attemptId});

  final String attemptId;

  @override
  ConsumerState<MockTestQuestionScreen> createState() =>
      _MockTestQuestionScreenState();
}

class _MockTestQuestionScreenState
    extends ConsumerState<MockTestQuestionScreen> {
  bool _navPanelOpen = false;
  bool _timerStarted = false;

  void _onTimerExpired() {
    _submit();
  }

  Future<void> _submit() async {
    final id = await ref
        .read(examSessionNotifierProvider(widget.attemptId).notifier)
        .submit();
    if (id != null && mounted) {
      context.pushReplacement(AppRoutes.mockTestResultPath(id));
    }
  }

  void _showNavPanel(BuildContext ctx) {
    final isWide = MediaQuery.sizeOf(ctx).width >= 900;
    if (isWide) {
      setState(() => _navPanelOpen = !_navPanelOpen);
    } else {
      showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          builder: (_, controller) => ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: _buildNavPanel(ctx),
          ),
        ),
      );
    }
  }

  Widget _buildNavPanel(BuildContext ctx) {
    final sessionState = ref
        .read(examSessionNotifierProvider(widget.attemptId))
        .valueOrNull;
    if (sessionState == null) return const SizedBox.shrink();

    final navItems = buildNavItems(
      sections: sessionState.meta.sections,
      answers: sessionState.currentAnswers,
    );

    return QuestionNavPanel(
      sections: sessionState.meta.sections,
      items: navItems,
      currentGlobalIndex: sessionState.globalQuestionIndex,
      onClose: () => Navigator.of(ctx).pop(),
      onTap: (si, qi) {
        Navigator.of(ctx).pop();
        ref
            .read(examSessionNotifierProvider(widget.attemptId).notifier)
            .goToQuestion(si, qi);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync =
        ref.watch(examSessionNotifierProvider(widget.attemptId));

    // Start timer once when session first loads.
    // addPostFrameCallback ensures ref.watch(examTimerNotifierProvider) in the
    // data block below has already run this frame, keeping the autoDispose
    // provider alive before we call .start() on it.
    ref.listen(examSessionNotifierProvider(widget.attemptId), (prev, next) {
      if (_timerStarted) return;
      final s = next.valueOrNull;
      if (s == null) return;
      _timerStarted = true;
      final remaining = s.attempt.remainingSeconds ?? 0;
      final seconds = remaining > 0
          ? remaining
          : s.meta.durationMinutes * 60;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(examTimerNotifierProvider(seconds).notifier)
            .start(_onTimerExpired);
      });
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) async {
        await ConfirmExitDialog.show(
          context: context,
          onConfirm: () => context.go(AppRoutes.landing),
        );
      },
      child: sessionAsync.when(
        loading: () => const _SessionLoadingScreen(),
        error: (e, st) {
          // ignore: avoid_print
          print('[examSession ERROR] $e\n$st');
          return ErrorState(
            message: 'Lỗi session: $e',
            onRetry: () => ref.invalidate(
                examSessionNotifierProvider(widget.attemptId)),
          );
        },
        data: (session) {
          // Always watch the timer first — even during section transitions.
          // If ref.watch is skipped (early return), autoDispose kills the
          // provider and cancels Timer.periodic, causing a reset.
          final _remaining = session.attempt.remainingSeconds ?? 0;
          final timerSeconds = ref.watch(
            examTimerNotifierProvider(
              _remaining > 0 ? _remaining : session.meta.durationMinutes * 60,
            ),
          );

          // Show section transition overlay.
          // currentSectionIndex still points to the completed section here;
          // advanceSection() will increment it.
          if (session.showSectionTransition) {
            final completedIdx = session.currentSectionIndex;
            final nextIdx = completedIdx + 1;
            return SectionTransitionCard(
              completedSection: session.meta.sections[completedIdx],
              nextSection: session.meta.sections[nextIdx],
              onContinue: () => ref
                  .read(examSessionNotifierProvider(widget.attemptId)
                      .notifier)
                  .advanceSection(),
            );
          }

          final isWide = MediaQuery.sizeOf(context).width >= 900;

          return Scaffold(
            appBar: ExamTopBar(
              sectionLabel: session.currentSection.label,
              questionLabel:
                  'CÂU HỎI ${session.globalQuestionIndex + 1} / ${session.totalQuestions}',
              remainingSeconds: timerSeconds,
              autosaveStatus: session.autosaveStatus,
              onNavTap: () => _showNavPanel(context),
              onExit: () => ConfirmExitDialog.show(
                context: context,
                onConfirm: () => context.go(AppRoutes.landing),
              ),
            ),
            body: Row(
              children: [
                // Main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Progress bar
                      _ProgressBar(
                        answered: session.answeredCount,
                        total: session.totalQuestions,
                      ),
                      // Question renderer
                      Expanded(
                        child: _QuestionBody(
                          attemptId: widget.attemptId,
                          examId: session.meta.id,
                          session: session,
                        ),
                      ),
                      // Bottom nav row
                      _BottomBar(
                        session: session,
                        onPrev: () {
                          // simplified prev: go back in questions
                          final qi = session.currentQuestionIndex;
                          final si = session.currentSectionIndex;
                          if (qi > 0) {
                            ref
                                .read(examSessionNotifierProvider(
                                        widget.attemptId)
                                    .notifier)
                                .goToQuestion(si, qi - 1);
                          } else if (si > 0) {
                            final prevSection =
                                session.meta.sections[si - 1];
                            ref
                                .read(examSessionNotifierProvider(
                                        widget.attemptId)
                                    .notifier)
                                .goToQuestion(
                                    si - 1, prevSection.questionCount - 1);
                          }
                        },
                        onNext: () => ref
                            .read(examSessionNotifierProvider(
                                    widget.attemptId)
                                .notifier)
                            .nextQuestion(),
                        onSubmit: () => ConfirmSubmitDialog.show(
                          context: context,
                          unansweredCount: session.unansweredCount,
                          onConfirm: _submit,
                        ),
                        isSubmitting:
                            session.status == ExamSessionStatus.submitting,
                      ),
                    ],
                  ),
                ),
                // Side nav panel (web only)
                if (isWide && _navPanelOpen)
                  SizedBox(
                    width: 260,
                    child: _buildNavPanel(context),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Progress bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.answered, required this.total});
  final int answered;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : answered / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor:
              Theme.of(context).colorScheme.outlineVariant,
          color: AppColors.primary,
          minHeight: 3,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x4, vertical: AppSpacing.x1),
          child: Text(
            'Đã hoàn thành: $answered / $total (${(progress * 100).round()}%)',
            style: AppTypography.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.session,
    required this.onPrev,
    required this.onNext,
    required this.onSubmit,
    required this.isSubmitting,
  });

  final ExamSessionState session;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  bool get _isFirst =>
      session.currentSectionIndex == 0 &&
      session.currentQuestionIndex == 0;

  bool get _isLast =>
      session.currentSectionIndex ==
          session.meta.sections.length - 1 &&
      session.currentQuestionIndex ==
          session.currentSection.questionCount - 1;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x3,
        AppSpacing.x4,
        AppSpacing.x3 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _isFirst ? null : onPrev,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 52),
            ),
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            label: const Text('Trước'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _isLast
                ? AppButton(
              label: 'Nộp bài',
              loading: isSubmitting,
              onPressed: isSubmitting ? null : onSubmit,
              fullWidth: true,
              icon: Icons.check_rounded,
              size: AppButtonSize.md,
            )
                : AppButton(
              label: 'Tiếp',
              onPressed: onNext,
              fullWidth: true,
              trailingIcon: Icons.chevron_right_rounded,
              size: AppButtonSize.md,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Question body — fetch real questions from DB ───────────────────────────────

class _QuestionBody extends ConsumerWidget {
  const _QuestionBody({
    required this.attemptId,
    required this.examId,
    required this.session,
  });

  final String attemptId;
  final String examId;
  final ExamSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(examQuestionsProvider(examId));

    return questionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        message: 'Không thể tải câu hỏi. Vui lòng thử lại.',
        onRetry: () => ref.invalidate(examQuestionsProvider(examId)),
      ),
      data: (questions) {
        final globalIdx = session.globalQuestionIndex;
        if (questions.isEmpty || globalIdx >= questions.length) {
          return Center(
            child: Text(
              'Không tìm thấy câu hỏi.',
              style: AppTypography.bodyMedium,
            ),
          );
        }
        final question = questions[globalIdx];
        final raw = session.currentAnswers['q_$globalIdx'];
        // Writing/fill-blank/speaking answers are stored as free text;
        // MCQ answers are stored as selectedOptionId.
        final isTextAnswer = question.type == QuestionType.writing ||
            question.type == QuestionType.fillBlank ||
            question.type == QuestionType.speaking;
        final currentAnswer = raw == null
            ? QuestionAnswer(questionId: question.id)
            : isTextAnswer
                ? QuestionAnswer(questionId: question.id, writtenAnswer: raw)
                : QuestionAnswer(questionId: question.id, selectedOptionId: raw);

        return SingleChildScrollView(
          // Key by question.id so StatefulWidget descendants (e.g.
          // WritingInputExercise's TextEditingController) are fully
          // recreated when the question changes, not reused.
          key: ValueKey(question.id),
          child: QuestionShell(
            question: question,
            currentAnswer: currentAnswer,
            isSubmitted: false,
            onAnswerChanged: (qa) => ref
                .read(examSessionNotifierProvider(attemptId).notifier)
                .answer(
                  'q_$globalIdx',
                  qa.selectedOptionId ?? qa.writtenAnswer ?? '',
                ),
          ),
        );
      },
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _SessionLoadingScreen extends StatelessWidget {
  const _SessionLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget block({double h = 16, double? w}) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.x2),
          child: LoadingShimmer(
            child: Container(
              height: h,
              width: w ?? double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Đang tải...')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            block(h: 8, w: double.infinity), // progress bar
            const SizedBox(height: AppSpacing.x4),
            block(h: 14, w: 120),
            const SizedBox(height: AppSpacing.x3),
            block(h: 120),
            const SizedBox(height: AppSpacing.x4),
            block(h: 52),
            block(h: 52),
            block(h: 52),
            block(h: 52),
          ],
        ),
      ),
    );
  }
}
