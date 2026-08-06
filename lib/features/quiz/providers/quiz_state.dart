import 'package:flutter/foundation.dart';

import '../../../models/quiz_models.dart';

enum QuizStatus {
  initial,
  loading,
  inProgress,
  answered,
  finished,
  error,
}

@immutable
class QuizState {
  final QuizStatus status;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final int score;
  final int correctAnswers;

  /// Índice de la opción elegida para la pregunta actual (null = sin
  /// responder todavía).
  final int? selectedOptionIndex;

  /// Índices de opciones ocultas por el power-up 50/50 para la pregunta
  /// actual.
  final Set<int> hiddenOptionIndexes;

  final bool fiftyFiftyUsed;
  final bool skipUsed;

  final String? errorMessage;

  const QuizState({
    this.status = QuizStatus.initial,
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.correctAnswers = 0,
    this.selectedOptionIndex,
    this.hiddenOptionIndexes = const {},
    this.fiftyFiftyUsed = false,
    this.skipUsed = false,
    this.errorMessage,
  });

  QuizQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get totalQuestions => questions.length;

  bool get isLastQuestion => currentIndex == questions.length - 1;

  bool get hasAnswered => selectedOptionIndex != null;

  QuizState copyWith({
    QuizStatus? status,
    List<QuizQuestion>? questions,
    int? currentIndex,
    int? score,
    int? correctAnswers,
    int? selectedOptionIndex,
    bool clearSelectedOption = false,
    Set<int>? hiddenOptionIndexes,
    bool? fiftyFiftyUsed,
    bool? skipUsed,
    String? errorMessage,
    bool clearError = false,
  }) {
    return QuizState(
      status: status ?? this.status,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      selectedOptionIndex: clearSelectedOption
          ? null
          : (selectedOptionIndex ?? this.selectedOptionIndex),
      hiddenOptionIndexes: hiddenOptionIndexes ?? this.hiddenOptionIndexes,
      fiftyFiftyUsed: fiftyFiftyUsed ?? this.fiftyFiftyUsed,
      skipUsed: skipUsed ?? this.skipUsed,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
