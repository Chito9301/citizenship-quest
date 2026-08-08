import 'package:flutter_riverpod/flutter_riverpod.dart';

/// STUB deliberado: hoy no existe tracking por pregunta individual
/// (solo por categoría, ver UserProgress.categoryStats), así que no
/// hay forma honesta de saber "las 3 preguntas que más falla" todavía.
///
/// Este provider deja el punto de extensión listo: cuando se implemente
/// el tracking por pregunta, solo hay que reemplazar el cuerpo de este
/// provider por la consulta real — la tarjeta de Home
/// (smart_review_card.dart) no necesita cambiar.
class SmartReviewSuggestion {
  const SmartReviewSuggestion({required this.hasEnoughData, this.weakestCategory});

  final bool hasEnoughData;
  final String? weakestCategory;
}

final smartReviewProvider = Provider<SmartReviewSuggestion>((ref) {
  return const SmartReviewSuggestion(hasEnoughData: false);
});
