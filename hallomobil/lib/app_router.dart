import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hallomobil/data/models/video_model.dart';
import 'package:hallomobil/pages/dictionary/dictionary_page.dart';
import 'package:hallomobil/pages/home/home_page.dart';
import 'package:hallomobil/pages/home/router_page.dart';
import 'package:hallomobil/pages/login/login_page.dart';
import 'package:hallomobil/pages/profile/profile_page.dart';
import 'package:hallomobil/pages/profile/settings/setting_page.dart';
import 'package:hallomobil/pages/register/language_selection_page.dart';
import 'package:hallomobil/pages/register/register_page.dart';
import 'package:hallomobil/pages/splash/splash_page.dart';
import 'package:hallomobil/pages/translate/translate_page.dart';
import 'package:hallomobil/pages/videos/video_detail_page.dart';
import 'package:hallomobil/pages/videos/videos_page.dart';
import 'package:video_player/video_player.dart';

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
      case settingsPage:
        final args = settings.arguments as Map<String, dynamic>?;
        try {
          return MaterialPageRoute(
            builder: (_) => SettingsPage(
              user: args?['user'] as User?,
              userData: args?['userData'] as Map<String, dynamic>?,
            ),
          );
        } catch (e) {
          // Error handling for debugging purposes
          debugPrint('Error creating SettingsPage route: $e');
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(
                child: Text('Error loading settings: $e'),
              ),
            ),
          );
        }
      case videoDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => VideoDetailPage(
            video: args['video'] as Video,
            controller: args['controller'] as VideoPlayerController,
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
}
