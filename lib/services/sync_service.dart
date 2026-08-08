import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/local_storage_service.dart';
import '../models/quiz_models.dart';
import 'auth_service_stub.dart';
import 'firestore_service_stub.dart';

/// Resultado de un intento de sincronización disparado manualmente
/// (botón "Sincronizar ahora"), para poder mostrar el mensaje correcto
/// en la UI sin adivinar ni lanzar excepciones.
enum SyncTriggerResult { noConnection, noPendingData, success, failed }

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
    Connectivity? connectivity,
  })  : _storageService = storageService ?? LocalStorageService.instance,
        _firestoreService = firestoreService ?? FirestoreServiceStub(),
        _authService = authService ?? AuthServiceStub(),
        _connectivity = connectivity ?? Connectivity();

  final LocalStorageService _storageService;
  final FirestoreServiceStub _firestoreService;
  final AuthServiceStub _authService;
  final Connectivity _connectivity;

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

  /// Sincronización disparada manualmente por el usuario (botón
  /// "Sincronizar ahora"). A diferencia de [processPendingQueue] (que
  /// es "best effort" y silenciosa), esta variante nunca lanza
  /// excepciones y siempre devuelve un resultado específico para que
  /// la UI muestre el mensaje correcto:
  /// - sin datos pendientes -> [SyncTriggerResult.noPendingData]
  /// - sin conexión         -> [SyncTriggerResult.noConnection]
  /// - todo sincronizado    -> [SyncTriggerResult.success]
  /// - algo falló           -> [SyncTriggerResult.failed]
  Future<SyncTriggerResult> syncNow() async {
    try {
      final pending = await _storageService.getPendingSyncItems();
      if (pending.isEmpty) return SyncTriggerResult.noPendingData;

      final connectivityResult = await _connectivity.checkConnectivity();
      final hasConnection = !connectivityResult.contains(ConnectivityResult.none);
      if (!hasConnection) return SyncTriggerResult.noConnection;

      await processPendingQueue();

      final stillPending = await _storageService.getPendingSyncItems();
      return stillPending.isEmpty
          ? SyncTriggerResult.success
          : SyncTriggerResult.failed;
    } catch (_) {
      return SyncTriggerResult.failed;
    }
  }

  /// Intenta vaciar la cola de sincronización. Seguro de llamar varias
  /// veces seguidas (usa un flag interno para evitar corridas
  /// concurrentes). Es "best effort": nunca lanza, y no distingue por
  /// qué no se pudo sincronizar (para eso está [syncNow]).
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
