import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/constants/register/register_constants.dart';
import 'package:hallomobil/pages/login/login_page.dart';
import 'package:hallomobil/widgets/loginAndRegister/custom_input_field.dart';
import 'package:hallomobil/widgets/loginAndRegister/custom_login_button.dart';
import 'package:hallomobil/widgets/loginAndRegister/google_icon_button.dart';
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
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              FadeTransition(
            opacity: animation,
            child: const LoginPage(),
          ),
        ),
      );
    });
  }

  void _navigateToRouter() {
    Navigator.pushReplacementNamed(context, '/router');
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
                      CustomInputField(
                        labelText: RegisterConstants.FULL_NAME,
                        controller: _nameController,
                        prefixIcon: Icons.person,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      CustomInputField(
                        labelText: RegisterConstants.EMAIL,
                        controller: _emailController,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      CustomInputField(
                        labelText: RegisterConstants.PASSWORD,
                        isPassword: true,
                        controller: _passwordController,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      CustomLoginButton(
                        onPressed: _navigateToRouter,
                        text: RegisterConstants.SIGN_UP,
                        backgroundColor: ColorConstants.WHITE,
                        textColor: ColorConstants.MAINCOLOR,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      OrDivider(),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularIconButton(
                            image: AssetImage(RegisterConstants.GOOGLELOGO),
                            onPressed: () {},
                            backgroundColor: Colors.white,
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
