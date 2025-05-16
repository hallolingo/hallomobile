import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/constants/home/home_constants.dart';
import 'package:hallomobil/widgets/router/home/app_bar_points.dart';
import 'package:hallomobil/widgets/router/home/language_level_card.dart';
import 'package:hallomobil/widgets/router/home/lesson_progress_card.dart';
import 'package:hallomobil/widgets/router/home/section_title.dart';

class HomePage extends StatelessWidget {
  final User? user;
  final DocumentSnapshot? userData;

  const HomePage({
    super.key,
    this.user,
    this.userData,
  });

  @override
  Widget build(BuildContext context) {
    // Kullanıcının seçili dilini al
    final String selectedLanguage = userData?['selectedLanguage'] ??
        'Almanca'; // Varsayılan bir dil, eğer yoksa
    final languages = userData?['languages'] as Map<String, dynamic>? ?? {};
    final languageData =
        languages[selectedLanguage] as Map<String, dynamic>? ?? {};
    final levelData = languageData['level'] as Map<String, dynamic>? ?? {};
    final skills = levelData['skills'] as Map<String, dynamic>? ?? {};

    // Kullanıcı fotoğraf URL'sini al (Firebase Auth'dan veya Firestore'dan)
    final String? photoUrl = user?.photoURL ?? userData?['photoUrl'];

    // Ders ilerlemelerini seçili dile göre al
    final List<Map<String, dynamic>> lessons = [
      {'title': 'Gramer', 'progress': skills['grammar']?['progress'] ?? 0.0},
      {'title': 'Okuma', 'progress': skills['reading']?['progress'] ?? 0.0},
      {'title': 'Konuşma', 'progress': skills['writing']?['progress'] ?? 0.0},
      {'title': 'Dinleme', 'progress': skills['listening']?['progress'] ?? 0.0},
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
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: ColorConstants.MAINCOLOR,
          statusBarIconBrightness: Brightness.dark,
        ),
        actions: [
          AppBarPoints(
            points: userData?['score'] ?? 0,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.width * 0.02),
            LanguageLevelCard(
              language: selectedLanguage, // Seçili dili göster
              level: levelData['currentLevel'] ?? 'Başlangıç',
              imagePath: photoUrl,
              userName: user?.displayName ?? userData?['name'] ?? 'Misafir',
              progress: levelData['progress'] ?? 0.0,
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
