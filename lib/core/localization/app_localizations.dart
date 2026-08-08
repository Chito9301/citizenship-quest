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
      'navHome': 'Home',
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
      'avgTimePerQuestion': 'Avg. time / question',
      'motivationExcellent': 'Outstanding! You\'re ready for the real test.',
      'motivationGood': 'Great job! A bit more practice and you\'ll master it.',
      'motivationKeepPracticing': 'Keep practicing — you\'re building real progress.',
      'resultCelebrationTitle': '🎉 Great job!',
      'resultComparisonSame': 'Same as your last session',
      'resultNoErrors': 'Perfect! No mistakes this time.',
      'resultHideErrors': 'Hide errors',
      'resultCorrectAnswerLabel': 'Correct answer',
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
      'syncNoConnection': 'No internet connection',
      'syncNoPendingData': 'Nothing to sync',
      'syncFailed': 'Sync failed, will retry later',
      'loadingLabel': 'Loading...',
      'errorLabel': 'Something went wrong',
      'retryLabel': 'Retry',
      // Home / Lobby
      'homeGreeting': 'Hello! 👋',
      'homeStartPractice': 'Start practice',
      'homeCategoriesTitle': 'Categories',
      'categoryGovernment': 'Government',
      'categoryHistory': 'History',
      'categoryCivics': 'Civics',
      'homeLeagueMaxReached': 'You reached the top league!',
      'homeSmartReviewTitle': 'Smart review',
      'homeSmartReviewNoData': 'Keep practicing to unlock personalized recommendations.',
      // Onboarding
      'onboardingSkip': 'Skip',
      'onboardingNext': 'Next',
      'onboardingStart': 'Start now',
      'onboardingTitle1': 'Get ready for your citizenship interview',
      'onboardingBody1': 'Practice the official 100 USCIS questions — simply, quickly, and fully offline.',
      'onboardingTitle2': 'Keep your consistency',
      'onboardingBody2': 'Studying 5 minutes a day is more effective than one long session now and then.',
      'onboardingTitle3': 'Level up',
      'onboardingBody3': 'Earn points, unlock badges, and progress through mastery levels.',
      'onboardingTitle4': 'Start your path to citizenship',
      'onboardingBody4': 'Everything you practice here stays saved on your device, ready whenever you are.',
    },
    'es': {
      'appTitle': 'Citizenship Quest',
      'navQuiz': 'Quiz',
      'navHome': 'Inicio',
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
      'avgTimePerQuestion': 'Tiempo prom. / pregunta',
      'motivationExcellent': '¡Excelente! Ya estás listo para el examen real.',
      'motivationGood': '¡Buen trabajo! Un poco más de práctica y lo dominarás.',
      'motivationKeepPracticing': 'Sigue practicando — estás progresando de verdad.',
      'resultCelebrationTitle': '🎉 ¡Buen trabajo!',
      'resultComparisonSame': 'Igual que tu última sesión',
      'resultNoErrors': '¡Perfecto! Sin errores esta vez.',
      'resultHideErrors': 'Ocultar errores',
      'resultCorrectAnswerLabel': 'Respuesta correcta',
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
      'syncNoConnection': 'No hay conexión a Internet',
      'syncNoPendingData': 'No hay datos pendientes',
      'syncFailed': 'Falló la sincronización, se reintentará luego',
      'loadingLabel': 'Cargando...',
      'errorLabel': 'Algo salió mal',
      'retryLabel': 'Reintentar',
      // Home / Lobby
      'homeGreeting': '¡Hola! 👋',
      'homeStartPractice': 'Comenzar práctica',
      'homeCategoriesTitle': 'Categorías',
      'categoryGovernment': 'Gobierno',
      'categoryHistory': 'Historia',
      'categoryCivics': 'Educación cívica',
      'homeLeagueMaxReached': '¡Llegaste a la liga más alta!',
      'homeSmartReviewTitle': 'Repaso inteligente',
      'homeSmartReviewNoData': 'Sigue practicando para desbloquear recomendaciones personalizadas.',
      // Onboarding
      'onboardingSkip': 'Saltar',
      'onboardingNext': 'Siguiente',
      'onboardingStart': 'Comenzar ahora',
      'onboardingTitle1': 'Prepárate para tu entrevista de ciudadanía',
      'onboardingBody1': 'Practica las 100 preguntas oficiales de USCIS de forma sencilla, rápida y sin conexión a internet.',
      'onboardingTitle2': 'Mantén tu constancia',
      'onboardingBody2': 'Estudiar 5 minutos al día es más efectivo que una sesión prolongada ocasional.',
      'onboardingTitle3': 'Avanza de nivel',
      'onboardingBody3': 'Gana puntos, desbloquea insignias y progresa a través de diferentes niveles de dominio.',
      'onboardingTitle4': 'Inicia tu camino hacia la ciudadanía',
      'onboardingBody4': 'Todo lo que practiques aquí queda guardado en tu dispositivo, listo cuando quieras seguir.',
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
  String get avgTimePerQuestion => _t('avgTimePerQuestion');
  String get motivationExcellent => _t('motivationExcellent');
  String get motivationGood => _t('motivationGood');
  String get motivationKeepPracticing => _t('motivationKeepPracticing');
  String get resultCelebrationTitle => _t('resultCelebrationTitle');
  String get resultComparisonSame => _t('resultComparisonSame');
  String get resultNoErrors => _t('resultNoErrors');
  String get resultHideErrors => _t('resultHideErrors');
  String get resultCorrectAnswerLabel => _t('resultCorrectAnswerLabel');
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
  String get syncNoConnection => _t('syncNoConnection');
  String get syncNoPendingData => _t('syncNoPendingData');
  String get syncFailed => _t('syncFailed');
  String get loadingLabel => _t('loadingLabel');
  String get errorLabel => _t('errorLabel');
  String get retryLabel => _t('retryLabel');
  String get navHome => _t('navHome');
  String get homeGreeting => _t('homeGreeting');
  String get homeStartPractice => _t('homeStartPractice');
  String get homeCategoriesTitle => _t('homeCategoriesTitle');
  String get categoryGovernment => _t('categoryGovernment');
  String get categoryHistory => _t('categoryHistory');
  String get categoryCivics => _t('categoryCivics');
  String get homeLeagueMaxReached => _t('homeLeagueMaxReached');
  String get homeSmartReviewTitle => _t('homeSmartReviewTitle');
  String get homeSmartReviewNoData => _t('homeSmartReviewNoData');
  String get onboardingSkip => _t('onboardingSkip');
  String get onboardingNext => _t('onboardingNext');
  String get onboardingStart => _t('onboardingStart');
  String get onboardingTitle1 => _t('onboardingTitle1');
  String get onboardingBody1 => _t('onboardingBody1');
  String get onboardingTitle2 => _t('onboardingTitle2');
  String get onboardingBody2 => _t('onboardingBody2');
  String get onboardingTitle3 => _t('onboardingTitle3');
  String get onboardingBody3 => _t('onboardingBody3');
  String get onboardingTitle4 => _t('onboardingTitle4');
  String get onboardingBody4 => _t('onboardingBody4');

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

  String homeQuestionsRemaining(int count) {
    return locale.languageCode == 'es'
        ? 'Estás a $count preguntas de dominar el examen.'
        : "You're $count questions away from mastering the exam.";
  }

  String homeQuestionsMastered(int mastered, int total) {
    return locale.languageCode == 'es'
        ? '$mastered / $total preguntas dominadas'
        : '$mastered / $total questions mastered';
  }

  String homeStreakDays(int count) {
    return locale.languageCode == 'es'
        ? '$count días consecutivos'
        : '$count days in a row';
  }

  String homeLeaguePointsToNext(int points) {
    return locale.languageCode == 'es'
        ? 'Te faltan $points puntos para subir de liga'
        : '$points points to reach the next league';
  }

  String homeSmartReviewWeakCategory(String category) {
    return locale.languageCode == 'es'
        ? 'Tu categoría más débil es "$category". Repásala hoy.'
        : 'Your weakest category is "$category". Review it today.';
  }

  String resultComparisonUp(int delta) {
    return locale.languageCode == 'es'
        ? '+$delta puntos respecto a tu sesión anterior'
        : '+$delta points vs. your previous session';
  }

  String resultComparisonDown(int delta) {
    return locale.languageCode == 'es'
        ? '-$delta puntos respecto a tu sesión anterior'
        : '-$delta points vs. your previous session';
  }

  String resultReviewErrors(int count) {
    return locale.languageCode == 'es'
        ? 'Revisar errores ($count)'
        : 'Review errors ($count)';
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
