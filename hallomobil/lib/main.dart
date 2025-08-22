import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hallomobil/app_router.dart';
import 'package:hallomobil/firebase_options.dart';
import 'package:hallomobil/pages/splash/splash_page.dart';
import 'package:hallomobil/services/auth/email_auth_service.dart';
import 'package:hallomobil/services/google/google_auth_service.dart';
import 'package:hallomobil/services/verification/verification_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Future.delayed(const Duration(milliseconds: 300));

  runApp(
    MultiProvider(
      providers: [
        Provider<VerificationService>(
          create: (_) =>
              VerificationService(firestore: FirebaseFirestore.instance),
        ),
        Provider<EmailAuthService>(
          create: (_) => EmailAuthService(
            auth: FirebaseAuth.instance,
            firestore: FirebaseFirestore.instance,
            verificationService:
                Provider.of<VerificationService>(_, listen: false),
          ),
        ),
        Provider<GoogleAuthService>(
          create: (_) => GoogleAuthService(
            auth: FirebaseAuth.instance,
            firestore: FirebaseFirestore.instance,
            storage: FirebaseStorage.instance,
            verificationService:
                Provider.of<VerificationService>(_, listen: false),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
