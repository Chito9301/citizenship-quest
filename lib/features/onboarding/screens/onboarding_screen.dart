import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class _OnboardingPageData {
  const _OnboardingPageData({required this.emoji, required this.title, required this.body});

  final String emoji;
  final String title;
  final String body;
}

/// Onboarding de 4 pantallas, solo para el primer uso de la app. El
/// flag `hasSeenOnboarding` lo persiste quien llama a [onComplete]
/// (ver app_router.dart), no esta pantalla directamente, para que sea
/// fácil de testear de forma aislada (sin storage).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_OnboardingPageData> _pages(AppLocalizations l10n) => [
        _OnboardingPageData(
          emoji: '🎯',
          title: l10n.onboardingTitle1,
          body: l10n.onboardingBody1,
        ),
        _OnboardingPageData(
          emoji: '🔥',
          title: l10n.onboardingTitle2,
          body: l10n.onboardingBody2,
        ),
        _OnboardingPageData(
          emoji: '🏆',
          title: l10n.onboardingTitle3,
          body: l10n.onboardingBody3,
        ),
        _OnboardingPageData(
          emoji: '🚀',
          title: l10n.onboardingTitle4,
          body: l10n.onboardingBody4,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _pages(l10n);
    final isLastPage = _page == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: isLastPage ? null : widget.onComplete,
                  child: Text(isLastPage ? '' : l10n.onboardingSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(page.emoji, style: const TextStyle(fontSize: 72)),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _page ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: index == _page
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLastPage) {
                      widget.onComplete();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(isLastPage ? l10n.onboardingStart : l10n.onboardingNext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
