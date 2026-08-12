import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/local_storage_service.dart';
import 'core/localization/app_localizations.dart';
import 'core/notifications/notification_service.dart';
import 'core/question_progress_service.dart';
import 'core/router/app_router.dart';
import 'features/settings/screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // El almacenamiento local debe inicializarse antes de que cualquier
  // provider intente leer/escribir datos.
  await LocalStorageService.instance.init();

  // Sprint 6: progreso por pregunta (repaso por errores). Archivo
  // independiente del anterior; una falla acá no afecta al Sprint 5.
  await QuestionProgressService.instance.init();

  // Notificaciones: se inicializa el plugin y, si el usuario ya había
  // activado el recordatorio diario en una sesión anterior, se vuelve
  // a programar en cada arranque. Es idempotente (mismo id de
  // notificación), así que no crea duplicados; sirve como red de
  // seguridad si el sistema operativo llegó a descartar la alarma.
  await NotificationService.instance.init();
  if (LocalStorageService.instance.isDailyReminderEnabled) {
    // No se pide permiso aquí: si el usuario lo revocó desde los
    // ajustes del sistema, la próxima vez que abra la pantalla de
    // Ajustes y reintente activarlo se le volverá a pedir.
    await NotificationService.instance.scheduleDailyReminder(
      hour: LocalStorageService.instance.reminderHour,
      minute: LocalStorageService.instance.reminderMinute,
      title: 'Citizenship Quest',
      body: '🔥 Tu progreso te espera. Dedica 5 minutos hoy.',
    );
  }

  runApp(const ProviderScope(child: CitizenshipQuestApp()));
}

class CitizenshipQuestApp extends ConsumerWidget {
  const CitizenshipQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final selectedLocale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Citizenship Quest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      locale: selectedLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
