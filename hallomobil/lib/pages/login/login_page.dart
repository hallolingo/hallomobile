import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hallomobil/app_router.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/constants/login/login_constants.dart';
import 'package:hallomobil/pages/register/register_page.dart';
import 'package:hallomobil/services/google/google_auth_service.dart';
import 'package:hallomobil/widgets/custom_snackbar.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _cardAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();

    // Page animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
    ));

    _logoAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    // Card animation setup
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _cardAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _cardAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  void _navigateToRegister() {
    _animationController.reverse().then((_) {
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: const RegisterPage(),
          ),
        ),
      );
    });
  }

  Widget _buildGlassmorphicCard({
    required Widget child,
    EdgeInsets? margin,
  }) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_cardAnimation.value * 0.2),
          child: Opacity(
            opacity: _cardAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin:
            margin ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.MAINCOLOR.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: -5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    IconData? prefixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ColorConstants.TEXT_COLOR,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: ColorConstants.MAINCOLOR.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon,
                  color: ColorConstants.MAINCOLOR.withOpacity(0.7))
              : null,
          filled: true,
          fillColor: ColorConstants.MAINCOLOR.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: ColorConstants.MAINCOLOR.withOpacity(0.1),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: ColorConstants.MAINCOLOR,
              width: 2,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = true,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  ColorConstants.MAINCOLOR,
                  ColorConstants.SECONDARY_COLOR,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: ColorConstants.MAINCOLOR.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isPrimary ? Colors.white : ColorConstants.MAINCOLOR,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorConstants.MAINCOLOR.withOpacity(0.1),
              Colors.white,
              ColorConstants.SECONDARY_COLOR.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  height: screenHeight - MediaQuery.of(context).padding.top,
                  child: Column(
                    children: [
                      // Header with Logo
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _logoAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _logoAnimation.value,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: ColorConstants.MAINCOLOR
                                                .withOpacity(0.2),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Image.network(
                                        LoginConstants.LOGINLOGO,
                                        width: screenWidth * 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Hoş Geldiniz',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: ColorConstants.MAINCOLOR,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Hesabınıza giriş yapın',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: ColorConstants.TEXT_COLOR
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Login Form
                      Expanded(
                        flex: 2,
                        child: _buildGlassmorphicCard(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  _buildModernTextField(
                                    label: LoginConstants.EMAIL,
                                    controller: _emailController,
                                    prefixIcon: Icons.email_outlined,
                                  ),

                                  _buildModernTextField(
                                    label: LoginConstants.PASSWORD,
                                    controller: _passwordController,
                                    isPassword: true,
                                    prefixIcon: Icons.lock_outline,
                                  ),

                                  // Forgot Password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () async {
                                        if (_emailController.text.isEmpty) {
                                          showCustomSnackBar(
                                            context: context,
                                            message:
                                                'Şifre sıfırlama için e-posta adresinizi girin',
                                            isError: true,
                                          );
                                          return;
                                        }

                                        try {
                                          await FirebaseAuth.instance
                                              .sendPasswordResetEmail(
                                            email: _emailController.text.trim(),
                                          );
                                          showCustomSnackBar(
                                            context: context,
                                            message:
                                                'Şifre sıfırlama e-postası gönderildi',
                                            isError: false,
                                          );
                                        } on FirebaseAuthException catch (e) {
                                          String message =
                                              'Şifre sıfırlama e-postası gönderilemedi';
                                          if (e.code == 'user-not-found') {
                                            message =
                                                'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı';
                                          }
                                          showCustomSnackBar(
                                            context: context,
                                            message: message,
                                            isError: true,
                                          );
                                        }
                                      },
                                      child: Text(
                                        LoginConstants.FORGOT_PASSWORD,
                                        style: TextStyle(
                                          color: ColorConstants.MAINCOLOR,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Login Button
                                  _buildGradientButton(
                                    text: LoginConstants.LOGIN,
                                    onPressed: () async {
                                      if (_emailController.text.isEmpty ||
                                          _passwordController.text.isEmpty) {
                                        showCustomSnackBar(
                                          context: context,
                                          message:
                                              'E-posta ve şifre alanları boş bırakılamaz',
                                          isError: true,
                                        );
                                        return;
                                      }

                                      try {
                                        final credential = await FirebaseAuth
                                            .instance
                                            .signInWithEmailAndPassword(
                                          email: _emailController.text.trim(),
                                          password: _passwordController.text,
                                        );

                                        if (credential.user != null) {
                                          Navigator.pushReplacementNamed(
                                              context, AppRouter.router);
                                        }
                                      } on FirebaseAuthException catch (e) {
                                        String message = 'Giriş yapılamadı';
                                        if (e.code == 'user-not-found') {
                                          message =
                                              'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı';
                                        } else if (e.code == 'wrong-password') {
                                          message = 'Hatalı şifre';
                                        } else if (e.code == 'invalid-email') {
                                          message = 'Geçersiz e-posta adresi';
                                        }

                                        showCustomSnackBar(
                                          context: context,
                                          message: message,
                                          isError: true,
                                        );
                                      } catch (e) {
                                        showCustomSnackBar(
                                          context: context,
                                          message: 'Bir hata oluştu: $e',
                                          isError: true,
                                        );
                                      }
                                    },
                                  ),

                                  const SizedBox(height: 12),

                                  // Divider
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.grey.withOpacity(0.3),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text(
                                          'veya',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.grey.withOpacity(0.3),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Google Sign In
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      child: InkWell(
                                        onTap: () async {
                                          try {
                                            final googleAuthService =
                                                Provider.of<GoogleAuthService>(
                                                    context,
                                                    listen: false);
                                            final userCredential =
                                                await googleAuthService
                                                    .signInWithGoogle(
                                                        context: context);

                                            if (userCredential != null &&
                                                userCredential.user != null) {
                                              Navigator.pushReplacementNamed(
                                                  context, AppRouter.router);
                                            }
                                          } catch (e) {
                                            showCustomSnackBar(
                                              context: context,
                                              message:
                                                  'Google ile giriş yapılamadı',
                                              isError: true,
                                            );
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              LoginConstants.GOOGLELOGO,
                                              width: 24,
                                              height: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Google ile devam et',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    ColorConstants.TEXT_COLOR,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Register Prompt
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        LoginConstants.DONT_HAVE_ACCOUNT,
                                        style: TextStyle(
                                          color: ColorConstants.TEXT_COLOR
                                              .withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _navigateToRegister,
                                        child: Text(
                                          LoginConstants.SIGN_UP_NOW,
                                          style: TextStyle(
                                            color: ColorConstants.MAINCOLOR,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
