import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';

class LanguageLevelCard extends StatelessWidget {
  final String language;
  final String level;
  final String? imagePath;
  final String userName;
  final double progress;

  const LanguageLevelCard({
    super.key,
    required this.language,
    required this.level,
    this.imagePath,
    required this.userName,
    required this.progress,
  });

  // Seviye metinlerini Türkçeleştiren yardımcı fonksiyon
  String _getTranslatedLevel(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return 'Başlangıç';
      case 'intermediate':
        return 'Orta';
      case 'advanced':
        return 'İleri';
      default:
        return level; // Bilinmeyen seviyeler olduğu gibi gösterilir
    }
  }

  @override
  Widget build(BuildContext context) {
    final translatedLevel = _getTranslatedLevel(level);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
      ),
      color: ColorConstants.MAINCOLOR,
      elevation: 2, // Gölgelendirme eklendi
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Köşeler yuvarlatıldı
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      ColorConstants.MAINCOLOR, // Daha canlı bir mavi
                  backgroundImage:
                      imagePath != null ? NetworkImage(imagePath!) : null,
                  child: imagePath == null
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$language Seviyeniz',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.WHITE,
                      ),
                    ),
                    Text(
                      '$translatedLevel', // Türkçeleştirilmiş seviye
                      style: TextStyle(
                        fontSize: 16,
                        color: ColorConstants.WHITE,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: ColorConstants.WHITE,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorConstants.WHITE,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
