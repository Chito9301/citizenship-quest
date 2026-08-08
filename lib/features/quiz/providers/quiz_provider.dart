import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle, HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/local_storage_service.dart';
import '../../../models/quiz_models.dart';
import '../../../services/sync_service.dart';
import 'quiz_state.dart';

/// Provider global de acceso al almacenamiento local (usado por
/// múltiples features).
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService.instance;
});

/// Provider global del servicio de sincronización.
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(storageService: ref.watch(localStorageServiceProvider));
});

/// Carga y parsea assets/data/preguntas.json una sola vez.
final quizQuestionsProvider = FutureProvider<List<QuizQuestion>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/preguntas.json');
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

  Future<void> startQuiz({int questionCount = 10, bool shuffle = true}) async {
    _resultsPersisted = false;
    state = state.copyWith(status: QuizStatus.loading, clearError: true);
    try {
      final allQuestions = await _ref.read(quizQuestionsProvider.future);
      final pool = [...allQuestions];
      if (shuffle) pool.shuffle(Random());
      // .shuffled() reordena las 4 opciones de CADA pregunta (en el
      // JSON la correcta siempre está en la posición 0) y recalcula
      // correctIndex. Se hace una sola vez aquí, al armar la partida,
      // así el orden queda fijo mientras el usuario responde.
      final selected =
          pool.take(questionCount).map((q) => q.shuffled()).toList();

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
    );

    await storageService.saveProgress(updated);

    await syncService.enqueueQuizCompleted(
      score: state.score,
      correctAnswers: state.correctAnswers,
      totalQuestions: state.totalQuestions,
    );

    // Best-effort: intenta vaciar la cola inmediatamente.
    unawaited(syncService.processPendingQueue());
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
