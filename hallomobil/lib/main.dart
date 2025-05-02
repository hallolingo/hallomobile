import 'package:flutter/material.dart';
import 'package:hallomobil/app_router.dart';
import 'package:hallomobil/pages/splash/splash_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HALLOLINGO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.generateRoute,
      onGenerateInitialRoutes: (initialRoute) {
        return [
          MaterialPageRoute(
            settings: const RouteSettings(name: AppRouter.splash),
            builder: (context) => const SplashPage(),
          ),
        ];
      },
    );
  }
}
