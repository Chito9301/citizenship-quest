import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
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

  Future<void> startQuiz({int questionCount = 10, bool shuffle = true}) async {
    state = state.copyWith(status: QuizStatus.loading, clearError: true);
    try {
      final allQuestions = await _ref.read(quizQuestionsProvider.future);
      final pool = [...allQuestions];
      if (shuffle) pool.shuffle(Random());
      final selected = pool.take(questionCount).toList();

      state = QuizState(
        status: QuizStatus.inProgress,
        questions: selected,
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
    state = state.copyWith(
      status: QuizStatus.answered,
      selectedOptionIndex: optionIndex,
      score: isCorrect ? state.score + pointsPerCorrectAnswer : state.score,
      correctAnswers: isCorrect ? state.correctAnswers + 1 : state.correctAnswers,
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

  void skipQuestion() {
    if (state.skipUsed || state.hasAnswered) return;
    state = state.copyWith(skipUsed: true);
    goToNextQuestion();
  }

  void goToNextQuestion() {
    if (state.isLastQuestion) {
      state = state.copyWith(status: QuizStatus.finished);
      _persistResults();
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
    final storageService = _ref.read(localStorageServiceProvider);
    final syncService = _ref.read(syncServiceProvider);

    final current = await storageService.getOrCreateProgress();
    final updated = current.copyWith(
      totalScore: current.totalScore + state.score,
      totalQuizzesPlayed: current.totalQuizzesPlayed + 1,
      totalCorrectAnswers: current.totalCorrectAnswers + state.correctAnswers,
      totalQuestionsAnswered:
          current.totalQuestionsAnswered + state.totalQuestions,
      lastPlayedAt: DateTime.now(),
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

  void reset() {
    state = const QuizState();
  }
}

final quizControllerProvider =
    StateNotifierProvider<QuizController, QuizState>((ref) {
  return QuizController(ref);
});
