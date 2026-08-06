import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../providers/quiz_provider.dart';
import '../providers/quiz_state.dart';
import '../widgets/power_up_bar.dart';
import '../widgets/question_card.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(quizControllerProvider);
      if (state.status == QuizStatus.initial) {
        ref.read(quizControllerProvider.notifier).startQuiz();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(quizControllerProvider);
    final controller = ref.read(quizControllerProvider.notifier);

    ref.listen<QuizState>(quizControllerProvider, (previous, next) {
      if (next.status == QuizStatus.finished &&
          previous?.status != QuizStatus.finished) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const QuizResultScreen()),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.quizTitle)),
      body: SafeArea(
        child: _buildBody(context, l10n, state, controller),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    QuizState state,
    QuizController controller,
  ) {
    if (state.status == QuizStatus.loading ||
        state.status == QuizStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == QuizStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.errorLabel),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => controller.startQuiz(),
              child: Text(l10n.retryLabel),
            ),
          ],
        ),
      );
    }

    final question = state.currentQuestion;
    if (question == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (state.currentIndex + 1) / state.totalQuestions,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.questionOf(state.currentIndex + 1, state.totalQuestions),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: QuestionCard(
                question: question,
                selectedOptionIndex: state.selectedOptionIndex,
                hiddenOptionIndexes: state.hiddenOptionIndexes,
                onOptionSelected: controller.selectAnswer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          PowerUpBar(
            fiftyFiftyUsed: state.fiftyFiftyUsed,
            skipUsed: state.skipUsed,
            answered: state.hasAnswered,
            onFiftyFifty: controller.useFiftyFifty,
            onSkip: controller.skipQuestion,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: state.hasAnswered ? controller.goToNextQuestion : null,
            child: Text(
              state.isLastQuestion ? l10n.finishQuiz : l10n.nextQuestion,
            ),
          ),
        ],
      ),
    );
  }
}
