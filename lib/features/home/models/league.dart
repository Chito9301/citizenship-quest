import 'package:flutter/material.dart';

/// Liga semanal: puramente derivada de `totalScore` para mostrar en
/// Home. No es un dato persistido ni afecta el puntaje; es solo una
/// forma de presentar el progreso. Los umbrales son provisionales y se
/// pueden ajustar sin migrar ningún dato guardado.
enum League {
  bronze(minPoints: 0, maxPoints: 199, icon: '🥉'),
  silver(minPoints: 200, maxPoints: 499, icon: '🥈'),
  gold(minPoints: 500, maxPoints: 999, icon: '🥇'),
  citizen(minPoints: 1000, maxPoints: null, icon: '🏛️');

  const League({required this.minPoints, required this.maxPoints, required this.icon});

  final int minPoints;
  final int? maxPoints; // null = sin techo (liga más alta)
  final String icon;

  static League fromPoints(int points) {
    for (final league in League.values) {
      if (points >= league.minPoints &&
          (league.maxPoints == null || points <= league.maxPoints!)) {
        return league;
      }
    }
    return League.bronze;
  }

  /// Puntos que faltan para la siguiente liga. 0 si ya está en la más
  /// alta (Ciudadano).
  int pointsToNextLeague(int currentPoints) {
    final next = maxPoints;
    if (next == null) return 0;
    return (next + 1 - currentPoints).clamp(0, next + 1);
  }

  /// Progreso (0.0–1.0) dentro del rango de la liga actual, para una
  /// barra de progreso hacia la siguiente liga.
  double progressWithinLeague(int currentPoints) {
    final max = maxPoints;
    if (max == null) return 1.0;
    final range = (max + 1 - minPoints);
    if (range <= 0) return 1.0;
    return ((currentPoints - minPoints) / range).clamp(0.0, 1.0);
  }

  String nameFor(String languageCode) {
    final es = languageCode == 'es';
    return switch (this) {
      League.bronze => es ? 'Bronce' : 'Bronze',
      League.silver => es ? 'Plata' : 'Silver',
      League.gold => es ? 'Oro' : 'Gold',
      League.citizen => es ? 'Ciudadano' : 'Citizen',
    };
  }

  Color color(BuildContext context) {
    return switch (this) {
      League.bronze => const Color(0xFFCD7F32),
      League.silver => const Color(0xFFB0B7BF),
      League.gold => const Color(0xFFD4AF37),
      League.citizen => Theme.of(context).colorScheme.primary,
    };
  }
}
