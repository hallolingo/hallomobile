import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';

class LessonProgressCard extends StatelessWidget {
  final String title;
  final double progress;
  final VoidCallback? onTap; // İsteğe bağlı onTap callback'i eklendi

  const LessonProgressCard({
    super.key,
    required this.title,
    required this.progress,
    this.onTap, // İsteğe bağlı parametre
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // onTap tetikleyici
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.MAINCOLOR.withAlpha((0.7 * 255).toInt()),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.MAINCOLOR,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tamamlanan ${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                // Background track
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Progress fill
                Container(
                  height: 8,
                  width: (MediaQuery.of(context).size.width * 0.43) * progress,
                  decoration: BoxDecoration(
                    color: ColorConstants.MAINCOLOR,
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [
                        ColorConstants.MAINCOLOR,
                        ColorConstants.MAINCOLOR.withAlpha((0.7 * 255).toInt()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
