import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../models/quiz_models.dart';
import '../../home/widgets/category_progress_card.dart';
import '../../profile/providers/profile_provider.dart';
import '../widgets/activity_calendar.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final progressAsync = ref.watch(userProgressStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: SafeArea(
        child: progressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('${l10n.errorLabel}: $err')),
          data: (progress) {
            final p = progress ?? const UserProgress();
            // Mismo criterio que Home: el denominador es el banco
            // OFICIAL de USCIS (100), no la cantidad de preguntas que
            // hay hoy en preguntas.json.
            const totalCount = officialUscisQuestionBankSize;
            final masteredCount = p.totalCorrectAnswers.clamp(0, totalCount);
            final accuracyPercent = (p.accuracy * 100).round();
            final studyHours = p.totalStudySeconds ~/ 3600;
            final studyMinutes = (p.totalStudySeconds % 3600) ~/ 60;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _StatCard(
                      icon: Icons.percent,
                      label: l10n.statsGlobalAccuracy,
                      value: '$accuracyPercent%',
                    ),
                    _StatCard(
                      icon: Icons.quiz,
                      label: l10n.quizzesPlayed,
                      value: '${p.totalQuizzesPlayed}',
                    ),
                    _StatCard(
                      icon: Icons.school,
                      label: l10n.statsQuestionsMastered,
                      value: '$masteredCount / $totalCount',
                    ),
                    _StatCard(
                      icon: Icons.timer,
                      label: l10n.statsTotalStudyTime,
                      value: studyHours > 0 ? '${studyHours}h ${studyMinutes}m' : '${studyMinutes}m',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (p.strongestCategory != null || p.weakestCategory != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.strongestCategory != null)
                            _CategoryHighlight(
                              icon: Icons.trending_up,
                              color: Colors.green,
                              label: l10n.statsStrongestCategory,
                              categoryId: p.strongestCategory!,
                            ),
                          if (p.strongestCategory != null && p.weakestCategory != null)
                            const Divider(height: 24),
                          if (p.weakestCategory != null)
                            _CategoryHighlight(
                              icon: Icons.trending_down,
                              color: Theme.of(context).colorScheme.error,
                              label: l10n.statsWeakestCategory,
                              categoryId: p.weakestCategory!,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ActivityCalendar(activityDates: p.activityDates),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _CategoryHighlight extends StatelessWidget {
  const _CategoryHighlight({
    required this.icon,
    required this.color,
    required this.label,
    required this.categoryId,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              categoryDisplayName(categoryId, l10n),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
