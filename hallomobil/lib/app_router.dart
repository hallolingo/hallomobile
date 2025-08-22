import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hallomobil/data/models/video_model.dart';
import 'package:hallomobil/pages/dictionary/dictionary_page.dart';
import 'package:hallomobil/pages/home/dinleme/fill_blank_page.dart';
import 'package:hallomobil/pages/home/dinleme/level_selection_page.dart';
import 'package:hallomobil/pages/home/home_page.dart';
import 'package:hallomobil/pages/home/konusma/dialogue_exercise_page.dart';
import 'package:hallomobil/pages/home/konusma/pronunciation_exercise_page.dart';
import 'package:hallomobil/pages/home/konusma/question_response_exercise_page.dart';
import 'package:hallomobil/pages/home/konusma/sentence_repetition_exercise_page.dart';
import 'package:hallomobil/pages/home/konusma/speaking_level_selection_page.dart';
import 'package:hallomobil/pages/home/konusma/speaking_page.dart';
import 'package:hallomobil/pages/home/router_page.dart';
import 'package:hallomobil/pages/login/login_page.dart';
import 'package:hallomobil/pages/premium/be_premium_screen.dart';
import 'package:hallomobil/pages/profile/profile_page.dart';
import 'package:hallomobil/pages/profile/settings/setting_page.dart';
import 'package:hallomobil/pages/register/language_selection_page.dart';
import 'package:hallomobil/pages/register/register_page.dart';
import 'package:hallomobil/pages/register/verification_page.dart';
import 'package:hallomobil/pages/splash/splash_page.dart';
import 'package:hallomobil/pages/translate/translate_page.dart';
import 'package:hallomobil/pages/videos/video_detail_page.dart';
import 'package:hallomobil/pages/videos/videos_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String router = '/router';
  static const String home = '/home';
  static const String translate = '/translate';
  static const String dictionary = '/dictionary';
  static const String videos = '/videos';
  static const String profile = '/profile';
  static const String languageSelection = '/languageSelection';
  static const String videoDetail = '/videoDetail';
  static const String settingsPage = '/settings';
  static const String premium = '/premium';
  static const String fillBlank = '/fillBlank';
  static const String levelSelection = '/levelSelection';
  static const String verificationCode = '/verificationCode';
  static const String speaking = '/speaking';
  static const String speakingLevelSelection = '/speaking_level_selection';
  static const String speakingExercise = '/speaking_exercise';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case router:
        return MaterialPageRoute(builder: (_) => const RouterPage());
      case speaking:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SpeakingPage(
            selectedLanguage: args?['selectedLanguage'] ?? 'Almanca',
          ),
        );
      case speakingLevelSelection:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SpeakingLevelSelectionPage(
            selectedLanguage: args?['selectedLanguage'] ?? 'Almanca',
            category: args?['category'] ?? 'pronunciation',
          ),
        );
      case speakingExercise:
        final args = settings.arguments as Map<String, dynamic>?;
        final category = args?['category'] ?? 'pronunciation';
        final selectedLanguage = args?['selectedLanguage'] ?? 'Almanca';
        final selectedLevel = args?['selectedLevel'] ?? 'A1';
        switch (category) {
          case 'pronunciation':
            return MaterialPageRoute(
              builder: (_) => PronunciationExercisePage(
                selectedLanguage: selectedLanguage,
                selectedLevel: selectedLevel,
              ),
            );
          case 'dialogue':
            return MaterialPageRoute(
              builder: (_) => DialogueExercisePage(
                selectedLanguage: selectedLanguage,
                selectedLevel: selectedLevel,
              ),
            );
          case 'question_response':
            return MaterialPageRoute(
              builder: (_) => QuestionResponseExercisePage(
                selectedLanguage: selectedLanguage,
                selectedLevel: selectedLevel,
              ),
            );
          case 'sentence_repetition':
            return MaterialPageRoute(
              builder: (_) => SentenceRepetitionExercisePage(
                selectedLanguage: selectedLanguage,
                selectedLevel: selectedLevel,
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Geçersiz konuşma kategorisi')),
              ),
            );
        }

      case verificationCode:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => VerificationCodePage(
            email: args['email'] as String,
            name: args['name'] as String?,
            password: args['password'] as String?,
            provider: args['provider'] as String,
          ),
        );
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case translate:
        return MaterialPageRoute(builder: (_) => const TranslationPage());
      case dictionary:
        return MaterialPageRoute(builder: (_) => const DictionaryPage());
      case videos:
        return MaterialPageRoute(builder: (_) => const VideosPage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case premium:
        return MaterialPageRoute(builder: (_) => const PremiumPage());
      case levelSelection:
        final selectedLanguage = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) =>
              LevelSelectionPage(selectedLanguage: selectedLanguage),
        );
      case fillBlank:
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => ListeningFillBlankPage(
            selectedLanguage: args['selectedLanguage']!,
            selectedLevel: args['selectedLevel']!,
          ),
        );
      case AppRouter.settingsPage:
        try {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (context) => SettingsPage(
              user: args['user'] as User?,
              userData: args['userData'] as Map<String, dynamic>? ?? {},
            ),
          );
        } catch (e) {
          debugPrint('Error in settings route: $e');
          return _errorRoute(settings);
        }
      case videoDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => VideoDetailPage(
            video: args['video'] as Video,
            controller: args['controller'] as ChewieController,
          ),
        );
      case languageSelection:
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => LanguageSelectionPage(
            userId: args['userId']!,
            userEmail: args['userEmail']!,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text('Route hatası: ${settings.name}'),
        ),
      ),
    );
  }
}
