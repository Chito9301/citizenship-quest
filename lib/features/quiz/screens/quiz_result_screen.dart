import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../gamification/models/badge.dart';
import '../providers/quiz_provider.dart';
import '../providers/quiz_state.dart';

class QuizResultScreen extends ConsumerStatefulWidget {
  const QuizResultScreen({super.key});

  @override
  ConsumerState<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends ConsumerState<QuizResultScreen> {
  bool _showFailedQuestions = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(quizControllerProvider);
    final controller = ref.read(quizControllerProvider.notifier);

    final accuracy = state.totalQuestions == 0
        ? 0.0
        : state.correctAnswers / state.totalQuestions;
    final accuracyPercent = (accuracy * 100).round();
    final avgSeconds = state.avgSecondsPerQuestion;
    final failedQuestions = state.failedQuestions;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resultTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Celebration(),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  l10n.yourScore,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              // Animación de conteo del puntaje: sutil (~800ms), no
              // exagerada.
              Center(
                child: TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: state.score),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text(
                      '$value',
                      style: Theme.of(context).textTheme.displayMedium,
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  l10n.correctCount(state.correctAnswers, state.totalQuestions),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: _ScoreComparison(
                  currentScore: state.score,
                  previousScore: state.previousSessionScore,
                ),
              ),
              const SizedBox(height: 20),
              _ResultStatsRow(
                accuracyPercent: accuracyPercent,
                avgSeconds: avgSeconds,
              ),
              const SizedBox(height: 20),
              _MotivationalMessage(accuracy: accuracy),
              if (state.newlyUnlockedBadgeIds.isNotEmpty) ...[
                const SizedBox(height: 16),
                _NewBadgesBanner(badgeIds: state.newlyUnlockedBadgeIds),
              ],
              const SizedBox(height: 24),

              if (failedQuestions.isEmpty)
                _NoErrorsBanner(l10n: l10n)
              else ...[
                OutlinedButton.icon(
                  icon: Icon(_showFailedQuestions ? Icons.expand_less : Icons.expand_more),
                  label: Text(
                    _showFailedQuestions
                        ? l10n.resultHideErrors
                        : l10n.resultReviewErrors(failedQuestions.length),
                  ),
                  onPressed: () => setState(() => _showFailedQuestions = !_showFailedQuestions),
                ),
                if (_showFailedQuestions) ...[
                  const SizedBox(height: 12),
                  for (final result in failedQuestions)
                    _FailedQuestionCard(result: result),
                ],
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // startQuiz() ya reemplaza el QuizState entero por
                  // uno nuevo (score, índice, power-ups en cero), no
                  // hace falta llamar reset() antes.
                  controller.startQuiz();
                  Navigator.of(context).pop();
                },
                child: Text(l10n.playAgain),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  controller.reset();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(l10n.goHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Celebration extends StatelessWidget {
  const _Celebration();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Icon(
          Icons.emoji_events,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.resultCelebrationTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

/// Compara el puntaje de esta partida con el de la anterior. Si
/// `previousScore` es null (primera partida de la app, o el dato
/// todavía no terminó de cargar desde el storage), no muestra nada en
/// vez de inventar una comparación.
class _ScoreComparison extends StatelessWidget {
  const _ScoreComparison({required this.currentScore, required this.previousScore});

  final int currentScore;
  final int? previousScore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final previous = previousScore;
    if (previous == null) return const SizedBox.shrink();

    final delta = currentScore - previous;
    final Color color;
    final IconData icon;
    final String text;

    if (delta > 0) {
      color = Colors.green;
      icon = Icons.trending_up;
      text = l10n.resultComparisonUp(delta);
    } else if (delta < 0) {
      color = Theme.of(context).colorScheme.error;
      icon = Icons.trending_down;
      text = l10n.resultComparisonDown(-delta);
    } else {
      color = Theme.of(context).colorScheme.outline;
      icon = Icons.trending_flat;
      text = l10n.resultComparisonSame;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ResultStatsRow extends StatelessWidget {
  const _ResultStatsRow({
    required this.accuracyPercent,
    required this.avgSeconds,
  });

  final int accuracyPercent;
  final double avgSeconds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _StatChip(
            icon: Icons.percent,
            label: l10n.accuracyLabel,
            value: '$accuracyPercent%',
          ),
        ),
        Expanded(
          child: _StatChip(
            icon: Icons.timer_outlined,
            label: l10n.avgTimePerQuestion,
            value: '${avgSeconds.toStringAsFixed(1)}s',
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Mensaje motivacional según el desempeño. Los umbrales son
/// deliberadamente simples (sin lógica de racha ni comparación
/// histórica) para que el mensaje sea inmediato y predecible.
class _MotivationalMessage extends StatelessWidget {
  const _MotivationalMessage({required this.accuracy});

  final double accuracy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = accuracy >= 0.9
        ? l10n.motivationExcellent
        : accuracy >= 0.7
            ? l10n.motivationGood
            : l10n.motivationKeepPracticing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NewBadgesBanner extends StatelessWidget {
  const _NewBadgesBanner({required this.badgeIds});

  final List<String> badgeIds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final badges = badgeIds.map(BadgeCatalog.byId).whereType<BadgeDef>().toList();
    if (badges.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.resultNewBadgesTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: badges
                .map((b) => Chip(
                      avatar: Text(b.icon, style: const TextStyle(fontSize: 16)),
                      label: Text(b.titleFor(languageCode)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _NoErrorsBanner extends StatelessWidget {
  const _NoErrorsBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.resultNoErrors)),
        ],
      ),
    );
  }
}

/// Tarjeta de una pregunta fallada: enunciado, respuesta elegida por el
/// usuario, respuesta correcta y explicación. Los tres textos salen
/// directamente de `QuizQuestion` (que viene de assets/data/preguntas.json)
/// y de `selectedOptionIndex` (lo que el usuario tocó de verdad) — nada
/// se inventa ni se aproxima.
class _FailedQuestionCard extends StatelessWidget {
  const _FailedQuestionCard({required this.result});

  final FailedQuestionResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final question = result.question;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.questionFor(languageCode),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cancel, size: 18, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${l10n.resultYourAnswerLabel}: ${result.selectedOption.textFor(languageCode)}',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, size: 18, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${l10n.resultCorrectAnswerLabel}: ${result.correctOption.textFor(languageCode)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              question.explanationFor(languageCode),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
