import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final http.Client httpClient = http.Client();

  Future<void> sendVerificationCode(String email) async {
    try {
      final code = _generateRandomCode();

      // Firestore'a kodu kaydet
      await _firestore.collection('verificationCodes').add({
        'email': email,
        'code': code,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Firebase Function'ını çağır
      final functionUrl =
          'https://europe-west3-hallolingo-739a8.cloudfunctions.net/sendVerificationEmail';
      final response = await httpClient.post(
        Uri.parse(functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'code': code}),
      );

      if (response.statusCode != 200) {
        throw Exception('Doğrulama kodu gönderilemedi');
      }
    } catch (e) {
      throw Exception('Hata: ${e.toString()}');
    }
  }

  String _generateRandomCode() {
    return (100000 + Random().nextInt(900000)).toString();
  }

  Future<void> verifyCode(String email, String code) async {
    final snapshot = await _firestore
        .collection('verificationCodes')
        .where('email', isEqualTo: email)
        .where('code', isEqualTo: code)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('Geçersiz doğrulama kodu');
    }
    await snapshot.docs.first.reference.delete();
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String verificationCode,
  }) async {
    // Kodu doğrula
    await verifyCode(email, verificationCode);

    // Kullanıcıyı oluştur
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Firestore'a kullanıcı bilgilerini kaydet
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return userCredential;
  }
}
