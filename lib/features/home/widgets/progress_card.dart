import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

/// Tarjeta de progreso general: "X/Y preguntas dominadas".
///
/// Nota de diseño: hoy no existe tracking por pregunta individual (ver
/// smart_review_provider.dart), así que "dominadas" es una aproximación
/// razonable = total de respuestas correctas acumuladas, con techo en
/// el tamaño del banco de preguntas. No es una medida exacta de
/// preguntas únicas dominadas; cuando exista tracking por pregunta,
/// solo hay que cambiar el cálculo que llega en [masteredCount].
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.masteredCount,
    required this.totalCount,
  });

  final int masteredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ratio = totalCount == 0 ? 0.0 : (masteredCount / totalCount).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homeQuestionsMastered(masteredCount, totalCount),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 6),
            Text('$percent%', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
