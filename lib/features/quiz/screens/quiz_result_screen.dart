import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../providers/quiz_provider.dart';

class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(quizControllerProvider);
    final controller = ref.read(quizControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resultTitle)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.yourScore,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${state.score}',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.correctCount(state.correctAnswers, state.totalQuestions),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      controller.reset();
                      controller.startQuiz();
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.playAgain),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      controller.reset();
                      Navigator.of(context)
                          .popUntil((route) => route.isFirst);
                    },
                    child: Text(l10n.goHome),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
