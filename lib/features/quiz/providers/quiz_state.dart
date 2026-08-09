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

  /// Registro de QUÉ opción (índice) eligió el usuario en cada
  /// pregunta. Se usa solo para mostrar "tu respuesta" en "Revisar
  /// errores"; no participa en ningún cálculo de puntaje.
  final Map<int, int> selectedOptionByIndex;

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

  /// Ids de insignias ganadas recién en ESTA partida (para mostrar la
  /// celebración en la pantalla de resultados). No confundir con
  /// UserProgress.unlockedBadgeIds, que es el historial completo.
  final List<String> newlyUnlockedBadgeIds;

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
    this.selectedOptionByIndex = const {},
    this.startedAt,
    this.finishedAt,
    this.previousSessionScore,
    this.newlyUnlockedBadgeIds = const [],
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
  /// en que aparecieron, junto con la opción que el usuario eligió.
  /// Las preguntas saltadas con "Skip" no cuentan como falladas (no se
  /// respondieron, así que no hay "opción elegida" que mostrar).
  List<FailedQuestionResult> get failedQuestions {
    return [
      for (var i = 0; i < questions.length; i++)
        if (answeredCorrectByIndex[i] == false)
          FailedQuestionResult(
            question: questions[i],
            selectedOptionIndex: selectedOptionByIndex[i]!,
          ),
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
    Map<int, int>? selectedOptionByIndex,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? previousSessionScore,
    List<String>? newlyUnlockedBadgeIds,
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
      selectedOptionByIndex: selectedOptionByIndex ?? this.selectedOptionByIndex,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      previousSessionScore: previousSessionScore ?? this.previousSessionScore,
      newlyUnlockedBadgeIds: newlyUnlockedBadgeIds ?? this.newlyUnlockedBadgeIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Resultado de una pregunta fallada, listo para pintar en "Revisar
/// errores": la pregunta completa + qué opción eligió el usuario. La
/// respuesta correcta y la explicación se leen directamente de
/// `question` (question.correctIndex / question.explanationFor), que
/// vienen del JSON local — nunca se inventan.
@immutable
class FailedQuestionResult {
  const FailedQuestionResult({
    required this.question,
    required this.selectedOptionIndex,
  });

  final QuizQuestion question;
  final int selectedOptionIndex;

  QuizOption get selectedOption => question.options[selectedOptionIndex];
  QuizOption get correctOption => question.options[question.correctIndex];
}
