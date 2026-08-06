import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class PowerUpBar extends StatelessWidget {
  const PowerUpBar({
    super.key,
    required this.fiftyFiftyUsed,
    required this.skipUsed,
    required this.answered,
    required this.onFiftyFifty,
    required this.onSkip,
  });

  final bool fiftyFiftyUsed;
  final bool skipUsed;
  final bool answered;
  final VoidCallback onFiftyFifty;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: (fiftyFiftyUsed || answered) ? null : onFiftyFifty,
            icon: const Icon(Icons.percent),
            label: Text(l10n.fiftyFifty),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: (skipUsed || answered) ? null : onSkip,
            icon: const Icon(Icons.skip_next),
            label: Text(l10n.skipQuestion),
          ),
        ),
      ],
    );
  }
}
