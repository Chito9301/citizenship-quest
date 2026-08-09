/// Catálogo estático de insignias. Los ids son estables porque se
/// persisten en UserProgress.unlockedBadgeIds — no renombrar un id ya
/// publicado, o los usuarios "pierden" esa insignia visualmente
/// (seguiría en la lista pero sin match en el catálogo).
class BadgeDef {
  final String id;
  final String titleEn;
  final String titleEs;
  final String descriptionEn;
  final String descriptionEs;
  final String icon;

  const BadgeDef({
    required this.id,
    required this.titleEn,
    required this.titleEs,
    required this.descriptionEn,
    required this.descriptionEs,
    required this.icon,
  });

  String titleFor(String languageCode) => languageCode == 'es' ? titleEs : titleEn;
  String descriptionFor(String languageCode) => languageCode == 'es' ? descriptionEs : descriptionEn;
}

class BadgeCatalog {
  BadgeCatalog._();

  static const List<BadgeDef> all = [
    BadgeDef(
      id: 'first_quiz',
      titleEn: 'First session',
      titleEs: 'Primera sesión',
      descriptionEn: 'Complete your first quiz.',
      descriptionEs: 'Completa tu primer quiz.',
      icon: '🎓',
    ),
    BadgeDef(
      id: 'streak_3',
      titleEn: 'Getting consistent',
      titleEs: 'Constancia inicial',
      descriptionEn: '3 days in a row.',
      descriptionEs: '3 días consecutivos.',
      icon: '🔥',
    ),
    BadgeDef(
      id: 'streak_7',
      titleEn: 'Citizen discipline',
      titleEs: 'Disciplina ciudadana',
      descriptionEn: '7 days in a row.',
      descriptionEs: '7 días consecutivos.',
      icon: '🏅',
    ),
    BadgeDef(
      id: 'perfect_quiz',
      titleEn: 'Perfection',
      titleEs: 'Perfección',
      descriptionEn: 'Answer every question correctly in a session.',
      descriptionEs: 'Responde todas las preguntas correctamente en una sesión.',
      icon: '💯',
    ),
    BadgeDef(
      id: 'history_master',
      titleEn: 'History master',
      titleEs: 'Dominio de Historia',
      descriptionEn: '100% accuracy in the History category.',
      descriptionEs: '100% de precisión en la categoría Historia.',
      icon: '📜',
    ),
    BadgeDef(
      id: 'government_master',
      titleEn: 'Government master',
      titleEs: 'Dominio de Gobierno',
      descriptionEn: '100% accuracy in the Government category.',
      descriptionEs: '100% de precisión en la categoría Gobierno.',
      icon: '🏛️',
    ),
  ];

  static BadgeDef? byId(String id) {
    for (final badge in all) {
      if (badge.id == id) return badge;
    }
    return null;
  }
}
