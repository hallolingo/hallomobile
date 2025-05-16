import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_flags/country_flags.dart';
import 'package:hallomobil/app_router.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/widgets/custom_snackbar.dart';

class LanguageSelectionPage extends StatefulWidget {
  final String userId;
  final String userEmail;

  const LanguageSelectionPage({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedLanguage;
  bool _isLoading = false;
  List<Map<String, dynamic>> _languages = [];

  @override
  void initState() {
    super.initState();
    _fetchLanguages();
  }

  Future<void> _fetchLanguages() async {
    try {
      final snapshot = await _firestore.collection('languages').get();
      setState(() {
        _languages = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
            'flagCode': doc['flagCode'], // Match Firestore structure
          };
        }).toList();
      });
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'Diller yüklenirken hata oluştu: $e',
        isError: true,
      );
    }
  }

  Future<void> _saveLanguageSelection() async {
    if (_selectedLanguage == null) {
      showCustomSnackBar(
        context: context,
        message: 'Lütfen bir dil seçin',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Kullanıcı verilerini güncelle
      await _firestore.collection('users').doc(widget.userId).update({
        'selectedLanguage': _selectedLanguage,
        'languages': {
          _selectedLanguage: {
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
            'createdAt': FieldValue.serverTimestamp(),
          }
        },
      });

      // Ana sayfaya yönlendir
      Navigator.pushReplacementNamed(context, AppRouter.router);
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'Dil seçimi kaydedilirken hata oluştu: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.WHITE,
      appBar: AppBar(
        title: const Text('Dil Seçimi'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hangi dili öğrenmek istiyorsunuz?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ColorConstants.MAINCOLOR,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _languages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _languages.length,
                      itemBuilder: (context, index) {
                        final language = _languages[index];
                        return Card(
                          elevation: 2,
                          color: ColorConstants.WHITE,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListTile(
                              leading: language['flagCode'] != null
                                  ? CountryFlag.fromCountryCode(
                                      language['flagCode'],
                                      width: 40,
                                      height: 30,
                                    )
                                  : const Icon(Icons.language),
                              title: Text(
                                language['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: _selectedLanguage == language['name']
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedLanguage = language['name'];
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveLanguageSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.MAINCOLOR,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'DEVAM ET',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
