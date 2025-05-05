import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/constants/login/login_constants.dart';
import 'package:hallomobil/pages/register/register_page.dart';
import 'package:hallomobil/widgets/loginAndRegister/custom_login_button.dart';
import 'package:hallomobil/widgets/loginAndRegister/google_icon_button.dart';
import 'package:hallomobil/widgets/loginAndRegister/or_divider_widget.dart';
import 'package:hallomobil/widgets/loginAndRegister/register_prompt.dart';
import 'package:hallomobil/widgets/loginAndRegister/custom_input_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late AnimationController _containerAnimationController;
  late Animation<double> _containerAnimation;

  @override
  void initState() {
    super.initState();
    _containerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _containerAnimation = CurvedAnimation(
      parent: _containerAnimationController,
      curve: Curves.easeInOut,
    );
    _containerAnimationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _containerAnimationController.dispose();
    super.dispose();
  }

  void _navigateToRegister() {
    _containerAnimationController.reverse().then((_) {
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              FadeTransition(
            opacity: animation,
            child: const RegisterPage(),
          ),
        ),
      );
    });
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
              Image.asset(LoginConstants.LOGINLOGO),
              const Spacer(),
            ],
            AnimatedBuilder(
              animation: _containerAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 100 * (1 - _containerAnimation.value)),
                  child: Opacity(
                    opacity: _containerAnimation.value,
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
                        LoginConstants.WELCOME,
                        style: TextStyle(
                          color: ColorConstants.WHITE,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      CustomInputField(
                        labelText: LoginConstants.EMAIL,
                        controller: _emailController,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      CustomInputField(
                        labelText: LoginConstants.PASSWORD,
                        isPassword: true,
                        controller: _passwordController,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            LoginConstants.FORGOT_PASSWORD,
                            style: TextStyle(
                              color: ColorConstants.WHITE,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01),
                      CustomLoginButton(
                        onPressed: () {},
                        text: LoginConstants.LOGIN,
                        backgroundColor: ColorConstants.WHITE,
                        textColor: ColorConstants.MAINCOLOR,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01),
                      OrDivider(),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularIconButton(
                            image: AssetImage(LoginConstants.GOOGLELOGO),
                            onPressed: () {},
                            backgroundColor: Colors.white,
                          ),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      RegisterPrompt(
                        onTap: _navigateToRegister,
                        promptText: LoginConstants.DONT_HAVE_ACCOUNT,
                        actionText: LoginConstants.SIGN_UP_NOW,
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
