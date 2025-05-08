import 'package:flutter/material.dart';
import 'package:hallomobil/pages/dictionary/dictionary_page.dart';
import 'package:hallomobil/pages/home/home_page.dart';
import 'package:hallomobil/pages/home/router_page.dart';
import 'package:hallomobil/pages/login/login_page.dart';
import 'package:hallomobil/pages/profile/profile_page.dart';
import 'package:hallomobil/pages/register/register_page.dart';
import 'package:hallomobil/pages/splash/splash_page.dart';
import 'package:hallomobil/pages/translate/translate_page.dart';
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
