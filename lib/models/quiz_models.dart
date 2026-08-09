import 'dart:math';

/// Tamaño del banco OFICIAL de preguntas de USCIS (versión 2008, la que
/// usa el examen real). El progreso de "preguntas dominadas" se mide
/// contra este número fijo, NO contra `assets/data/preguntas.json`.
///
/// IMPORTANTE: a día de hoy el banco local en preguntas.json tiene
/// menos de 100 preguntas transcritas (ver conteo real en el propio
/// archivo). Eso significa que "dominadas" nunca podrá llegar a 100/100
/// hasta que se complete la transcripción del banco oficial completo.
/// Se prioriza mostrar el denominador correcto (la meta real del
/// examen) antes que un número que "cierre bonito" pero sea engañoso
/// sobre cuánto le falta al usuario para el examen real.
const int officialUscisQuestionBankSize = 100;

/// ---------------------------------------------------------------------
/// Modelos "planos" que representan las preguntas cargadas desde
/// assets/data/preguntas.json. Viven solo en memoria durante la partida.
/// ---------------------------------------------------------------------

class QuizOption {
  final String textEn;
  final String textEs;

  const QuizOption({required this.textEn, required this.textEs});

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      textEn: json['text_en'] as String? ?? '',
      textEs: json['text_es'] as String? ?? '',
    );
  }

  String textFor(String languageCode) {
    return languageCode == 'es' ? textEs : textEn;
  }
}

class QuizQuestion {
  final String id;
  final String category;
  final String difficulty;
  final String questionEn;
  final String questionEs;
  final List<QuizOption> options;
  final int correctIndex;
  final String explanationEn;
  final String explanationEs;

  const QuizQuestion({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.questionEn,
    required this.questionEs,
    required this.options,
    required this.correctIndex,
    required this.explanationEn,
    required this.explanationEs,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List<dynamic>? ?? [])
        .map((e) => QuizOption.fromJson(e as Map<String, dynamic>))
        .toList();
    return QuizQuestion(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      difficulty: json['difficulty'] as String? ?? 'easy',
      questionEn: json['question_en'] as String? ?? '',
      questionEs: json['question_es'] as String? ?? '',
      options: rawOptions,
      correctIndex: json['correct_index'] as int? ?? 0,
      explanationEn: json['explanation_en'] as String? ?? '',
      explanationEs: json['explanation_es'] as String? ?? '',
    );
  }

  String questionFor(String languageCode) {
    return languageCode == 'es' ? questionEs : questionEn;
  }

  String explanationFor(String languageCode) {
    return languageCode == 'es' ? explanationEs : explanationEn;
  }

  /// Devuelve una copia de esta pregunta con el ORDEN de las opciones
  /// mezclado y `correctIndex` recalculado para seguir apuntando a la
  /// respuesta correcta en su nueva posición.
  ///
  /// En `assets/data/preguntas.json` la respuesta correcta siempre está
  /// en la posición 0 (es más fácil de escribir/mantener así), así que
  /// SIN este paso la opción correcta aparecería siempre primero en la
  /// UI. Se aplica una vez por pregunta al armar cada partida (ver
  /// QuizController.startQuiz), no en cada rebuild, para que el orden
  /// no cambie mientras el usuario está respondiendo.
  QuizQuestion shuffled([Random? random]) {
    final rnd = random ?? Random();
    final order = List<int>.generate(options.length, (i) => i)..shuffle(rnd);
    final reorderedOptions = [for (final originalIndex in order) options[originalIndex]];
    final newCorrectIndex = order.indexOf(correctIndex);

    return QuizQuestion(
      id: id,
      category: category,
      difficulty: difficulty,
      questionEn: questionEn,
      questionEs: questionEs,
      options: reorderedOptions,
      correctIndex: newCorrectIndex,
      explanationEn: explanationEn,
      explanationEs: explanationEs,
    );
  }
}

/// ---------------------------------------------------------------------
/// Desempeño por categoría (Gobierno, Historia, Educación Cívica...).
/// Se usa solo para mostrar el porcentaje por categoría en Home; no
/// afecta el puntaje ni ninguna regla del quiz.
/// ---------------------------------------------------------------------

class CategoryStat {
  final int correct;
  final int total;

  const CategoryStat({this.correct = 0, this.total = 0});

  double get accuracy => total == 0 ? 0 : correct / total;

  CategoryStat copyWith({int? correct, int? total}) {
    return CategoryStat(
      correct: correct ?? this.correct,
      total: total ?? this.total,
    );
  }

  Map<String, dynamic> toJson() => {'correct': correct, 'total': total};

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      correct: json['correct'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }
}

/// ---------------------------------------------------------------------
/// Progreso del usuario. Antes era una colección de Isar; ahora es una
/// clase inmutable de Dart puro, serializada a JSON a mano por
/// LocalStorageService. No requiere build_runner ni generación de
/// código.
/// ---------------------------------------------------------------------

class UserProgress {
  final String profileKey;
  final int totalScore;
  final int totalQuizzesPlayed;
  final int totalCorrectAnswers;
  final int totalQuestionsAnswered;
  final int currentStreakDays;
  final int longestStreakDays;
  final DateTime? lastPlayedAt;
  final List<String> unlockedBadgeIds;
  final Map<String, CategoryStat> categoryStats;

  /// Puntaje de la última partida completada (no acumulado). Se usa
  /// solo para mostrar "+N respecto a tu sesión anterior" en la
  /// pantalla de resultados; no afecta totalScore ni ninguna regla.
  final int? lastSessionScore;

  /// Segundos de estudio acumulados (suma de la duración de cada
  /// partida). Solo para la pantalla de Estadísticas.
  final int totalStudySeconds;

  /// Fechas (formato 'yyyy-MM-dd', hora UTC) en las que se completó al
  /// menos una partida. Se usa para el calendario de actividad de los
  /// últimos 7 días. Se limita a las últimas 30 entradas para que el
  /// archivo JSON no crezca indefinidamente.
  final List<String> activityDates;

  const UserProgress({
    this.profileKey = 'local_profile',
    this.totalScore = 0,
    this.totalQuizzesPlayed = 0,
    this.totalCorrectAnswers = 0,
    this.totalQuestionsAnswered = 0,
    this.currentStreakDays = 0,
    this.longestStreakDays = 0,
    this.lastPlayedAt,
    this.unlockedBadgeIds = const [],
    this.categoryStats = const {},
    this.lastSessionScore,
    this.totalStudySeconds = 0,
    this.activityDates = const [],
  });

  double get accuracy {
    if (totalQuestionsAnswered == 0) return 0;
    return totalCorrectAnswers / totalQuestionsAnswered;
  }

  UserProgress copyWith({
    String? profileKey,
    int? totalScore,
    int? totalQuizzesPlayed,
    int? totalCorrectAnswers,
    int? totalQuestionsAnswered,
    int? currentStreakDays,
    int? longestStreakDays,
    DateTime? lastPlayedAt,
    List<String>? unlockedBadgeIds,
    Map<String, CategoryStat>? categoryStats,
    int? lastSessionScore,
    bool clearLastSessionScore = false,
    int? totalStudySeconds,
    List<String>? activityDates,
  }) {
    return UserProgress(
      profileKey: profileKey ?? this.profileKey,
      totalScore: totalScore ?? this.totalScore,
      totalQuizzesPlayed: totalQuizzesPlayed ?? this.totalQuizzesPlayed,
      totalCorrectAnswers: totalCorrectAnswers ?? this.totalCorrectAnswers,
      totalQuestionsAnswered:
          totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      longestStreakDays: longestStreakDays ?? this.longestStreakDays,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      unlockedBadgeIds: unlockedBadgeIds ?? this.unlockedBadgeIds,
      categoryStats: categoryStats ?? this.categoryStats,
      lastSessionScore: clearLastSessionScore
          ? null
          : (lastSessionScore ?? this.lastSessionScore),
      totalStudySeconds: totalStudySeconds ?? this.totalStudySeconds,
      activityDates: activityDates ?? this.activityDates,
    );
  }

  /// Categoría con mejor precisión (mínimo 1 pregunta respondida).
  /// `null` si todavía no hay datos por categoría.
  String? get strongestCategory => _extremeCategory(strongest: true);

  /// Categoría con peor precisión (mínimo 1 pregunta respondida).
  String? get weakestCategory => _extremeCategory(strongest: false);

  String? _extremeCategory({required bool strongest}) {
    String? result;
    double? bestValue;
    for (final entry in categoryStats.entries) {
      if (entry.value.total == 0) continue;
      final value = entry.value.accuracy;
      final isBetter = bestValue == null ||
          (strongest ? value > bestValue : value < bestValue);
      if (isBetter) {
        bestValue = value;
        result = entry.key;
      }
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
        'profileKey': profileKey,
        'totalScore': totalScore,
        'totalQuizzesPlayed': totalQuizzesPlayed,
        'totalCorrectAnswers': totalCorrectAnswers,
        'totalQuestionsAnswered': totalQuestionsAnswered,
        'currentStreakDays': currentStreakDays,
        'longestStreakDays': longestStreakDays,
        'lastPlayedAt': lastPlayedAt?.toIso8601String(),
        'unlockedBadgeIds': unlockedBadgeIds,
        'categoryStats': categoryStats.map((k, v) => MapEntry(k, v.toJson())),
        'lastSessionScore': lastSessionScore,
        'totalStudySeconds': totalStudySeconds,
        'activityDates': activityDates,
      };

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final rawCategoryStats = json['categoryStats'] as Map<String, dynamic>?;
    return UserProgress(
      profileKey: json['profileKey'] as String? ?? 'local_profile',
      totalScore: json['totalScore'] as int? ?? 0,
      totalQuizzesPlayed: json['totalQuizzesPlayed'] as int? ?? 0,
      totalCorrectAnswers: json['totalCorrectAnswers'] as int? ?? 0,
      totalQuestionsAnswered: json['totalQuestionsAnswered'] as int? ?? 0,
      currentStreakDays: json['currentStreakDays'] as int? ?? 0,
      longestStreakDays: json['longestStreakDays'] as int? ?? 0,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.tryParse(json['lastPlayedAt'] as String)
          : null,
      unlockedBadgeIds: (json['unlockedBadgeIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      categoryStats: rawCategoryStats == null
          ? const {}
          : rawCategoryStats.map(
              (k, v) => MapEntry(k, CategoryStat.fromJson(v as Map<String, dynamic>)),
            ),
      lastSessionScore: json['lastSessionScore'] as int?,
      totalStudySeconds: json['totalStudySeconds'] as int? ?? 0,
      activityDates: (json['activityDates'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

/// ---------------------------------------------------------------------
/// Cola de sincronización. También pasó de colección de Isar a clase
/// inmutable de Dart puro con toJson/fromJson manuales.
/// ---------------------------------------------------------------------

enum SyncOperationType {
  quizCompleted,
  profileUpdated,
}

class SyncQueueItem {
  final int id;
  final SyncOperationType operationType;
  final String payloadJson;
  final DateTime createdAt;
  final bool synced;
  final DateTime? syncedAt;
  final int attemptCount;

  const SyncQueueItem({
    this.id = 0,
    this.operationType = SyncOperationType.quizCompleted,
    required this.payloadJson,
    required this.createdAt,
    this.synced = false,
    this.syncedAt,
    this.attemptCount = 0,
  });

  SyncQueueItem copyWith({
    int? id,
    SyncOperationType? operationType,
    String? payloadJson,
    DateTime? createdAt,
    bool? synced,
    DateTime? syncedAt,
    int? attemptCount,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      syncedAt: syncedAt ?? this.syncedAt,
      attemptCount: attemptCount ?? this.attemptCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'operationType': operationType.name,
        'payloadJson': payloadJson,
        'createdAt': createdAt.toIso8601String(),
        'synced': synced,
        'syncedAt': syncedAt?.toIso8601String(),
        'attemptCount': attemptCount,
      };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] as int? ?? 0,
      operationType: SyncOperationType.values.firstWhere(
        (e) => e.name == json['operationType'],
        orElse: () => SyncOperationType.quizCompleted,
      ),
      payloadJson: json['payloadJson'] as String? ?? '{}',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      synced: json['synced'] as bool? ?? false,
      syncedAt: json['syncedAt'] != null
          ? DateTime.tryParse(json['syncedAt'] as String)
          : null,
      attemptCount: json['attemptCount'] as int? ?? 0,
    );
  }
}
