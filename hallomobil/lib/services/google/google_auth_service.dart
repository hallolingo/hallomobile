import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hallomobil/services/verification/verification_service.dart';
import 'package:hallomobil/widgets/loginAndRegister/google/custom_google_picker.dart';

class GoogleAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final VerificationService _verificationService;

  GoogleAuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required VerificationService verificationService,
  })  : _auth = auth,
        _firestore = firestore,
        _storage = storage,
        _verificationService = verificationService;

  Future<UserCredential?> signInWithGoogle({BuildContext? context}) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
        hostedDomain: '',
      );

      GoogleSignInAccount? currentAccount;
      try {
        currentAccount = await googleSignIn.signInSilently();
      } catch (e) {}

      final List<GoogleSignInAccount> accounts = [];
      if (currentAccount != null) {
        accounts.add(currentAccount);
      }

      GoogleSignInAccount? selectedAccount;

      if (context != null) {
        selectedAccount = await showModalBottomSheet<GoogleSignInAccount>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => CustomGoogleAccountPicker(
            accounts: accounts,
            onAccountSelected: (account) => Navigator.pop(context, account),
            onAddAccount: () {
              Navigator.pop(context);
              return googleSignIn.signIn();
            },
          ),
        );
      } else {
        selectedAccount = await googleSignIn.signIn();
      }

      if (selectedAccount == null) return null;

      final auth = await selectedAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      await _verificationService.sendVerificationCode(selectedAccount.email);

      return userCredential;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<void> sendVerificationCode(String email) async {
    await _verificationService.sendVerificationCode(email);
  }

  Future<void> verifyGoogleUser(String email, String verificationCode) async {
    try {
      final isValid =
          await _verificationService.verifyCode(email, verificationCode);
      if (!isValid) {
        throw Exception('Geçersiz doğrulama kodu');
      }

      final user = _auth.currentUser;
      if (user != null) {
        final photoUrl = await _uploadProfilePhoto(user.photoURL, user.uid);
        final userData = {
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? 'Kullanıcı',
          'photoUrl': photoUrl,
          'score': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'google',
          'level': {
            'currentLevel': 'beginner',
            'progress': 0.0,
            'skills': {
              'reading': {'progress': 0.0, 'lastPracticed': null},
              'writing': {'progress': 0.0, 'lastPracticed': null},
              'listening': {'progress': 0.0, 'lastPracticed': null},
              'grammar': {'progress': 0.0, 'lastPracticed': null},
            },
          },
        };
        await _firestore.collection('users').doc(user.uid).set(userData);
      }
    } catch (e) {
      throw Exception('Doğrulama başarısız: $e');
    }
  }

  Future<String?> _uploadProfilePhoto(String? photoUrl, String userId) async {
    if (photoUrl == null) return null;
    // Fotoğraf yükleme işlemi burada uygulanabilir, ancak basitlik için null döndürüyoruz
    return photoUrl;
  }
}
