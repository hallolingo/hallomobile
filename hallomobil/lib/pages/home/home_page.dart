import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/constants/home/home_constants.dart';
import 'package:hallomobil/widgets/router/home/app_bar_points.dart';
import 'package:hallomobil/widgets/router/home/language_level_card.dart';
import 'package:hallomobil/widgets/router/home/lesson_progress_card.dart';
import 'package:hallomobil/widgets/router/home/section_title.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> lessons = [
      {'title': 'Gramer', 'progress': 0.48},
      {'title': 'Okuma', 'progress': 0.75},
      {'title': 'Konuşma', 'progress': 0.92},
      {'title': 'Dinle ve Bul', 'progress': 0.57},
    ];

    return Scaffold(
      backgroundColor: ColorConstants.WHITE,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ColorConstants.WHITE,
        title: Image.asset(
          HomeConstants.APPBARLOGO,
          width: MediaQuery.of(context).size.width * 0.5,
        ),
        centerTitle: false,
        actions: const [AppBarPoints(points: 2400)],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const LanguageLevelCard(
              level: 'Başlangıç',
              imagePath: 'assets/logo/logo.png',
            ),
            SizedBox(height: MediaQuery.of(context).size.width * 0.05),
            const SectionTitle(title: 'Ders Detayları'),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
              ),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: lessons.map((lesson) {
                  return LessonProgressCard(
                    title: lesson['title'],
                    progress: lesson['progress'],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
