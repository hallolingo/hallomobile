import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String userName;
  final String? photoUrl;
  final String initial;
  final String? email;
  final String currentLevel;
  final VoidCallback onLanguageTap;
  final bool isLoadingLanguages;
  final List<Map<String, dynamic>> languages;
  final String? selectedLanguage;

  const ProfileHeaderWidget({
    super.key,
    required this.userName,
    this.photoUrl,
    required this.initial,
    this.email,
    required this.currentLevel,
    required this.onLanguageTap,
    required this.isLoadingLanguages,
    required this.languages,
    this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            backgroundColor: Colors.white,
            child: photoUrl == null
                ? Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 30,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email ?? 'E-posta bilgisi yok',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        currentLevel,
                        style: const TextStyle(color: ColorConstants.MAINCOLOR),
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                    ),
                    const SizedBox(width: 8),
                    LanguageSelectorWidget(
                      onTap: onLanguageTap,
                      isLoadingLanguages: isLoadingLanguages,
                      languages: languages,
                      selectedLanguage: selectedLanguage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LanguageSelectorWidget extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoadingLanguages;
  final List<Map<String, dynamic>> languages;
  final String? selectedLanguage;

  const LanguageSelectorWidget({
    super.key,
    required this.onTap,
    required this.isLoadingLanguages,
    required this.languages,
    this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoadingLanguages || languages.isEmpty ? null : onTap,
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedLanguage ?? 'Dil Seçin',
              style: const TextStyle(color: ColorConstants.MAINCOLOR),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down,
                color: ColorConstants.MAINCOLOR, size: 20),
          ],
        ),
        backgroundColor: Colors.white,
        side: BorderSide.none,
      ),
    );
  }
}
