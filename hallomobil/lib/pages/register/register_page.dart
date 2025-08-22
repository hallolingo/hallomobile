import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hallomobil/app_router.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/constants/register/register_constants.dart';
import 'package:hallomobil/services/auth/email_auth_service.dart';
import 'package:hallomobil/services/google/google_auth_service.dart';
import 'package:hallomobil/widgets/common_widgets.dart';
import 'package:hallomobil/widgets/custom_snackbar.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _cardAnimation;
  late Animation<double> _logoAnimation;
  late bool _isLoading;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Animasyon ayarları (mevcut kod korunuyor)
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
    _animationController.dispose();
    _cardAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    _animationController.reverse().then((_) {
      Navigator.pushReplacementNamed(context, AppRouter.login);
    });
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
              ColorConstants.SECONDARY_COLOR.withOpacity(0.1),
              Colors.white,
              ColorConstants.MAINCOLOR.withOpacity(0.05),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
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
                                            color: ColorConstants
                                                .SECONDARY_COLOR
                                                .withOpacity(0.2),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Image.network(
                                        RegisterConstants.REGISTERLOGO,
                                        width: screenWidth * 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Hesap Oluştur',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: ColorConstants.MAINCOLOR,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Yeni hesabınızı oluşturun',
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

                      // Register Form
                      Expanded(
                        flex: 2,
                        child: AnimatedBuilder(
                          animation: _cardAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 0.8 + (_cardAnimation.value * 0.2),
                              child: Opacity(
                                opacity: _cardAnimation.value,
                                child: buildGlassmorphicCard(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Column(
                                        children: [
                                          buildModernTextField(
                                            label: 'Ad Soyad',
                                            controller: _nameController,
                                            prefixIcon: Icons.person_outline,
                                          ),
                                          buildModernTextField(
                                            label: RegisterConstants.EMAIL ??
                                                'E-posta',
                                            controller: _emailController,
                                            prefixIcon: Icons.email_outlined,
                                          ),
                                          buildModernTextField(
                                            label: RegisterConstants.PASSWORD ??
                                                'Şifre',
                                            controller: _passwordController,
                                            isPassword: true,
                                            prefixIcon: Icons.lock_outline,
                                          ),
                                          const SizedBox(height: 10),
                                          buildGradientButton(
                                            text: RegisterConstants.SIGN_UP,
                                            onPressed: () async {
                                              final email =
                                                  _emailController.text.trim();
                                              final password =
                                                  _passwordController.text;
                                              final name =
                                                  _nameController.text.trim();

                                              if (email.isEmpty ||
                                                  password.isEmpty ||
                                                  name.isEmpty) {
                                                showCustomSnackBar(
                                                  context: context,
                                                  message:
                                                      'Lütfen tüm alanları doldurun',
                                                  isError: true,
                                                );
                                                return;
                                              }

                                              if (!RegExp(
                                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                                  .hasMatch(email)) {
                                                showCustomSnackBar(
                                                  context: context,
                                                  message:
                                                      'Geçerli bir e-posta adresi girin',
                                                  isError: true,
                                                );
                                                return;
                                              }

                                              if (password.length < 6) {
                                                showCustomSnackBar(
                                                  context: context,
                                                  message:
                                                      'Şifre en az 6 karakter olmalı',
                                                  isError: true,
                                                );
                                                return;
                                              }

                                              try {
                                                setState(
                                                    () => _isLoading = true);
                                                final emailAuthService =
                                                    Provider.of<
                                                            EmailAuthService>(
                                                        context,
                                                        listen: false);
                                                await emailAuthService
                                                    .sendVerificationCode(
                                                        email);

                                                Navigator.pushNamed(
                                                  context,
                                                  AppRouter.verificationCode,
                                                  arguments: {
                                                    'email': email,
                                                    'name': name,
                                                    'password': password,
                                                    'provider': 'email',
                                                  },
                                                );
                                              } catch (e) {
                                                showCustomSnackBar(
                                                  context: context,
                                                  message:
                                                      'Hata: ${e.toString()}',
                                                  isError: true,
                                                );
                                              } finally {
                                                if (mounted) {
                                                  setState(
                                                      () => _isLoading = false);
                                                }
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  height: 1,
                                                  color: Colors.grey
                                                      .withOpacity(0.3),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                  color: Colors.grey
                                                      .withOpacity(0.3),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 18),
                                          InkWell(
                                            onTap: () async {
                                              try {
                                                final googleAuthService =
                                                    Provider.of<
                                                            GoogleAuthService>(
                                                        context,
                                                        listen: false);
                                                final userCredential =
                                                    await googleAuthService
                                                        .signInWithGoogle(
                                                            context: context);
                                                if (userCredential != null &&
                                                    userCredential.user !=
                                                        null) {
                                                  final email = userCredential
                                                      .user!.email;
                                                  if (email != null) {
                                                    Navigator.pushNamed(
                                                      context,
                                                      AppRouter
                                                          .languageSelection,
                                                      arguments: {
                                                        'userId': FirebaseAuth
                                                            .instance
                                                            .currentUser!
                                                            .uid,
                                                        'userEmail': email,
                                                      },
                                                    );
                                                  }
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
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: Container(
                                              width: double.infinity,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey
                                                      .withOpacity(0.3),
                                                  width: 1.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Image.asset(
                                                    RegisterConstants
                                                        .GOOGLELOGO,
                                                    height: 24,
                                                    width: 24,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
                                                    'Google ile Devam Et',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                RegisterConstants
                                                    .ALREADY_HAVE_ACCOUNT,
                                                style: TextStyle(
                                                  color: ColorConstants
                                                      .TEXT_COLOR
                                                      .withOpacity(0.7),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: _navigateToLogin,
                                                child: Text(
                                                  RegisterConstants.SIGN_IN_NOW,
                                                  style: TextStyle(
                                                    color: ColorConstants
                                                        .MAINCOLOR,
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
                            );
                          },
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
