import 'package:flutter/material.dart';
import 'package:app_czech/core/theme/app_colors.dart';
import 'package:app_czech/core/theme/app_spacing.dart';
import 'package:app_czech/core/theme/app_typography.dart';
import 'package:app_czech/shared/models/question_model.dart';

/// Slides up after submission to show the correct answer and explanation.
/// Can be embedded inline (isInline: true) or shown as a bottom sheet.
class ExplanationPanel extends StatelessWidget {
  const ExplanationPanel({
    super.key,
    required this.question,
    required this.isCorrect,
    this.isInline = true,
  });

  final Question question;
  final bool isCorrect;
  final bool isInline;

  /// Show as a modal bottom sheet. Returns when user taps "Tiếp tục".
  static Future<void> show(
    BuildContext context, {
    required Question question,
    required bool isCorrect,
    VoidCallback? onContinue,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheetWrapper(
        question: question,
        isCorrect: isCorrect,
        onContinue: onContinue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ExplanationContent(
      question: question,
      isCorrect: isCorrect,
    );
  }
}

// ── Bottom sheet wrapper ───────────────────────────────────────────────────────

class _BottomSheetWrapper extends StatelessWidget {
  const _BottomSheetWrapper({
    required this.question,
    required this.isCorrect,
    this.onContinue,
  });

  final Question question;
  final bool isCorrect;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.x4, AppSpacing.x3, AppSpacing.x4, AppSpacing.x4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.x4),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _ExplanationContent(question: question, isCorrect: isCorrect),
              const SizedBox(height: AppSpacing.x4),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onContinue?.call();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.x4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Tiếp tục',
                      style: AppTypography.labelLarge
                          .copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Content ────────────────────────────────────────────────────────────────────

class _ExplanationContent extends StatelessWidget {
  const _ExplanationContent({
    required this.question,
    required this.isCorrect,
  });

  final Question question;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result banner
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x4, vertical: AppSpacing.x3),
          decoration: BoxDecoration(
            color: isCorrect
                ? const Color(0xFFECFDF5) // emerald-50
                : AppColors.errorContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCorrect
                  ? const Color(0xFFD1FAE5) // emerald-100
                  : AppColors.error.withOpacity(0.15),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isCorrect
                    ? Icons.verified_rounded
                    : Icons.cancel_rounded,
                color: isCorrect
                    ? const Color(0xFF059669)
                    : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.x3),
              Text(
                isCorrect ? 'Chính xác!' : 'Chưa đúng',
                style: AppTypography.labelSmall.copyWith(
                  color: isCorrect
                      ? const Color(0xFF059669)
                      : AppColors.error,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x4),

        // Correct answer (if wrong)
        if (!isCorrect && question.correctAnswer != null) ...[
          Text('Đáp án đúng',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.x1),
          Text(
            question.correctAnswer!,
            style: AppTypography.bodyMedium.copyWith(
              color: const Color(0xFF16A34A),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
        ],

        // Explanation
        if (question.explanation.isNotEmpty) ...[
          Text('Giải thích',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.x2),
          Text(
            question.explanation,
            style: AppTypography.bodyMedium.copyWith(height: 1.6),
          ),
        ],
      ],
    );
  }
}
