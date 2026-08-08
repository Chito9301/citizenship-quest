import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../services/sync_service.dart';
import '../../quiz/providers/quiz_provider.dart';

/// Locale seleccionado por el usuario. `null` significa "seguir el
/// idioma del dispositivo".
final localeProvider = StateProvider<Locale?>((ref) => null);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider) ??
        Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.languageLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              title: Text(l10n.englishOption),
              value: 'en',
              groupValue: currentLocale.languageCode,
              onChanged: (_) {
                ref.read(localeProvider.notifier).state = const Locale('en');
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.spanishOption),
              value: 'es',
              groupValue: currentLocale.languageCode,
              onChanged: (_) {
                ref.read(localeProvider.notifier).state = const Locale('es');
              },
            ),
            const Divider(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.sync),
              label: Text(l10n.syncNow),
              onPressed: () async {
                final syncService = ref.read(syncServiceProvider);
                final result = await syncService.syncNow();
                if (!context.mounted) return;

                final message = switch (result) {
                  SyncTriggerResult.noConnection => l10n.syncNoConnection,
                  SyncTriggerResult.noPendingData => l10n.syncNoPendingData,
                  SyncTriggerResult.success => l10n.syncSuccess,
                  SyncTriggerResult.failed => l10n.syncFailed,
                };

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
