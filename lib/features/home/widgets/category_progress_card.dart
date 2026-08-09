import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../models/quiz_models.dart';

/// Traduce el id de categoría interno (el que viene en preguntas.json,
/// ej. "american_government") a un nombre presentable. Cualquier
/// categoría nueva que se agregue al banco de preguntas sin actualizar
/// este mapa cae en el fallback (capitaliza el id crudo), así que
/// nunca rompe la UI, solo se ve menos pulido hasta que se le agregue
/// una traducción.
String categoryDisplayName(String categoryId, AppLocalizations l10n) {
  switch (categoryId) {
    case 'american_government':
      return l10n.categoryGovernment;
    case 'american_history':
      return l10n.categoryHistory;
    case 'civics_integrated':
    case 'civics_rights':
      return l10n.categoryCivics;
    default:
      return categoryId
          .split('_')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
  }
}

class CategoryProgressCard extends StatelessWidget {
  const CategoryProgressCard({
    super.key,
    required this.categoryId,
    required this.stat,
  });

  final String categoryId;
  final CategoryStat stat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = (stat.accuracy * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Expanded + ellipsis: sin esto, un nombre de categoría
              // largo (ej. "Educación cívica" o el fallback
              // capitalizado de un id nuevo) puede desbordar cuando
              // comparte la fila con el porcentaje a la derecha.
              Expanded(
                child: Text(
                  categoryDisplayName(categoryId, l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                stat.total == 0 ? '—' : '$percent%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: stat.total == 0 ? 0 : stat.accuracy,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
