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

  /// Registro de qué preguntas (por índice) se respondieron
  /// correctamente. No participa en el cálculo de score/racha (eso
  /// sigue igual); solo se usa al terminar la partida para desglosar
  /// el desempeño por categoría en la pantalla Home.
  final Map<int, bool> answeredCorrectByIndex;

  /// Marca de tiempo de inicio de la partida (para calcular tiempo
  /// promedio por pregunta en la pantalla de resultados).
  final DateTime? startedAt;

  /// Marca de tiempo de fin de partida. Se fija una sola vez al
  /// terminar, para que el tiempo mostrado en resultados no siga
  /// corriendo mientras el usuario mira la pantalla.
  final DateTime? finishedAt;

  /// Puntaje de la partida anterior (leído de UserProgress justo antes
  /// de guardar esta), para poder mostrar la comparación en la
  /// pantalla de resultados. `null` = esta fue la primera partida.
  final int? previousSessionScore;

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
    this.answeredCorrectByIndex = const {},
    this.startedAt,
    this.finishedAt,
    this.previousSessionScore,
    this.errorMessage,
  });

  QuizQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get totalQuestions => questions.length;

  bool get isLastQuestion => currentIndex == questions.length - 1;

  bool get hasAnswered => selectedOptionIndex != null;

  /// Segundos transcurridos desde que empezó la partida. Si ya
  /// terminó, se congela en el momento en que terminó; si sigue en
  /// curso, se calcula contra el reloj actual.
  int get elapsedSeconds {
    if (startedAt == null) return 0;
    final end = finishedAt ?? DateTime.now();
    return end.difference(startedAt!).inSeconds;
  }

  double get avgSecondsPerQuestion {
    if (totalQuestions == 0) return 0;
    return elapsedSeconds / totalQuestions;
  }

  /// Preguntas que se respondieron incorrectamente, en el mismo orden
  /// en que aparecieron. Las preguntas saltadas con "Skip" no cuentan
  /// como falladas (no se respondieron).
  List<QuizQuestion> get failedQuestions {
    return [
      for (var i = 0; i < questions.length; i++)
        if (answeredCorrectByIndex[i] == false) questions[i],
    ];
  }

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
    Map<int, bool>? answeredCorrectByIndex,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? previousSessionScore,
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
      answeredCorrectByIndex: answeredCorrectByIndex ?? this.answeredCorrectByIndex,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      previousSessionScore: previousSessionScore ?? this.previousSessionScore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
