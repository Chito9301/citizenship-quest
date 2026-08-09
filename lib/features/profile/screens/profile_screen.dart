import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../gamification/models/badge.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final progressAsync = ref.watch(userProgressStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SafeArea(
        child: progressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('${l10n.errorLabel}: $err')),
          data: (progress) {
            if (progress == null) {
              return Center(child: Text(l10n.loadingLabel));
            }

            final accuracyPercent = (progress.accuracy * 100).toStringAsFixed(0);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatTile(
                  icon: Icons.star,
                  label: l10n.totalScore,
                  value: '${progress.totalScore}',
                ),
                _StatTile(
                  icon: Icons.quiz,
                  label: l10n.quizzesPlayed,
                  value: '${progress.totalQuizzesPlayed}',
                ),
                _StatTile(
                  icon: Icons.percent,
                  label: l10n.accuracyLabel,
                  value: '$accuracyPercent%',
                ),
                _StatTile(
                  icon: Icons.local_fire_department,
                  label: l10n.currentStreak,
                  value: '${progress.currentStreakDays}',
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.badgesLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (progress.unlockedBadgeIds.isEmpty)
                  Text(
                    l10n.noBadgesYet,
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: progress.unlockedBadgeIds.map((id) {
                      final badge = BadgeCatalog.byId(id);
                      final languageCode = Localizations.localeOf(context).languageCode;
                      if (badge == null) return Chip(label: Text(id));
                      return Tooltip(
                        message: badge.descriptionFor(languageCode),
                        child: Chip(
                          avatar: Text(badge.icon, style: const TextStyle(fontSize: 16)),
                          label: Text(badge.titleFor(languageCode)),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
