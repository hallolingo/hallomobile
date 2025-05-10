import 'package:flutter/material.dart';
import 'package:hallomobil/services/google/google_auth_service.dart';
import 'package:hallomobil/widgets/custom_snackbar.dart';
import 'package:provider/provider.dart';

class GoogleSignInButton extends StatelessWidget {
  final Function(String email)? onSuccess;
  final VoidCallback? onError;
  final double size;
  final Color backgroundColor;
  final double padding;
  final String imagePath;
  final BuildContext? context;

  const GoogleSignInButton({
    super.key,
    this.onSuccess,
    this.onError,
    this.size = 50,
    this.backgroundColor = Colors.white,
    this.padding = 8.0,
    required this.imagePath,
    this.context,
  });

  @override
  Widget build(BuildContext context) {
    final googleAuthService =
        Provider.of<GoogleAuthService>(context, listen: false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: () async {
          try {
            final userCredential = await googleAuthService.signInWithGoogle(
              context: this.context ?? context,
            );
            if (userCredential != null && userCredential.user != null) {
              final email = userCredential.user!.email;
              if (email != null && onSuccess != null) {
                onSuccess!(email); // Doğrulama sayfasına yönlendirme
              } else if (onError != null) {
                onError!();
              }
            } else if (onError != null) {
              onError!();
            }
          } catch (e) {
            if (onError != null) onError!();
            showCustomSnackBar(
              context: context,
              message: 'Google ile giriş yapılamadı: $e',
              isError: true,
            );
          }
        },
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          padding: EdgeInsets.all(padding),
          child: Image.asset(imagePath),
        ),
      ),
    );
  }
}
