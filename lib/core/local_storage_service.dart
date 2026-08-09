import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';

import '../models/quiz_models.dart';

/// Almacenamiento local basado en un único archivo JSON.
///
/// No requiere build_runner ni ningún paso de generación de código:
/// todo el (de)serializado es manual en quiz_models.dart. Pensado para
/// funcionar bien en condiciones inestables (apagones):
///
/// - Cada escritura es "atómica" (se escribe a un archivo temporal y
///   luego se renombra), así que un corte de luz a mitad de guardado
///   nunca corrompe el archivo principal.
/// - Al iniciar, se limpia cualquier `.tmp` huérfano que haya quedado
///   de un corte de luz exactamente en el instante de renombrar.
/// - Todas las operaciones de escritura se serializan con un lock en
///   memoria, para que dos guardados concurrentes (por ejemplo, un
///   `saveProgress` y un `enqueueSync` casi simultáneos) nunca se
///   pisen ni pierdan datos entre el `read` y el `write`.
/// - Si el JSON no se puede decodificar, se recupera con datos por
///   defecto en vez de tumbar la app.
class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  /// Crea una instancia independiente de [instance] que escribe
  /// directamente en [file], sin pasar por `path_provider`. Pensado
  /// exclusivamente para tests unitarios (ver test/local_storage_service_test.dart),
  /// donde no hay un canal de plataforma real disponible.
  @visibleForTesting
  factory LocalStorageService.withFile(File file) {
    final service = LocalStorageService._();
    service._file = file;
    return service;
  }

  static const String _fileName = 'citizenship_quest_data.json';
  static const String defaultProfileKey = 'local_profile';

  File? _file;
  Map<String, dynamic> _data = _defaultData();
  bool _initialized = false;

  /// Memoiza la Future de inicialización: si dos llamadas a [init]
  /// (o a cualquier método que dependa de [_ensureInit]) llegan casi
  /// al mismo tiempo antes de que termine la primera, ambas esperan la
  /// MISMA inicialización en vez de correr dos veces en paralelo.
  Future<void>? _initFuture;

  /// Cola de exclusión mutua en memoria: cada operación que lee y
  /// luego escribe `_data` se encadena a esta Future, así nunca se
  /// ejecutan dos "lecturas + escrituras" en paralelo sobre el mismo
  /// estado.
  Future<void> _writeLock = Future.value();

  final StreamController<UserProgress?> _progressController =
      StreamController<UserProgress?>.broadcast();

  bool get isInitialized => _initialized;

  // -------------------------------------------------------------------
  // Onboarding (flag simple, independiente de UserProgress)
  // -------------------------------------------------------------------

  /// Lectura síncrona a propósito: para cuando se llama, `main.dart` ya
  /// hizo `await LocalStorageService.instance.init()`, así que `_data`
  /// ya está cargado en memoria. Evita tener que modelar el arranque
  /// del router como un estado "cargando" solo por este flag.
  bool get hasSeenOnboarding => _data['hasSeenOnboarding'] as bool? ?? false;

  Future<void> setHasSeenOnboarding(bool value) {
    return _synchronized(() async {
      await _ensureInit();
      _data['hasSeenOnboarding'] = value;
      await _persist();
    });
  }

  // -------------------------------------------------------------------
  // Preferencias del recordatorio diario (notificaciones locales)
  // -------------------------------------------------------------------

  bool get isDailyReminderEnabled => _data['reminderEnabled'] as bool? ?? false;
  int get reminderHour => _data['reminderHour'] as int? ?? 19;
  int get reminderMinute => _data['reminderMinute'] as int? ?? 0;

  Future<void> saveReminderPreference({
    required bool enabled,
    required int hour,
    required int minute,
  }) {
    return _synchronized(() async {
      await _ensureInit();
      _data['reminderEnabled'] = enabled;
      _data['reminderHour'] = hour;
      _data['reminderMinute'] = minute;
      await _persist();
    });
  }

  static Map<String, dynamic> _defaultData() => {
        'userProgress':
            const UserProgress(profileKey: defaultProfileKey).toJson(),
        'syncQueue': <Map<String, dynamic>>[],
        'nextSyncId': 1,
      };

  Future<void> init() {
    return _initFuture ??= _performInit();
  }

  Future<void> _performInit() async {
    if (_file == null) {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/$_fileName');
    }

    // Limpieza de arranque: si quedó un .tmp de una escritura anterior
    // interrumpida (apagón justo antes del rename), se descarta. El
    // archivo principal nunca se tocó durante esa escritura fallida,
    // así que sigue siendo válido.
    final orphanedTemp = File('${_file!.path}.tmp');
    if (await orphanedTemp.exists()) {
      try {
        await orphanedTemp.delete();
      } catch (_) {
        // No crítico: si no se puede borrar ahora, se sobrescribirá en
        // el próximo _persist() de todas formas.
      }
    }

    if (await _file!.exists()) {
      try {
        final raw = await _file!.readAsString();
        _data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        // Archivo corrupto (por ejemplo, por un apagón a mitad de una
        // escritura de una versión anterior de la app, antes de que
        // existiera la escritura atómica). Se reinicia con datos por
        // defecto en lugar de tumbar la app.
        _data = _defaultData();
        await _persist();
      }
    } else {
      _data = _defaultData();
      await _persist();
    }

    _initialized = true;
  }

  Future<void> close() async {
    await _progressController.close();
    _initialized = false;
    _initFuture = null;
  }

  /// Ejecuta [action] en exclusión mutua respecto de cualquier otra
  /// operación de escritura en curso. La UI nunca se bloquea por esto:
  /// solo se encadenan las propias tareas async de almacenamiento
  /// entre sí, nunca el hilo de la UI.
  Future<T> _synchronized<T>(Future<T> Function() action) {
    final previous = _writeLock;
    final completer = Completer<void>();
    _writeLock = completer.future;

    return previous.then((_) async {
      try {
        return await action();
      } finally {
        completer.complete();
      }
    });
  }

  /// Escritura atómica: escribe en un archivo temporal y recién ahí lo
  /// renombra sobre el archivo real, para no dejar nunca el archivo
  /// principal a medio escribir.
  Future<void> _persist() async {
    final file = _file;
    if (file == null) return;

    final tempFile = File('${file.path}.tmp');
    await tempFile.writeAsString(jsonEncode(_data), flush: true);
    await tempFile.rename(file.path);
  }

  Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }

  // -------------------------------------------------------------------
  // UserProgress
  // -------------------------------------------------------------------

  Future<UserProgress> getOrCreateProgress() async {
    await _ensureInit();
    return _synchronized(() async {
      final raw = _data['userProgress'] as Map<String, dynamic>?;
      if (raw == null) {
        const fresh = UserProgress(profileKey: defaultProfileKey);
        _data['userProgress'] = fresh.toJson();
        await _persist();
        return fresh;
      }
      return UserProgress.fromJson(raw);
    });
  }

  Future<void> saveProgress(UserProgress progress) async {
    await _ensureInit();
    await _synchronized(() async {
      _data['userProgress'] = progress.toJson();
      await _persist();
    });
    _progressController.add(progress);
  }

  /// Emite el progreso actual de inmediato y luego cada vez que cambie.
  Stream<UserProgress?> watchProgress() async* {
    await _ensureInit();
    yield await getOrCreateProgress();
    yield* _progressController.stream;
  }

  // -------------------------------------------------------------------
  // Cola de sincronización
  // -------------------------------------------------------------------

  Future<void> enqueueSync(SyncQueueItem item) {
    return _synchronized(() async {
      await _ensureInit();
      final nextId = _data['nextSyncId'] as int? ?? 1;
      final withId = item.copyWith(id: nextId);

      final queue =
          List<dynamic>.from(_data['syncQueue'] as List<dynamic>? ?? []);
      queue.add(withId.toJson());

      _data['syncQueue'] = queue;
      _data['nextSyncId'] = nextId + 1;
      await _persist();
    });
  }

  Future<List<SyncQueueItem>> getPendingSyncItems() async {
    await _ensureInit();
    return _synchronized(() async {
      final queue = (_data['syncQueue'] as List<dynamic>? ?? []);
      return queue
          .map((e) => SyncQueueItem.fromJson(e as Map<String, dynamic>))
          .where((item) => !item.synced)
          .toList();
    });
  }

  Future<void> markSynced(int id) {
    return _updateSyncItem(
      id,
      (item) => item.copyWith(synced: true, syncedAt: DateTime.now()),
    );
  }

  Future<void> markSyncAttemptFailed(int id) {
    return _updateSyncItem(
      id,
      (item) => item.copyWith(attemptCount: item.attemptCount + 1),
    );
  }

  Future<void> _updateSyncItem(
    int id,
    SyncQueueItem Function(SyncQueueItem item) update,
  ) {
    return _synchronized(() async {
      await _ensureInit();
      final queue =
          List<dynamic>.from(_data['syncQueue'] as List<dynamic>? ?? []);
      final index = queue.indexWhere(
        (e) => (e as Map<String, dynamic>)['id'] == id,
      );
      if (index == -1) return;

      final current =
          SyncQueueItem.fromJson(queue[index] as Map<String, dynamic>);
      final updated = update(current);
      queue[index] = updated.toJson();

      _data['syncQueue'] = queue;
      await _persist();
    });
  }
}
