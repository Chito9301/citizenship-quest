import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/quiz_models.dart';
import '../../profile/providers/profile_provider.dart';

const int _minQuestionsForCategoryMastery = 5;
const int _minQuestionsForPerfectBadge = 5;

/// Evalúa qué insignias nuevas se ganaron con esta partida.
///
/// Es una función pura (sin providers, sin IO) a propósito: así se
/// puede testear con datos de ejemplo sin levantar Riverpod ni
/// storage. Recibe el UserProgress YA actualizado con los stats de
/// esta partida (puntos, racha, categoryStats) pero ANTES de fusionar
/// las insignias nuevas en unlockedBadgeIds.
List<String> evaluateNewlyUnlockedBadges({
  required UserProgress updatedProgress,
  required List<String> alreadyUnlockedIds,
  required int sessionCorrectAnswers,
  required int sessionTotalQuestions,
}) {
  final newlyUnlocked = <String>[];

  void unlock(String id) {
    if (!alreadyUnlockedIds.contains(id) && !newlyUnlocked.contains(id)) {
      newlyUnlocked.add(id);
    }
  }

  if (updatedProgress.totalQuizzesPlayed >= 1) {
    unlock('first_quiz');
  }
  if (updatedProgress.currentStreakDays >= 3) {
    unlock('streak_3');
  }
  if (updatedProgress.currentStreakDays >= 7) {
    unlock('streak_7');
  }
  if (sessionTotalQuestions >= _minQuestionsForPerfectBadge &&
      sessionCorrectAnswers == sessionTotalQuestions) {
    unlock('perfect_quiz');
  }

  final history = updatedProgress.categoryStats['american_history'];
  if (history != null &&
      history.total >= _minQuestionsForCategoryMastery &&
      history.accuracy >= 1.0) {
    unlock('history_master');
  }

  final government = updatedProgress.categoryStats['american_government'];
  if (government != null &&
      government.total >= _minQuestionsForCategoryMastery &&
      government.accuracy >= 1.0) {
    unlock('government_master');
  }

  return newlyUnlocked;
}

/// Expone la lista de insignias desbloqueadas del usuario actual,
/// reactiva a UserProgress (se actualiza sola cuando se gana una
/// nueva). Usado por ProfileScreen.
final unlockedBadgeIdsProvider = Provider<List<String>>((ref) {
  final progressAsync = ref.watch(userProgressStreamProvider);
  return progressAsync.valueOrNull?.unlockedBadgeIds ?? const [];
});
