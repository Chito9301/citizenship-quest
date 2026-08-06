import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../models/quiz_models.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.selectedOptionIndex,
    required this.hiddenOptionIndexes,
    required this.onOptionSelected,
  });

  final QuizQuestion question;
  final int? selectedOptionIndex;
  final Set<int> hiddenOptionIndexes;
  final ValueChanged<int> onOptionSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final hasAnswered = selectedOptionIndex != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.questionFor(languageCode),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ...List.generate(question.options.length, (index) {
              if (hiddenOptionIndexes.contains(index)) {
                return const SizedBox.shrink();
              }

              final option = question.options[index];
              final isSelected = selectedOptionIndex == index;
              final isCorrectOption = index == question.correctIndex;

              Color? backgroundColor;
              Color? borderColor;
              if (hasAnswered) {
                if (isCorrectOption) {
                  backgroundColor = Colors.green.withOpacity(0.15);
                  borderColor = Colors.green;
                } else if (isSelected) {
                  backgroundColor = Colors.red.withOpacity(0.15);
                  borderColor = Colors.red;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: hasAnswered ? null : () => onOptionSelected(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border.all(
                        color: borderColor ??
                            Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(option.textFor(languageCode)),
                        ),
                        if (hasAnswered && isCorrectOption)
                          const Icon(Icons.check_circle, color: Colors.green),
                        if (hasAnswered && isSelected && !isCorrectOption)
                          const Icon(Icons.cancel, color: Colors.red),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (hasAnswered) ...[
              const SizedBox(height: 8),
              Text(
                selectedOptionIndex == question.correctIndex
                    ? l10n.correctAnswer
                    : l10n.incorrectAnswer,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selectedOptionIndex == question.correctIndex
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.explanationLabel} ${question.explanationFor(languageCode)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
