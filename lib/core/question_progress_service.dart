import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';

import '../models/question_progress.dart';

/// Persistencia del progreso por pregunta (Sprint 6: repaso por
/// errores). Archivo independiente ("user_question_progress.json"),
/// separado a propósito de "citizenship_quest_data.json" (Sprint 5:
/// puntaje, racha, insignias) para no tocar ni arriesgar ese archivo.
///
/// Reutiliza exactamente las mismas garantías que LocalStorageService:
/// escritura atómica (.tmp + rename), limpieza de temporales huérfanos
/// al iniciar, recuperación ante JSON corrupto, y escrituras
/// serializadas con un lock en memoria.
class QuestionProgressService {
  QuestionProgressService._();

  static final QuestionProgressService instance = QuestionProgressService._();

  /// Solo para tests unitarios: evita depender de path_provider.
  @visibleForTesting
  factory QuestionProgressService.withFile(File file) {
    final service = QuestionProgressService._();
    service._file = file;
    return service;
  }

  static const String _fileName = 'user_question_progress.json';

  File? _file;
  Map<String, dynamic> _data = _defaultData();
  bool _initialized = false;
  Future<void>? _initFuture;
  Future<void> _writeLock = Future.value();

  final StreamController<int> _masteredCountController =
      StreamController<int>.broadcast();

  bool get isInitialized => _initialized;

  static Map<String, dynamic> _defaultData() => {
        'version': 1,
        'progress': <String, dynamic>{},
      };

  Future<void> init() {
    return _initFuture ??= _performInit();
  }

  Future<void> _performInit() async {
    if (_file == null) {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/$_fileName');
    }

    final orphanedTemp = File('${_file!.path}.tmp');
    if (await orphanedTemp.exists()) {
      try {
        await orphanedTemp.delete();
      } catch (_) {
        // Se sobrescribirá en el próximo _persist() de todas formas.
      }
    }

    if (await _file!.exists()) {
      try {
        final raw = await _file!.readAsString();
        _data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
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
    await _masteredCountController.close();
    _initialized = false;
    _initFuture = null;
  }

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

  Map<String, QuestionProgress> _readAll() {
    final raw = _data['progress'] as Map<String, dynamic>? ?? {};
    return raw.map(
      (id, value) => MapEntry(id, QuestionProgress.fromJson(id, value as Map<String, dynamic>)),
    );
  }

  /// Todo el progreso guardado, indexado por id de pregunta (ej. "q001").
  /// Una pregunta sin entrada aquí nunca fue vista.
  Future<Map<String, QuestionProgress>> getAllProgress() async {
    await _ensureInit();
    return _synchronized(() async => _readAll());
  }

  /// Aplica los resultados de una partida completa en una sola
  /// escritura atómica (más seguro y más eficiente que una escritura
  /// por pregunta).
  Future<void> recordSessionResults(
    Map<String, bool> resultsByQuestionId,
    DateTime answeredAt,
  ) {
    return _synchronized(() async {
      await _ensureInit();
      final current = _readAll();

      resultsByQuestionId.forEach((questionId, wasCorrect) {
        final existing = current[questionId] ??
            QuestionProgress(questionId: questionId, lastSeenAt: answeredAt);
        current[questionId] = existing.recordAnswer(
          wasCorrect: wasCorrect,
          answeredAt: answeredAt,
        );
      });

      _data['progress'] = current.map((id, p) => MapEntry(id, p.toJson()));
      await _persist();

      _masteredCountController.add(
        current.values.where((p) => p.isMastered).length,
      );
    });
  }

  /// Cantidad de preguntas "dominadas" ahora mismo (ver
  /// QuestionProgress.isMastered): aciertos consecutivos >= umbral.
  Future<int> masteredCount() async {
    final all = await getAllProgress();
    return all.values.where((p) => p.isMastered).length;
  }

  /// Emite la cantidad de preguntas dominadas al inicio y cada vez que
  /// cambia (por ejemplo, al terminar una partida).
  Stream<int> watchMasteredCount() async* {
    yield await masteredCount();
    yield* _masteredCountController.stream;
  }
}
