import 'dart:async';
import 'dart:convert';

import '../core/local_storage_service.dart';
import '../models/quiz_models.dart';
import 'auth_service_stub.dart';
import 'firestore_service_stub.dart';

/// Procesa la cola local (SyncQueueItem en el JSON de LocalStorageService)
/// y "sube" cada entrada pendiente usando FirestoreServiceStub. Diseñado
/// para funcionar offline primero: cada resultado de quiz se guarda
/// localmente de inmediato y se encola; este servicio se encarga de
/// vaciar la cola cuando hay conectividad (en Sprint 1 siempre "hay
/// conectividad" porque el stub simula éxito).
class SyncService {
  SyncService({
    LocalStorageService? storageService,
    FirestoreServiceStub? firestoreService,
    AuthServiceStub? authService,
  })  : _storageService = storageService ?? LocalStorageService.instance,
        _firestoreService = firestoreService ?? FirestoreServiceStub(),
        _authService = authService ?? AuthServiceStub();

  final LocalStorageService _storageService;
  final FirestoreServiceStub _firestoreService;
  final AuthServiceStub _authService;

  static const int maxAttempts = 5;

  bool _isSyncing = false;

  Future<void> enqueueQuizCompleted({
    required int score,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    final item = SyncQueueItem(
      operationType: SyncOperationType.quizCompleted,
      payloadJson: jsonEncode({
        'score': score,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      createdAt: DateTime.now(),
    );

    await _storageService.enqueueSync(item);
  }

  /// Intenta vaciar la cola de sincronización. Seguro de llamar varias
  /// veces seguidas (usa un flag interno para evitar corridas
  /// concurrentes).
  Future<void> processPendingQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      var user = _authService.currentUser;
      user ??= await _authService.signInAnonymously();

      final pending = await _storageService.getPendingSyncItems();

      for (final item in pending) {
        if (item.attemptCount >= maxAttempts) continue;

        try {
          final payload =
              jsonDecode(item.payloadJson) as Map<String, dynamic>;
          final ok = await _firestoreService.syncProgress(
            uid: user.uid,
            payload: payload,
          );
          if (ok) {
            await _storageService.markSynced(item.id);
          } else {
            await _storageService.markSyncAttemptFailed(item.id);
          }
        } catch (_) {
          await _storageService.markSyncAttemptFailed(item.id);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
