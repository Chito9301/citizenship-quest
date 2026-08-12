import 'dart:math';

import '../../../models/question_progress.dart';
import '../../../models/quiz_models.dart';

/// Arma una sesión de práctica priorizando preguntas que el usuario
/// todavía no domina, tal como pide el objetivo pedagógico de Sprint 6:
/// "recordar la pregunta, aumentar su prioridad, y volver a mostrarla
/// hasta que la responda correctamente varias veces seguidas".
///
/// Sprint 6.1: corrige el bug donde una pregunta recién fallada podía
/// no reaparecer en la siguiente sesión. Antes, "aprendiendo" era un
/// solo grupo limitado a un tope fijo del 60% de la sesión y ordenado
/// por cantidad total de fallos histórica — así que una pregunta con
/// pocos fallos acumulados (aunque fuera la fallada más recientemente)
/// podía quedar afuera del tope si había otras con más fallos viejos.
///
/// Ahora "aprendiendo" se separa en 3 niveles de prioridad según
/// `consecutiveCorrect` (aciertos seguidos desde el último fallo), y
/// cada nivel se llena ANTES de aplicar cualquier límite, en este orden:
///
/// 1. Prioridad OBLIGATORIA — `consecutiveCorrect == 0`: falladas y
///    todavía no recuperadas ni una vez. Se toman todas las que entren
///    en la sesión, sin tope de porcentaje. Dentro del grupo, la
///    fallada más recientemente va primero.
/// 2. Prioridad ALTA — `consecutiveCorrect == 1`: acertada una vez
///    después de fallar, pero todavía no se considera recuperada.
/// 3. Prioridad MEDIA — `consecutiveCorrect == 2`: a un acierto más de
///    dominarse.
/// 4. Nuevas — sin entrada de progreso todavía, rellenan el espacio
///    que quede.
/// 5. Dominadas (`consecutiveCorrect >= 3`) — relleno final al azar
///    para repaso ocasional, solo si sobra espacio.
List<QuizQuestion> selectPrioritizedSession({
  required List<QuizQuestion> allQuestions,
  required Map<String, QuestionProgress> progress,
  int sessionSize = 10,
  Random? random,
}) {
  final rnd = random ?? Random();

  final mandatory = <QuizQuestion>[]; // consecutiveCorrect == 0
  final highPriority = <QuizQuestion>[]; // consecutiveCorrect == 1
  final mediumPriority = <QuizQuestion>[]; // consecutiveCorrect == 2
  final neverSeen = <QuizQuestion>[];
  final mastered = <QuizQuestion>[]; // consecutiveCorrect >= 3

  for (final question in allQuestions) {
    final p = progress[question.id];
    if (p == null) {
      neverSeen.add(question);
    } else if (p.isMastered) {
      mastered.add(question);
    } else if (p.consecutiveCorrect == 0) {
      mandatory.add(question);
    } else if (p.consecutiveCorrect == 1) {
      highPriority.add(question);
    } else {
      mediumPriority.add(question);
    }
  }

  // Dentro de cada nivel, la vista/fallada más recientemente va
  // primero. Esto es lo que garantiza que una pregunta fallada en la
  // sesión anterior (su lastSeenAt queda en "ahora mismo") quede al
  // frente de la cola de prioridad obligatoria para la sesión
  // siguiente, en vez de competir en igualdad contra fallos viejos.
  int byMostRecentFirst(QuizQuestion a, QuizQuestion b) =>
      progress[b.id]!.lastSeenAt.compareTo(progress[a.id]!.lastSeenAt);

  mandatory.sort(byMostRecentFirst);
  highPriority.sort(byMostRecentFirst);
  mediumPriority.sort(byMostRecentFirst);
  neverSeen.shuffle(rnd);
  mastered.shuffle(rnd);

  final selected = <QuizQuestion>[];
  final usedIds = <String>{};

  void take(List<QuizQuestion> source, int maxCount) {
    var taken = 0;
    for (final q in source) {
      if (selected.length >= sessionSize || taken >= maxCount) return;
      if (usedIds.contains(q.id)) continue;
      selected.add(q);
      usedIds.add(q.id);
      taken++;
    }
  }

  // Sin tope de porcentaje: cada nivel se llena por completo (hasta el
  // tamaño de la sesión) ANTES de pasar al siguiente. "mandatory" es
  // literalmente obligatorio salvo que ya no queden cupos.
  take(mandatory, sessionSize);
  take(highPriority, sessionSize - selected.length);
  take(mediumPriority, sessionSize - selected.length);

  // Con lo que sobre de espacio, entra contenido nuevo...
  take(neverSeen, sessionSize - selected.length);

  // ...y si todavía sobra (banco chico o casi todo dominado), relleno
  // al azar con preguntas ya dominadas para repaso ocasional.
  if (selected.length < sessionSize) {
    take(mastered, sessionSize - selected.length);
  }

  selected.shuffle(rnd);
  return selected.take(sessionSize).toList();
}
