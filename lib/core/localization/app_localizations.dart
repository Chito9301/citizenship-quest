import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Localización manual EN/ES para Sprint 1.
///
/// Las claves de este archivo reflejan 1:1 las claves definidas en
/// `l10n/app_en.arb` y `l10n/app_es.arb`. Se implementa a mano (sin
/// `flutter gen-l10n`) para que el proyecto compile sin pasos de
/// generación de código adicionales; en un sprint futuro se puede migrar
/// a `flutter_localizations` + `gen-l10n` reutilizando los mismos .arb.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    final localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(localizations != null, 'No AppLocalizations found in context');
    return localizations!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'appTitle': 'Citizenship Quest',
      'navQuiz': 'Quiz',
      'navProfile': 'Profile',
      'navRanking': 'Ranking',
      'navSettings': 'Settings',
      'quizTitle': 'Citizenship Quiz',
      'startQuiz': 'Start Quiz',
      'nextQuestion': 'Next',
      'finishQuiz': 'Finish',
      'skipQuestion': 'Skip',
      'fiftyFifty': '50/50',
      'correctAnswer': 'Correct!',
      'incorrectAnswer': 'Incorrect',
      'explanationLabel': 'Why?',
      'resultTitle': 'Quiz Results',
      'yourScore': 'Your score',
      'playAgain': 'Play again',
      'goHome': 'Go home',
      'profileTitle': 'Profile',
      'totalScore': 'Total score',
      'quizzesPlayed': 'Quizzes played',
      'accuracyLabel': 'Accuracy',
      'currentStreak': 'Current streak',
      'badgesLabel': 'Badges',
      'noBadgesYet': 'No badges yet. Keep playing!',
      'rankingTitle': 'Ranking',
      'rankingLoading': 'Loading ranking...',
      'settingsTitle': 'Settings',
      'languageLabel': 'Language',
      'englishOption': 'English',
      'spanishOption': 'Español',
      'syncNow': 'Sync now',
      'syncSuccess': 'Sync complete',
      'loadingLabel': 'Loading...',
      'errorLabel': 'Something went wrong',
      'retryLabel': 'Retry',
    },
    'es': {
      'appTitle': 'Citizenship Quest',
      'navQuiz': 'Quiz',
      'navProfile': 'Perfil',
      'navRanking': 'Ranking',
      'navSettings': 'Ajustes',
      'quizTitle': 'Quiz de Ciudadanía',
      'startQuiz': 'Comenzar Quiz',
      'nextQuestion': 'Siguiente',
      'finishQuiz': 'Finalizar',
      'skipQuestion': 'Saltar',
      'fiftyFifty': '50/50',
      'correctAnswer': '¡Correcto!',
      'incorrectAnswer': 'Incorrecto',
      'explanationLabel': '¿Por qué?',
      'resultTitle': 'Resultados del Quiz',
      'yourScore': 'Tu puntaje',
      'playAgain': 'Jugar de nuevo',
      'goHome': 'Ir al inicio',
      'profileTitle': 'Perfil',
      'totalScore': 'Puntaje total',
      'quizzesPlayed': 'Quizzes jugados',
      'accuracyLabel': 'Precisión',
      'currentStreak': 'Racha actual',
      'badgesLabel': 'Insignias',
      'noBadgesYet': 'Aún no hay insignias. ¡Sigue jugando!',
      'rankingTitle': 'Ranking',
      'rankingLoading': 'Cargando ranking...',
      'settingsTitle': 'Ajustes',
      'languageLabel': 'Idioma',
      'englishOption': 'English',
      'spanishOption': 'Español',
      'syncNow': 'Sincronizar ahora',
      'syncSuccess': 'Sincronización completa',
      'loadingLabel': 'Cargando...',
      'errorLabel': 'Algo salió mal',
      'retryLabel': 'Reintentar',
    },
  };

  String _t(String key) {
    final lang = _values.containsKey(locale.languageCode)
        ? locale.languageCode
        : 'en';
    return _values[lang]?[key] ?? _values['en']![key] ?? key;
  }

  String get appTitle => _t('appTitle');
  String get navQuiz => _t('navQuiz');
  String get navProfile => _t('navProfile');
  String get navRanking => _t('navRanking');
  String get navSettings => _t('navSettings');
  String get quizTitle => _t('quizTitle');
  String get startQuiz => _t('startQuiz');
  String get nextQuestion => _t('nextQuestion');
  String get finishQuiz => _t('finishQuiz');
  String get skipQuestion => _t('skipQuestion');
  String get fiftyFifty => _t('fiftyFifty');
  String get correctAnswer => _t('correctAnswer');
  String get incorrectAnswer => _t('incorrectAnswer');
  String get explanationLabel => _t('explanationLabel');
  String get resultTitle => _t('resultTitle');
  String get yourScore => _t('yourScore');
  String get playAgain => _t('playAgain');
  String get goHome => _t('goHome');
  String get profileTitle => _t('profileTitle');
  String get totalScore => _t('totalScore');
  String get quizzesPlayed => _t('quizzesPlayed');
  String get accuracyLabel => _t('accuracyLabel');
  String get currentStreak => _t('currentStreak');
  String get badgesLabel => _t('badgesLabel');
  String get noBadgesYet => _t('noBadgesYet');
  String get rankingTitle => _t('rankingTitle');
  String get rankingLoading => _t('rankingLoading');
  String get settingsTitle => _t('settingsTitle');
  String get languageLabel => _t('languageLabel');
  String get englishOption => _t('englishOption');
  String get spanishOption => _t('spanishOption');
  String get syncNow => _t('syncNow');
  String get syncSuccess => _t('syncSuccess');
  String get loadingLabel => _t('loadingLabel');
  String get errorLabel => _t('errorLabel');
  String get retryLabel => _t('retryLabel');

  String questionOf(int current, int total) {
    return locale.languageCode == 'es'
        ? 'Pregunta $current de $total'
        : 'Question $current of $total';
  }

  String correctCount(int correct, int total) {
    return locale.languageCode == 'es'
        ? '$correct de $total correctas'
        : '$correct of $total correct';
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any(
        (l) => l.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
