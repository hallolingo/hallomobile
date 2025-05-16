import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hallomobil/app_router.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/constants/register/register_constants.dart';
import 'package:hallomobil/widgets/custom_snackbar.dart';
import 'package:hallomobil/widgets/loginAndRegister/auth/email_register_form.dart';
import 'package:hallomobil/widgets/loginAndRegister/google/google_sign_in_button.dart';
import 'package:hallomobil/widgets/loginAndRegister/login_prompt.dart';
import 'package:hallomobil/widgets/loginAndRegister/or_divider_widget.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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

  void _navigateToRouter() {
    Navigator.pushReplacementNamed(context, AppRouter.router);
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: ColorConstants.WHITE,
      body: SafeArea(
        child: Column(
          children: [
            if (!isKeyboardVisible) ...[
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              Image.asset(RegisterConstants.REGISTERLOGO),
              const Spacer(),
            ],
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 100 * (1 - _animation.value)),
                  child: Opacity(
                    opacity: _animation.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                padding:
                    EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                decoration: BoxDecoration(
                  color: ColorConstants.MAINCOLOR,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05),
                  child: Column(
                    children: [
                      Text(
                        RegisterConstants.CREATE_ACCOUNT,
                        style: TextStyle(
                          color: ColorConstants.WHITE,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),

                      // Email ile kayıt formu
                      EmailRegisterForm(
                        onSuccess: _navigateToRouter,
                        nameController: _nameController,
                        emailController: _emailController,
                        passwordController: _passwordController,
                      ),

                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      OrDivider(),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),

                      // Google ile giriş butonu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GoogleSignInButton(
                            onSuccess: (email) {
                              Navigator.pushNamed(
                                context,
                                AppRouter.languageSelection,
                                arguments: {
                                  'userId':
                                      FirebaseAuth.instance.currentUser!.uid,
                                  'userEmail': email,
                                },
                              );
                            },
                            onError: () {
                              showCustomSnackBar(
                                context: context,
                                message: 'Google ile giriş yapılamadı',
                                isError: true,
                              );
                            },
                            backgroundColor: Colors.white,
                            imagePath: RegisterConstants.GOOGLELOGO,
                            context: context,
                          ),
                        ],
                      ),

                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      LoginPrompt(
                        onTap: _navigateToLogin,
                        promptText: RegisterConstants.ALREADY_HAVE_ACCOUNT,
                        actionText: RegisterConstants.SIGN_IN_NOW,
                        promptColor: ColorConstants.WHITE,
                        actionTextColor: ColorConstants.WHITE,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
