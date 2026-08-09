import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

/// Calendario simple de los últimos 7 días: un círculo por día,
/// relleno si hubo actividad ese día. `activityDates` son strings
/// 'yyyy-MM-dd' en UTC (ver UserProgress.activityDates).
class ActivityCalendar extends StatelessWidget {
  const ActivityCalendar({super.key, required this.activityDates});

  final List<String> activityDates;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = DateTime.now().toUtc();
    final todayDateOnly = DateTime.utc(today.year, today.month, today.day);
    final activitySet = activityDates.toSet();

    final days = List.generate(7, (i) => todayDateOnly.subtract(Duration(days: 6 - i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.statsActivityCalendarTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.map((day) {
            final key =
                '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
            final hasActivity = activitySet.contains(key);
            final isToday = day == todayDateOnly;

            return Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasActivity
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: isToday
                        ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: hasActivity
                      ? Icon(
                          Icons.check,
                          size: 18,
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  _weekdayLabel(day.weekday, l10n),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  String _weekdayLabel(int weekday, AppLocalizations l10n) {
    // weekday: 1 = lunes ... 7 = domingo (DateTime estándar de Dart)
    const en = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const es = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final labels = l10n.locale.languageCode == 'es' ? es : en;
    return labels[weekday - 1];
  }
}
