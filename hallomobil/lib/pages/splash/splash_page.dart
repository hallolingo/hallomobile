import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/constants/splash/splash_constants.dart';
import 'package:hallomobil/app_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();

    // Kullanıcı durumunu kontrol et
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    // Animasyonun bitmesini bekle (3 saniye)
    await Future.delayed(const Duration(seconds: 3));

    // Kullanıcı oturum açmış mı kontrol et
    User? user = _auth.currentUser;

    if (mounted) {
      if (user != null) {
        // Kullanıcı giriş yapmış, direkt ana sayfaya yönlendir
        Navigator.pushReplacementNamed(context, AppRouter.router);
      } else {
        // Kullanıcı giriş yapmamış, login sayfasına yönlendir
        Navigator.pushReplacementNamed(context, AppRouter.login);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.WHITE,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..scale(_scaleAnimation.value)
                      ..rotateZ(_rotationAnimation.value),
                    child: Image.asset(
                      SplashConstants.SPLASLOGO,
                      width: 150,
                      height: 150,
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'v 1.M.01',
              style: TextStyle(
                color: ColorConstants.BLACK, // Adjust color as needed
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
