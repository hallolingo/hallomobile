import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';

class LoginPrompt extends StatelessWidget {
  final VoidCallback onTap;
  final String promptText;
  final String actionText;
  final Color promptColor;
  final Color actionTextColor;

  const LoginPrompt({
    super.key,
    required this.onTap,
    this.promptText = 'Zaten hesabınız var mı?',
    this.actionText = 'Giriş Yap',
    this.promptColor = Colors.grey,
    this.actionTextColor = ColorConstants.MAINCOLOR,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              color: promptColor,
              fontSize: 14,
            ),
            children: [
              TextSpan(text: '$promptText '),
              TextSpan(
                text: actionText,
                style: TextStyle(
                  color: actionTextColor,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
