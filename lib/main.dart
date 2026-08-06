import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/local_storage_service.dart';
import 'core/localization/app_localizations.dart';
import 'core/router/app_router.dart';
import 'features/settings/screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // El almacenamiento local debe inicializarse antes de que cualquier
  // provider intente leer/escribir datos.
  await LocalStorageService.instance.init();

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
