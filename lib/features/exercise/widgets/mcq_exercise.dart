import 'package:flutter/material.dart';
import 'package:app_czech/core/theme/app_spacing.dart';
import 'package:app_czech/core/theme/app_typography.dart';
import 'package:app_czech/shared/models/question_model.dart';
import 'mcq_option_tile.dart';

class McqExercise extends StatelessWidget {
  const McqExercise({
    super.key,
    required this.question,
    this.selectedOptionId,
    this.isSubmitted = false,
    this.onSelect,
  });

  final Question question;
  final String? selectedOptionId;
  final bool isSubmitted;
  final ValueChanged<String>? onSelect;

  OptionState _stateFor(QuestionOption opt) {
    if (!isSubmitted) {
      return selectedOptionId == opt.id
          ? OptionState.selected
          : OptionState.idle;
    }
    // After submit: show correct/incorrect
    if (opt.isCorrect) return OptionState.correct;
    if (opt.id == selectedOptionId && !opt.isCorrect) {
      return OptionState.incorrect;
    }
    return OptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Prompt
        Text(question.prompt, style: AppTypography.bodyLarge),
        const SizedBox(height: AppSpacing.x5),
        // Options
        ...question.options.asMap().entries.map(
              (e) => McqOptionTile(
                option: e.value,
                optionState: _stateFor(e.value),
                index: e.key,
                onTap: isSubmitted
                    ? null
                    : () => onSelect?.call(e.value.id),
              ),
            ),
      ],
    );
  }
}
