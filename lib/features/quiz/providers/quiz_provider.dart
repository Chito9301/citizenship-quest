import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle, HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/local_storage_service.dart';
import '../../../core/question_progress_service.dart';
import '../../../models/quiz_models.dart';
import '../../../services/sync_service.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../logic/spaced_repetition_selector.dart';
import 'quiz_state.dart';

/// Provider global de acceso al almacenamiento local (usado por
/// múltiples features).
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService.instance;
});

/// Provider global del progreso por pregunta (Sprint 6: repaso por
/// errores). Archivo y ciclo de vida independientes de
/// localStorageServiceProvider.
final questionProgressServiceProvider = Provider<QuestionProgressService>((ref) {
  return QuestionProgressService.instance;
});

/// Cantidad de preguntas "dominadas" (aciertos consecutivos >= umbral),
/// reactiva: se actualiza sola al terminar cada partida. Reemplaza a la
/// aproximación anterior basada en `totalCorrectAnswers`.
final masteredQuestionsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(questionProgressServiceProvider).watchMasteredCount();
});

/// Provider global del servicio de sincronización.
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(storageService: ref.watch(localStorageServiceProvider));
});

/// Carga y parsea el banco USCIS 2008 (assets/data/preguntas_2008.json)
/// una sola vez. Sprint 7.5: el banco 2008 se separó a su propio
/// archivo (ver pubspec.yaml); este provider hoy solo conoce el 2008 —
/// todavía no elige entre bancos, eso queda para cuando exista
/// preguntas_2025.json.
final quizQuestionsProvider = FutureProvider<List<QuizQuestion>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/preguntas_2008.json');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final list = (decoded['questions'] as List<dynamic>? ?? [])
      .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
      .toList();
  return list;
});

const int pointsPerCorrectAnswer = 10;

class QuizController extends StateNotifier<QuizState> {
  QuizController(this._ref) : super(const QuizState());

  final Ref _ref;

  /// Guarda de idempotencia: aunque la UI llegara a permitir un doble
  /// toque en "Finalizar" (por ejemplo, mientras la navegación a la
  /// pantalla de resultados todavía no ocurrió), esto asegura que
  /// _persistResults() se ejecute como máximo una vez por partida.
  bool _resultsPersisted = false;

  Future<void> startQuiz({int questionCount = 10}) async {
    _resultsPersisted = false;
    state = state.copyWith(status: QuizStatus.loading, clearError: true);
    try {
      final allQuestions = await _ref.read(quizQuestionsProvider.future);
      final progressService = _ref.read(questionProgressServiceProvider);
      final progress = await progressService.getAllProgress();

      // Sprint 6: en vez de un shuffle simple, prioriza preguntas que
      // el usuario todavía no domina (ver spaced_repetition_selector.dart).
      final prioritized = selectPrioritizedSession(
        allQuestions: allQuestions,
        progress: progress,
        sessionSize: questionCount,
      );

      // .shuffled() reordena las 4 opciones de CADA pregunta (en el
      // JSON la correcta siempre está en la posición 0) y recalcula
      // correctIndex. Se hace una sola vez aquí, al armar la partida,
      // así el orden queda fijo mientras el usuario responde.
      final selected = prioritized.map((q) => q.shuffled()).toList();

      state = QuizState(
        status: QuizStatus.inProgress,
        questions: selected,
        startedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        status: QuizStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void selectAnswer(int optionIndex) {
    final question = state.currentQuestion;
    if (question == null || state.hasAnswered) return;

    final isCorrect = optionIndex == question.correctIndex;
    if (isCorrect) {
      // Feedback táctil sutil, no exagerado (tarea de pulido #6).
      HapticFeedback.lightImpact();
    }
    state = state.copyWith(
      status: QuizStatus.answered,
      selectedOptionIndex: optionIndex,
      score: isCorrect ? state.score + pointsPerCorrectAnswer : state.score,
      correctAnswers: isCorrect ? state.correctAnswers + 1 : state.correctAnswers,
      answeredCorrectByIndex: {
        ...state.answeredCorrectByIndex,
        state.currentIndex: isCorrect,
      },
      selectedOptionByIndex: {
        ...state.selectedOptionByIndex,
        state.currentIndex: optionIndex,
      },
    );
  }

  void useFiftyFifty() {
    final question = state.currentQuestion;
    if (question == null || state.fiftyFiftyUsed || state.hasAnswered) return;

    final wrongIndexes = List.generate(question.options.length, (i) => i)
        .where((i) => i != question.correctIndex)
        .toList()
      ..shuffle(Random());

    final toHide = wrongIndexes.take(2).toSet();

    state = state.copyWith(
      fiftyFiftyUsed: true,
      hiddenOptionIndexes: toHide,
    );
  }

  Future<void> skipQuestion() async {
    if (state.skipUsed || state.hasAnswered) return;
    state = state.copyWith(skipUsed: true);
    await goToNextQuestion();
  }

  /// Devuelve Future<void> (en vez de void) para que quien la llama
  /// -incluida la UI- pueda esperar a que el resultado quede guardado
  /// antes de navegar. Sigue siendo compatible como `VoidCallback` en
  /// los widgets (Dart descarta el valor de retorno en contexto void).
  Future<void> goToNextQuestion() async {
    // Guarda: si el quiz ya terminó, ignorar toques repetidos del botón
    // "Finalizar" (root cause del bug de contador duplicado: el botón
    // podía seguir tocable un instante después de terminar la partida).
    if (state.status == QuizStatus.finished) return;

    if (state.isLastQuestion) {
      state = state.copyWith(
        status: QuizStatus.finished,
        finishedAt: DateTime.now(),
      );
      await _persistResults();
      return;
    }

    state = state.copyWith(
      status: QuizStatus.inProgress,
      currentIndex: state.currentIndex + 1,
      clearSelectedOption: true,
      hiddenOptionIndexes: {},
    );
  }

  Future<void> _persistResults() async {
    // Segunda capa de la misma guarda: incluso si goToNextQuestion()
    // se llamara dos veces antes de que `state` terminara de
    // propagarse, esto evita persistir el resultado más de una vez.
    if (_resultsPersisted) return;
    _resultsPersisted = true;

    final storageService = _ref.read(localStorageServiceProvider);
    final syncService = _ref.read(syncServiceProvider);
    final progressService = _ref.read(questionProgressServiceProvider);

    final current = await storageService.getOrCreateProgress();
    final playedAt = DateTime.now().toUtc();

    // Se guarda en el propio QuizState (no solo en UserProgress) para
    // que la pantalla de resultados pueda leerlo directamente del
    // provider, sin tener que ir a buscar el UserProgress "de antes"
    // por su cuenta.
    state = state.copyWith(previousSessionScore: current.lastSessionScore);

    final updated = current.copyWith(
      totalScore: current.totalScore + state.score,
      totalQuizzesPlayed: current.totalQuizzesPlayed + 1,
      totalCorrectAnswers: current.totalCorrectAnswers + state.correctAnswers,
      totalQuestionsAnswered:
          current.totalQuestionsAnswered + state.totalQuestions,
      lastPlayedAt: playedAt,
      currentStreakDays: _computeStreak(
        previousStreak: current.currentStreakDays,
        lastPlayedAt: current.lastPlayedAt,
        playedAt: playedAt,
      ),
      longestStreakDays: max(
        current.longestStreakDays,
        _computeStreak(
          previousStreak: current.currentStreakDays,
          lastPlayedAt: current.lastPlayedAt,
          playedAt: playedAt,
        ),
      ),
      categoryStats: _mergeCategoryStats(current.categoryStats),
      lastSessionScore: state.score,
      totalStudySeconds: current.totalStudySeconds + state.elapsedSeconds,
      activityDates: _mergeActivityDates(current.activityDates, playedAt),
    );

    final newlyUnlocked = evaluateNewlyUnlockedBadges(
      updatedProgress: updated,
      alreadyUnlockedIds: current.unlockedBadgeIds,
      sessionCorrectAnswers: state.correctAnswers,
      sessionTotalQuestions: state.totalQuestions,
    );

    final finalProgress = newlyUnlocked.isEmpty
        ? updated
        : updated.copyWith(
            unlockedBadgeIds: [...current.unlockedBadgeIds, ...newlyUnlocked],
          );

    state = state.copyWith(newlyUnlockedBadgeIds: newlyUnlocked);

    await storageService.saveProgress(finalProgress);

    // Sprint 6: registra el acierto/fallo de CADA pregunta respondida
    // (no las salteadas con Skip) para el sistema de repaso por
    // errores. Es una escritura aparte, en su propio archivo, así que
    // una falla acá nunca puede corromper el progreso del Sprint 5.
    final questionResults = <String, bool>{
      for (final entry in state.answeredCorrectByIndex.entries)
        state.questions[entry.key].id: entry.value,
    };
    if (questionResults.isNotEmpty) {
      await progressService.recordSessionResults(questionResults, playedAt);
    }

    await syncService.enqueueQuizCompleted(
      score: state.score,
      correctAnswers: state.correctAnswers,
      totalQuestions: state.totalQuestions,
    );

    // Best-effort: intenta vaciar la cola inmediatamente.
    unawaited(syncService.processPendingQueue());
  }

  /// Agrega la fecha (UTC, 'yyyy-MM-dd') de esta partida a la lista de
  /// días con actividad, sin duplicar si ya se jugó hoy, y recortando
  /// a las últimas 30 entradas.
  List<String> _mergeActivityDates(List<String> previous, DateTime playedAt) {
    final today = _dateOnlyUtc(playedAt);
    final todayKey =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    if (previous.contains(todayKey)) return previous;

    final updated = [...previous, todayKey];
    if (updated.length > 30) {
      return updated.sublist(updated.length - 30);
    }
    return updated;
  }

  /// Suma los resultados de esta partida (por categoría) a las stats ya
  /// guardadas. Las preguntas saltadas con "Skip" no cuentan ni suman
  /// ni restan. No participa en score/racha/validación de respuestas.
  Map<String, CategoryStat> _mergeCategoryStats(
    Map<String, CategoryStat> previous,
  ) {
    final merged = Map<String, CategoryStat>.from(previous);

    for (var i = 0; i < state.questions.length; i++) {
      final wasAnswered = state.answeredCorrectByIndex.containsKey(i);
      if (!wasAnswered) continue;

      final category = state.questions[i].category;
      final wasCorrect = state.answeredCorrectByIndex[i]!;
      final existing = merged[category] ?? const CategoryStat();

      merged[category] = existing.copyWith(
        correct: existing.correct + (wasCorrect ? 1 : 0),
        total: existing.total + 1,
      );
    }

    return merged;
  }

  /// Racha basada en fechas reales en UTC (no en "sesiones jugadas"):
  /// - Primera partida de la app  -> racha = 1
  /// - Ya jugó hoy (misma fecha)  -> racha se mantiene igual (no sube
  ///   varias veces por jugar varias partidas el mismo día)
  /// - Jugó ayer y vuelve hoy     -> racha + 1
  /// - Pasó más de 1 día sin jugar -> racha se reinicia a 1
  static int _computeStreak({
    required int previousStreak,
    required DateTime? lastPlayedAt,
    required DateTime playedAt,
  }) {
    final today = _dateOnlyUtc(playedAt);

    if (lastPlayedAt == null) return 1;

    final lastPlayedDate = _dateOnlyUtc(lastPlayedAt);
    final yesterday = today.subtract(const Duration(days: 1));

    if (lastPlayedDate == today) return previousStreak == 0 ? 1 : previousStreak;
    if (lastPlayedDate == yesterday) return previousStreak + 1;
    return 1;
  }

  static DateTime _dateOnlyUtc(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  void reset() {
    _resultsPersisted = false;
    state = const QuizState();
  }
}

final quizControllerProvider =
    StateNotifierProvider<QuizController, QuizState>((ref) {
  return QuizController(ref);
});
