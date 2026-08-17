import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../features/exam_selection/screens/exam_selection_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/ranking/screens/ranking_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/stats/screens/stats_screen.dart';
import '../../models/exam_version.dart';
import '../local_storage_service.dart';

/// Se inicializa con el valor ya cargado en disco por
/// `LocalStorageService.instance` (main.dart hace `await init()` antes
/// de `runApp`, así que esta lectura inicial es segura y síncrona). El
/// onboarding lo marca como visto escribiendo en este mismo provider,
/// sin necesidad de agregar una ruta nueva de GoRouter para eso.
final onboardingCompletedProvider = StateProvider<bool>((ref) {
  return LocalStorageService.instance.hasSeenOnboarding;
});

/// Igual patrón que `onboardingCompletedProvider`: se inicializa con lo
/// que ya haya en disco, y la propia pantalla de selección lo actualiza
/// al elegir el banco 2008 (el único funcional hoy). Sprint 7.8.
final examVersionSelectedProvider = StateProvider<bool>((ref) {
  return LocalStorageService.instance.hasSelectedExamVersion;
});

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AppRoot(),
      ),
    ],
  );
});

/// Punto de entrada de la app: muestra el Onboarding la primera vez,
/// después la selección de examen (Sprint 7.8) si todavía no se eligió
/// ninguna, y HomeShell (con la navegación inferior) el resto de las
/// veces.
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingCompleted = ref.watch(onboardingCompletedProvider);

    if (!onboardingCompleted) {
      return OnboardingScreen(
        onComplete: () {
          ref.read(onboardingCompletedProvider.notifier).state = true;
          unawaited(LocalStorageService.instance.setHasSeenOnboarding(true));
        },
      );
    }

    final examVersionSelected = ref.watch(examVersionSelectedProvider);

    if (!examVersionSelected) {
      return ExamSelectionScreen(
        onSelected: (version) {
          ref.read(examVersionSelectedProvider.notifier).state = true;
          unawaited(LocalStorageService.instance.setSelectedExamVersion(version));
        },
      );
    }

    return const HomeShell();
  }
}

/// Contenedor con navegación inferior entre las 5 secciones: Inicio
/// (Home/lobby, desde donde se entra al quiz), Estadísticas, Perfil,
/// Ranking y Ajustes.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    StatsScreen(),
    ProfileScreen(),
    RankingScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.navStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.navProfile,
          ),
          NavigationDestination(
            icon: const Icon(Icons.leaderboard_outlined),
            selectedIcon: const Icon(Icons.leaderboard),
            label: l10n.navRanking,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
