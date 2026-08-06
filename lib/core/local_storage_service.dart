import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/quiz_models.dart';

/// Almacenamiento local basado en un único archivo JSON.
///
/// Reemplaza a Isar para Sprint 1. No requiere build_runner ni ningún
/// paso de generación de código: todo el (de)serializado es manual en
/// quiz_models.dart. Pensado para funcionar bien en condiciones
/// inestables (apagones): cada escritura es "atómica" (se escribe a un
/// archivo temporal y luego se renombra), así que un corte de luz a
/// mitad de guardado no corrompe los datos ya guardados.
class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  static const String _fileName = 'citizenship_quest_data.json';
  static const String defaultProfileKey = 'local_profile';

  File? _file;
  Map<String, dynamic> _data = _defaultData();
  bool _initialized = false;

  final StreamController<UserProgress?> _progressController =
      StreamController<UserProgress?>.broadcast();

  bool get isInitialized => _initialized;

  static Map<String, dynamic> _defaultData() => {
        'userProgress':
            const UserProgress(profileKey: defaultProfileKey).toJson(),
        'syncQueue': <Map<String, dynamic>>[],
        'nextSyncId': 1,
      };

  Future<void> init() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/$_fileName');

    if (await _file!.exists()) {
      try {
        final raw = await _file!.readAsString();
        _data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        // Archivo corrupto (por ejemplo, por un apagón a mitad de una
        // escritura anterior a este cambio). Se reinicia con datos por
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
    final raw = _data['userProgress'] as Map<String, dynamic>?;
    if (raw == null) {
      const fresh = UserProgress(profileKey: defaultProfileKey);
      _data['userProgress'] = fresh.toJson();
      await _persist();
      return fresh;
    }
    return UserProgress.fromJson(raw);
  }

  Future<void> saveProgress(UserProgress progress) async {
    await _ensureInit();
    _data['userProgress'] = progress.toJson();
    await _persist();
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

  Future<void> enqueueSync(SyncQueueItem item) async {
    await _ensureInit();
    final nextId = _data['nextSyncId'] as int? ?? 1;
    final withId = item.copyWith(id: nextId);

    final queue = List<dynamic>.from(_data['syncQueue'] as List<dynamic>? ?? []);
    queue.add(withId.toJson());

    _data['syncQueue'] = queue;
    _data['nextSyncId'] = nextId + 1;
    await _persist();
  }

  Future<List<SyncQueueItem>> getPendingSyncItems() async {
    await _ensureInit();
    final queue = (_data['syncQueue'] as List<dynamic>? ?? []);
    return queue
        .map((e) => SyncQueueItem.fromJson(e as Map<String, dynamic>))
        .where((item) => !item.synced)
        .toList();
  }

  Future<void> markSynced(int id) async {
    await _updateSyncItem(
      id,
      (item) => item.copyWith(synced: true, syncedAt: DateTime.now()),
    );
  }

  Future<void> markSyncAttemptFailed(int id) async {
    await _updateSyncItem(
      id,
      (item) => item.copyWith(attemptCount: item.attemptCount + 1),
    );
  }

  Future<void> _updateSyncItem(
    int id,
    SyncQueueItem Function(SyncQueueItem item) update,
  ) async {
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
  }
}
