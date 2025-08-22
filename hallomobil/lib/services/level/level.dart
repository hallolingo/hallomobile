import 'package:cloud_firestore/cloud_firestore.dart';

class LevelService {
  final FirebaseFirestore _firestore;

  LevelService({required FirebaseFirestore firestore}) : _firestore = firestore;

  Future<void> updateSkillProgress({
    required String userId,
    required String language,
    required String skill,
    required double newProgress,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final doc = await userRef.get();

      if (!doc.exists) throw Exception('Kullanıcı bulunamadı');

      final data = doc.data()!;
      final languages = data['languages'] as Map<String, dynamic>;

      if (!languages.containsKey(language)) {
        throw Exception('Dil bulunamadı');
      }

      final langData = languages[language] as Map<String, dynamic>;
      final levelData = langData['level'] as Map<String, dynamic>;
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
      await userRef.update({
        'languages.$language.level': {
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

  Future<void> addNewLanguage(String userId, String language) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'languages.$language': {
          'level': {
            'currentLevel': 'beginner',
            'progress': 0.0,
            'skills': {
              'reading': {'progress': 0.0, 'lastPracticed': null},
              'writing': {'progress': 0.0, 'lastPracticed': null},
              'listening': {'progress': 0.0, 'lastPracticed': null},
              'words': {'progress': 0.0, 'lastPracticed': null},
            },
          },
          'createdAt': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      throw Exception('Dil eklenirken hata oluştu: $e');
    }
  }

  // Aktif dil değiştirme fonksiyonu
  Future<void> changeSelectedLanguage(String userId, String newLanguage) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'selectedLanguage': newLanguage});
    } catch (e) {
      throw Exception('Aktif dil değiştirilirken hata oluştu: $e');
    }
  }

  // Kullanıcının dillerini getirme fonksiyonu
  Future<List<String>> getUserLanguages(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data == null || !data.containsKey('languages')) {
        return [];
      }
      return (data['languages'] as Map).keys.cast<String>().toList();
    } catch (e) {
      throw Exception('Diller getirilirken hata oluştu: $e');
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
