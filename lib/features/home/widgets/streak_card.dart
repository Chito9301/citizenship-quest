import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.currentStreak, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  l10n.homeStreakDays(streakDays),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
