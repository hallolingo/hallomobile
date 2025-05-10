import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VerificationService {
  final FirebaseFirestore _firestore;

  VerificationService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  Future<void> sendVerificationCode(String email) async {
    final generatedCode = _generateRandomCode();
    final now = DateTime.now();

    // Firestore'a doğrulama kodunu kaydet
    await _firestore.collection('verificationCodes').doc(email).set({
      'code': generatedCode,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(Duration(minutes: 5))),
    });

    // E-posta ile doğrulama kodunu gönder
    await _sendEmailWithCode(email, generatedCode);
  }

  Future<bool> verifyCode(String email, String code) async {
    final doc =
        await _firestore.collection('verificationCodes').doc(email).get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final correctCode = data['code'] as String;
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();

    if (DateTime.now().isAfter(expiresAt)) {
      await doc.reference.delete();
      return false;
    }

    return code == correctCode;
  }

  String _generateRandomCode() {
    return (100000 + Random().nextInt(900000)).toString();
  }

  Future<void> _sendEmailWithCode(String email, String code) async {
    const url = 'https://sendverificationemail-m5eamff7na-uc.a.run.app';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'code': code,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('E-posta gönderilemedi: ${response.body}');
      }
    } catch (e) {
      throw Exception('E-posta gönderiminde hata: $e');
    }
  }
}
