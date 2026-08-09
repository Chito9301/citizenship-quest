import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../models/league.dart';

class LeagueCard extends StatelessWidget {
  const LeagueCard({super.key, required this.totalPoints});

  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final league = League.fromPoints(totalPoints);
    final progress = league.progressWithinLeague(totalPoints);
    final pointsToNext = league.pointsToNextLeague(totalPoints);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(league.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    league.nameFor(languageCode),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: league.color(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              pointsToNext > 0
                  ? l10n.homeLeaguePointsToNext(pointsToNext)
                  : l10n.homeLeagueMaxReached,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
