import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hallomobil/services/verification/verification_service.dart';

class EmailAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final VerificationService _verificationService;

  EmailAuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required VerificationService verificationService,
  })  : _auth = auth,
        _firestore = firestore,
        _verificationService = verificationService;

  Future<void> sendVerificationCode(String email) async {
    await _verificationService.sendVerificationCode(email);
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String verificationCode,
  }) async {
    try {
      final isValid =
          await _verificationService.verifyCode(email, verificationCode);
      if (!isValid) {
        throw Exception('Geçersiz doğrulama kodu');
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _saveUserDataToFirestore(userCredential.user!, name);

      return userCredential;
    } catch (e) {
      throw Exception('Kayıt işlemi başarısız: $e');
    }
  }

  Future<void> _saveUserDataToFirestore(User user, String name) async {
    final userData = {
      'uid': user.uid,
      'email': user.email,
      'name': name,
      'photoUrl': null,
      'isPremium': false,
      'isEmailVerification': false,
      'isSMSVerification': false,
      'score': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'provider': 'email',
      'emailVerified': false,
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
    };

    await _firestore.collection('users').doc(user.uid).set(userData);
  }
}
