/// Representa qué versión oficial del examen de ciudadanía USCIS está
/// en juego. Sprint 7.6: preparación para poder soportar dos bancos de
/// preguntas en simultáneo (2008 y 2025) sin mezclarlos.
///
/// Todavía NO se usa en ningún flujo real (no hay pantalla de
/// selección, no existe el banco 2025) — es solo la representación
/// reutilizable que van a consumir esos sprints futuros.
enum ExamVersion {
  year2008(
    label: '2008',
    questionCount: 100,
    assetPath: 'assets/data/preguntas_2008.json',
  ),
  year2025(
    label: '2025',
    questionCount: 128,
    assetPath: 'assets/data/preguntas_2025.json',
  );

  const ExamVersion({
    required this.label,
    required this.questionCount,
    required this.assetPath,
  });

  /// Etiqueta corta ('2008' / '2025'). Coincide a propósito, carácter
  /// por carácter, con el valor que ya guarda cada pregunta en
  /// `QuizQuestion.examVersion` (ver quiz_models.dart, Sprint 7.1/7.2)
  /// para poder ir y volver entre ambas representaciones sin mapeos
  /// adicionales.
  final String label;

  /// Cantidad oficial de preguntas de ese banco. Es un dato de
  /// referencia (por ejemplo, para un futuro denominador de
  /// "dominadas" calculado por versión); no valida el contenido real
  /// del JSON, que puede tener menos preguntas mientras se completa.
  final int questionCount;

  /// Ruta del asset que contiene ese banco. La ruta del 2025 se
  /// declara acá para dejar el mapeo completo desde ya, aunque ese
  /// archivo todavía no existe ni está declarado en pubspec.yaml.
  final String assetPath;

  /// Convierte el string persistido en `QuizQuestion.examVersion`
  /// (o cualquier otro string equivalente) a su `ExamVersion`.
  /// Cualquier valor nulo o desconocido cae a 2008 a propósito: es el
  /// único banco que existe hoy, así que es el fallback seguro.
  static ExamVersion fromLabel(String? label) {
    return ExamVersion.values.firstWhere(
      (version) => version.label == label,
      orElse: () => ExamVersion.year2008,
    );
  }
}
