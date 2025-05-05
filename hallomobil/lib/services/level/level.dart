import 'package:cloud_firestore/cloud_firestore.dart';

class LevelService {
  final FirebaseFirestore _firestore;

  LevelService({required FirebaseFirestore firestore}) : _firestore = firestore;

  Future<void> updateSkillProgress({
    required String userId,
    required String skill, // reading, writing, listening, grammar
    required double newProgress, // 0.0 - 100.0 arası
  }) async {
    try {
      // Önce mevcut kullanıcı verilerini al
      final doc = await _firestore.collection('users').doc(userId).get();
      final userData = doc.data()!;
      final levelData = userData['level'] as Map<String, dynamic>;
      final currentLevel = levelData['currentLevel'] as String;
      final skills = levelData['skills'] as Map<String, dynamic>;

      // Yeni progress değerini güncelle
      skills[skill] = {
        'progress': newProgress,
        'lastPracticed': FieldValue.serverTimestamp(),
      };

      // Tüm becerilerin ortalamasını hesapla
      double total = 0.0;
      skills.forEach((key, value) {
        total += value['progress'] ?? 0.0;
      });
      final averageProgress = total / skills.length;

      // Seviye geçiş kontrolü
      String newLevel = currentLevel;
      bool levelUp = false;

      if (averageProgress >= 100 && currentLevel == 'beginner') {
        newLevel = 'intermediate';
        levelUp = true;
      } else if (averageProgress >= 100 && currentLevel == 'intermediate') {
        newLevel = 'advanced';
        levelUp = true;
      }

      // Eğer seviye atlandıysa tüm becerileri sıfırla
      if (levelUp) {
        skills.forEach((key, value) {
          skills[key] = {
            'progress': 0.0,
            'lastPracticed': FieldValue.serverTimestamp(),
          };
        });
      }

      // Firestore'da güncelleme yap
      await _firestore.collection('users').doc(userId).update({
        'level': {
          'currentLevel': newLevel,
          'progress': levelUp ? 0.0 : averageProgress,
          'skills': skills,
        },
      });
    } catch (e) {
      throw Exception('Beceri güncelleme hatası: $e');
    }
  }

  Future<Map<String, dynamic>> getUserLevelData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()!['level'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Seviye bilgisi alınamadı: $e');
    }
  }

  // Seviye atlama kontrolü için yardımcı fonksiyon
  String getNextLevel(String currentLevel) {
    switch (currentLevel) {
      case 'beginner':
        return 'intermediate';
      case 'intermediate':
        return 'advanced';
      case 'advanced':
        return 'advanced'; // En üst seviyede daha fazla ilerleme yok
      default:
        return 'beginner';
    }
  }
}
