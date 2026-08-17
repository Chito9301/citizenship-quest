import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../models/exam_version.dart';

/// Pantalla inicial de selección de examen (Sprint 7.8): 2008 o 2025.
///
/// Igual que OnboardingScreen, esta pantalla NO persiste nada por su
/// cuenta — solo notifica la elección vía [onSelected]. Quien la usa
/// (ver app_router.dart) es responsable de guardarla con
/// `LocalStorageService.setSelectedExamVersion()` y de actualizar el
/// provider que decide si volver a mostrarla. Esto la mantiene testeable
/// de forma aislada, sin depender de storage real.
///
/// El banco 2025 todavía no existe como contenido: tocar esa opción NO
/// dispara [onSelected] (no hay nada funcional a lo que navegar). Solo
/// muestra un aviso y deja al usuario elegir 2008 en su lugar.
class ExamSelectionScreen extends StatelessWidget {
  const ExamSelectionScreen({super.key, required this.onSelected});

  final ValueChanged<ExamVersion> onSelected;

  void _handleTap(BuildContext context, ExamVersion version) {
    final l10n = AppLocalizations.of(context);

    if (version == ExamVersion.year2025) {
      // Banco 2025 sin contenido todavía: no se completa la selección,
      // así la próxima vez que se abra la app se sigue mostrando esta
      // pantalla en vez de quedar "trabada" en un banco vacío.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exam2025ComingSoon)),
      );
      return;
    }

    onSelected(version);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.examSelectionTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.examSelectionSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              _ExamOptionCard(
                title: l10n.exam2008Title,
                subtitle: l10n.exam2008Subtitle,
                onTap: () => _handleTap(context, ExamVersion.year2008),
              ),
              const SizedBox(height: 16),
              _ExamOptionCard(
                title: l10n.exam2025Title,
                subtitle: l10n.exam2025Subtitle,
                onTap: () => _handleTap(context, ExamVersion.year2025),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamOptionCard extends StatelessWidget {
  const _ExamOptionCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
