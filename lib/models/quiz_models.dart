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
    );
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
      };

  factory UserProgress.fromJson(Map<String, dynamic> json) {
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
