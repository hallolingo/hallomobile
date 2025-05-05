import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/constants/register/register_constants.dart';
import 'package:hallomobil/services/auth/email_auth_service.dart';
import 'package:hallomobil/widgets/custom_snackbar.dart';
import 'package:hallomobil/widgets/loginAndRegister/custom_input_field.dart';
import 'package:hallomobil/widgets/loginAndRegister/custom_login_button.dart';
import 'package:provider/provider.dart';

class EmailRegisterForm extends StatefulWidget {
  final VoidCallback onSuccess;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const EmailRegisterForm({
    super.key,
    required this.onSuccess,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
  });

  @override
  State<EmailRegisterForm> createState() => _EmailRegisterFormState();
}

class _EmailRegisterFormState extends State<EmailRegisterForm> {
  bool _isLoading = false;

  Future<void> _registerWithEmail() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final emailAuthService =
          Provider.of<EmailAuthService>(context, listen: false);

      await emailAuthService.registerWithEmail(
        email: widget.emailController.text.trim(),
        password: widget.passwordController.text.trim(),
        name: widget.nameController.text.trim(),
      );

      widget.onSuccess();
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'Kayıt işlemi başarısız',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomInputField(
          labelText: RegisterConstants.FULL_NAME,
          controller: widget.nameController,
          prefixIcon: Icons.person,
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        CustomInputField(
          labelText: RegisterConstants.EMAIL,
          controller: widget.emailController,
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        CustomInputField(
          labelText: RegisterConstants.PASSWORD,
          isPassword: true,
          controller: widget.passwordController,
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        CustomLoginButton(
          onPressed: _registerWithEmail,
          text: _isLoading ? '...' : RegisterConstants.SIGN_UP,
          backgroundColor: ColorConstants.WHITE,
          textColor: ColorConstants.MAINCOLOR,
        ),
      ],
    );
  }
}
