import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hallomobil/widgets/loginAndRegister/google/custom_google_picker.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  GoogleAuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _auth = auth,
        _firestore = firestore,
        _storage = storage;

  Future<UserCredential?> signInWithGoogle({BuildContext? context}) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
        hostedDomain: '',
      );

      // Get current account if exists
      GoogleSignInAccount? currentAccount;
      try {
        currentAccount = await googleSignIn.signInSilently();
      } catch (e) {
        // Silent sign-in failed, proceed with normal flow
      }

      // Create typed list of accounts
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

      await _saveUserDataToFirestore(userCredential.user!, selectedAccount);

      return userCredential;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  // Diğer metodlar aynı kalabilir...
  Future<void> _saveUserDataToFirestore(
      User firebaseUser, GoogleSignInAccount googleUser) async {
    final String? photoUrl =
        await _uploadProfilePhoto(googleUser.photoUrl, firebaseUser.uid);

    final userData = {
      'uid': firebaseUser.uid,
      'email': firebaseUser.email,
      'name': googleUser.displayName ?? 'Kullanıcı',
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

    await _firestore.collection('users').doc(firebaseUser.uid).set(userData);
  }

  Future<String?> _uploadProfilePhoto(String? photoUrl, String userId) async {
    if (photoUrl == null) return null;

    try {
      final http.Response response = await http.get(Uri.parse(photoUrl));
      final bytes = response.bodyBytes;

      final random = Random();
      final String fileName = 'profile_${random.nextInt(10000)}.jpg';

      final Reference ref = _storage.ref('profilePhotos/$userId/$fileName');
      final UploadTask uploadTask = ref.putData(bytes);
      final TaskSnapshot snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Profil fotoğrafı yükleme hatası: $e');
    }
  }
}
