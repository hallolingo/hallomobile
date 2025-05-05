import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  EmailAuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _saveUserDataToFirestore(userCredential.user!, name);

      return userCredential;
    } catch (e) {
      throw Exception('Email ile kayıt hatası: $e');
    }
  }

  Future<void> _saveUserDataToFirestore(User user, String name) async {
    final userData = {
      'uid': user.uid,
      'email': user.email,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'provider': 'email',
      'photoUrl': '',
      'score': 0,
      'level': {
        'currentLevel': 'beginner', // beginner, intermediate, advanced
        'progress': 0.0, // Genel ilerleme yüzdesi
        'skills': {
          'reading': {
            'progress': 0.0,
            'lastPracticed': null,
          },
          'writing': {
            'progress': 0.0,
            'lastPracticed': null,
          },
          'listening': {
            'progress': 0.0,
            'lastPracticed': null,
          },
          'grammar': {
            'progress': 0.0,
            'lastPracticed': null,
          },
        },
      },
    };

    await _firestore.collection('users').doc(user.uid).set(userData);
  }
}
