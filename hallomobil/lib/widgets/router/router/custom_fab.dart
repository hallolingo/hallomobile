import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hallomobil/constants/color/color_constants.dart';

class CustomFloatingActionButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onPressed;
  final User? user; // Firebase Auth kullanıcısı
  final String? photoUrl; // Alternatif fotoğraf URL'si
  final String? userName; // Kullanıcı adı

  const CustomFloatingActionButton({
    super.key,
    required this.isSelected,
    required this.onPressed,
    this.user,
    this.photoUrl,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    // Öncelik sırası: user.photoURL > photoUrl > ismin ilk harfi
    final String? effectivePhotoUrl = user?.photoURL ?? photoUrl;
    final String displayName = user?.displayName ?? userName ?? '?';

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor:
          isSelected ? ColorConstants.MAINCOLOR : ColorConstants.WHITE,
      elevation: 2,
      shape: const CircleBorder(),
      child: effectivePhotoUrl != null
          ? CircleAvatar(
              backgroundImage: NetworkImage(effectivePhotoUrl),
              radius: 25,
            )
          : CircleAvatar(
              backgroundColor:
                  isSelected ? Colors.white : ColorConstants.MAINCOLOR,
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: isSelected ? ColorConstants.MAINCOLOR : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
}
