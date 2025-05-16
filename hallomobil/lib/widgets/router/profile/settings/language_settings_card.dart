import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';

class LanguageSettingsCard extends StatelessWidget {
  final String? selectedLanguage;
  final bool isLoadingLanguages;
  final List<Map<String, dynamic>> languages;
  final VoidCallback onLanguageTap;

  const LanguageSettingsCard({
    super.key,
    this.selectedLanguage,
    required this.isLoadingLanguages,
    required this.languages,
    required this.onLanguageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dil Ayarları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: isLoadingLanguages || languages.isEmpty
                  ? null
                  : onLanguageTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, color: Colors.black54),
                      const SizedBox(width: 8),
                      Text(
                        'Seçili Dil: ${selectedLanguage ?? 'Dil Seçin'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
