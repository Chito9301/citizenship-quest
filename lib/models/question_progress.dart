/// Progreso de UNA pregunta específica, para el sistema de repaso por
/// errores (Sprint 6). Vive en un archivo separado
/// (`user_question_progress.json`, ver QuestionProgressService) —
/// no toca `UserProgress` ni `citizenship_quest_data.json` del Sprint 5.
class QuestionProgress {
  /// Aciertos consecutivos necesarios para considerar una pregunta
  /// "dominada" y dejar de priorizarla. Cualquier fallo lo resetea a 0,
  /// así que llegar a este número exige acertarla varias veces seguidas,
  /// tal como pide el objetivo pedagógico.
  static const int masteryThreshold = 3;

  final String questionId;
  final int timesCorrect;
  final int timesIncorrect;
  final int consecutiveCorrect;
  final DateTime lastSeenAt;

  const QuestionProgress({
    required this.questionId,
    this.timesCorrect = 0,
    this.timesIncorrect = 0,
    this.consecutiveCorrect = 0,
    required this.lastSeenAt,
  });

  bool get isMastered => consecutiveCorrect >= masteryThreshold;

  /// Aplica el resultado de una respuesta y devuelve el progreso
  /// actualizado. Es la única fórmula de actualización del sistema —
  /// tanto la primera vez que se ve una pregunta como las siguientes
  /// pasan por acá.
  QuestionProgress recordAnswer({required bool wasCorrect, required DateTime answeredAt}) {
    return QuestionProgress(
      questionId: questionId,
      timesCorrect: timesCorrect + (wasCorrect ? 1 : 0),
      timesIncorrect: timesIncorrect + (wasCorrect ? 0 : 1),
      // La clave del sistema: un acierto suma sobre la racha anterior,
      // un fallo la rompe por completo.
      consecutiveCorrect: wasCorrect ? consecutiveCorrect + 1 : 0,
      lastSeenAt: answeredAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'timesCorrect': timesCorrect,
        'timesIncorrect': timesIncorrect,
        'consecutiveCorrect': consecutiveCorrect,
        'lastSeenAt': lastSeenAt.toIso8601String(),
      };

  factory QuestionProgress.fromJson(String questionId, Map<String, dynamic> json) {
    return QuestionProgress(
      questionId: questionId,
      timesCorrect: json['timesCorrect'] as int? ?? 0,
      timesIncorrect: json['timesIncorrect'] as int? ?? 0,
      consecutiveCorrect: json['consecutiveCorrect'] as int? ?? 0,
      lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
