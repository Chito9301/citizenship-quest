import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../models/quiz_models.dart';
import '../../profile/providers/profile_provider.dart';
import '../../quiz/providers/quiz_provider.dart';
import '../../quiz/screens/quiz_screen.dart';
import '../widgets/category_progress_card.dart';
import '../widgets/league_card.dart';
import '../widgets/progress_card.dart';
import '../widgets/smart_review_card.dart';
import '../widgets/streak_card.dart';

/// Pantalla de inicio ("lobby") que se muestra antes de entrar al quiz.
/// Es puramente de presentación: lee `UserProgress` y el banco de
/// preguntas ya existentes, sin agregar ninguna regla nueva al quiz.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final progressAsync = ref.watch(userProgressStreamProvider);
    final questionsAsync = ref.watch(quizQuestionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: progressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('${l10n.errorLabel}: $err')),
          data: (progress) {
            final userProgress = progress ?? const UserProgress();
            final allQuestions = questionsAsync.valueOrNull ?? const <QuizQuestion>[];
            final totalCount = allQuestions.length;
            final masteredCount =
                userProgress.totalCorrectAnswers.clamp(0, totalCount == 0 ? 0 : totalCount);

            final categories = {for (final q in allQuestions) q.category};

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.homeGreeting,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                if (totalCount > 0)
                  Text(
                    l10n.homeQuestionsRemaining(
                      (totalCount - masteredCount).clamp(0, totalCount),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 20),

                ProgressCard(masteredCount: masteredCount, totalCount: totalCount),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: StreakCard(streakDays: userProgress.currentStreakDays)),
                    const SizedBox(width: 12),
                    Expanded(child: LeagueCard(totalPoints: userProgress.totalScore)),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      l10n.homeStartPractice,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _startPractice(context, ref),
                  ),
                ),
                const SizedBox(height: 24),

                Text(l10n.homeCategoriesTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (categories.isEmpty)
                          Text(l10n.loadingLabel)
                        else
                          for (final category in categories)
                            CategoryProgressCard(
                              categoryId: category,
                              stat: userProgress.categoryStats[category] ?? const CategoryStat(),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const SmartReviewCard(),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _startPractice(BuildContext context, WidgetRef ref) async {
    // Arranca la partida explícitamente ANTES de navegar (no depende
    // del auto-inicio reactivo de QuizScreen), para que un quiz recién
    // "finished" que el usuario no reinició explícitamente no bloquee
    // el botón "Comenzar práctica".
    await ref.read(quizControllerProvider.notifier).startQuiz();
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QuizScreen()),
      );
    }
  }
}
