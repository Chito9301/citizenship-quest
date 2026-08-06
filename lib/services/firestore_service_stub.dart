/// Entrada de ranking simulada.
class RankingEntry {
  final String uid;
  final String displayName;
  final int score;
  final int rank;

  const RankingEntry({
    required this.uid,
    required this.displayName,
    required this.score,
    required this.rank,
  });
}

/// Stub de un futuro FirestoreService.
///
/// Sprint 1: no hay backend real. Devuelve datos mock para que las
/// pantallas de Ranking y la lógica de sincronización se puedan construir
/// y probar de punta a punta. Cuando exista el backend, se reemplaza la
/// implementación interna por llamadas reales a Cloud Firestore
/// manteniendo la misma interfaz pública (mismos métodos y tipos).
class FirestoreServiceStub {
  /// Simula subir el progreso de un usuario a Firestore.
  /// Devuelve `true` si la sincronización "fue exitosa".
  Future<bool> syncProgress({
    required String uid,
    required Map<String, dynamic> payload,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    // En Sprint 1 siempre "tiene éxito" para poder probar el flujo
    // completo sin depender de conectividad real.
    return true;
  }

  /// Devuelve un ranking global simulado.
  Future<List<RankingEntry>> getRanking({int limit = 20}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final mockNames = [
      'Alex',
      'María',
      'Sam',
      'Laila',
      'Chen',
      'Priya',
      'Diego',
      'Fatima',
      'Noah',
      'Sofía',
    ];

    return List.generate(mockNames.length, (index) {
      return RankingEntry(
        uid: 'mock-uid-$index',
        displayName: mockNames[index],
        score: 1000 - (index * 47),
        rank: index + 1,
      );
    }).take(limit).toList();
  }
}
