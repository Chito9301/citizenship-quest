import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../services/sync_service.dart';
import '../../quiz/providers/quiz_provider.dart';

/// Locale seleccionado por el usuario. `null` significa "seguir el
/// idioma del dispositivo".
final localeProvider = StateProvider<Locale?>((ref) => null);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadReminderPrefs();
  }

  Future<void> _loadReminderPrefs() async {
    final storage = ref.read(localStorageServiceProvider);
    if (!storage.isInitialized) await storage.init();
    if (!mounted) return;
    setState(() {
      _reminderEnabled = storage.isDailyReminderEnabled;
      _reminderTime = TimeOfDay(hour: storage.reminderHour, minute: storage.reminderMinute);
      _loaded = true;
    });
  }

  Future<void> _applyReminderState(bool enabled) async {
    final storage = ref.read(localStorageServiceProvider);
    final l10n = AppLocalizations.of(context);

    if (enabled) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.notificationsPermissionDenied)),
        );
        return;
      }
      await NotificationService.instance.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
        title: l10n.notificationTitle,
        body: l10n.notificationBody,
      );
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }

    await storage.saveReminderPreference(
      enabled: enabled,
      hour: _reminderTime.hour,
      minute: _reminderTime.minute,
    );

    if (!mounted) return;
    setState(() => _reminderEnabled = enabled);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked == null) return;

    setState(() => _reminderTime = picked);

    if (_reminderEnabled) {
      final l10n = AppLocalizations.of(context);
      await NotificationService.instance.scheduleDailyReminder(
        hour: picked.hour,
        minute: picked.minute,
        title: l10n.notificationTitle,
        body: l10n.notificationBody,
      );
      await ref.read(localStorageServiceProvider).saveReminderPreference(
            enabled: true,
            hour: picked.hour,
            minute: picked.minute,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider) ?? Localizations.localeOf(context);

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

            Text(
              l10n.notificationsSectionTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.dailyReminderLabel),
              subtitle: Text(l10n.dailyReminderSubtitle),
              value: _reminderEnabled,
              onChanged: _loaded ? (value) => _applyReminderState(value) : null,
            ),
            if (_reminderEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text(l10n.reminderTimeLabel),
                trailing: Text(_reminderTime.format(context)),
                onTap: _pickTime,
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
