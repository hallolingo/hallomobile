import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hallomobil/app_router.dart';
import 'package:hallomobil/widgets/custom_snackbar.dart';
import 'package:country_flags/country_flags.dart';
import 'package:hallomobil/widgets/router/profile/settings/account_settings_card.dart';
import 'package:hallomobil/widgets/router/profile/settings/language_settings_card.dart';
import 'package:hallomobil/widgets/router/profile/settings/logout_button_widget.dart';
import 'package:hallomobil/widgets/router/profile/settings/notification_settings_card.dart';
import 'package:hallomobil/widgets/router/profile/settings/settings_header_widget.dart';

class SettingsPage extends StatefulWidget {
  final User? user;
  final Map<String, dynamic>? userData;

  const SettingsPage({
    super.key,
    this.user,
    this.userData,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _languages = [];
  String? _selectedLanguage;
  bool _isLoadingLanguages = false;
  bool _isEmailVerification = false;
  bool _isSMSVerification = false;

  @override
  void initState() {
    super.initState();
    debugPrint('SettingsPage init with userData: ${widget.userData}');
    _selectedLanguage = widget.userData?['selectedLanguage'] ?? 'Almanca';
    _isEmailVerification = widget.userData?['isEmailVerification'] ?? false;
    _isSMSVerification = widget.userData?['isSMSVerification'] ?? false;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _fetchLanguages();
    _fetchUserSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchLanguages() async {
    setState(() => _isLoadingLanguages = true);
    try {
      final snapshot = await _firestore.collection('languages').get();
      setState(() {
        _languages = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['name'],
                  'flagCode': doc['flagCode'],
                })
            .toList();
      });
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Diller yüklenirken hata oluştu: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLanguages = false);
      }
    }
  }

  Future<void> _fetchUserSettings() async {
    try {
      if (widget.user?.uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user!.uid)
            .get();

        if (doc.exists && mounted) {
          final data = doc.data();
          if (data != null) {
            setState(() {
              _isEmailVerification = data['isEmailVerification'] ?? false;
              _isSMSVerification = data['isSMSVerification'] ?? false;
              _selectedLanguage = data['selectedLanguage'] ?? _selectedLanguage;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching settings: $e');
    }
  }

  Future<void> _changeSelectedLanguage(String newLanguage) async {
    try {
      if (widget.user?.uid == null) {
        throw Exception('Kullanıcı kimliği bulunamadı.');
      }
      await _firestore.collection('users').doc(widget.user!.uid).update({
        'selectedLanguage': newLanguage,
      });
      setState(() => _selectedLanguage = newLanguage);
      showCustomSnackBar(
        context: context,
        message: 'Dil başarıyla değiştirildi: $newLanguage',
        isError: false,
      );
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'Dil değiştirilirken hata oluştu: $e',
        isError: true,
      );
    }
  }

  Future<void> _updateNotificationSetting(String field, bool value) async {
    try {
      if (widget.user?.uid == null) {
        throw Exception('Kullanıcı kimliği bulunamadı.');
      }
      await _firestore.collection('users').doc(widget.user!.uid).update({
        field: value,
      });
      setState(() {
        if (field == 'isEmailVerification') _isEmailVerification = value;
        if (field == 'isSMSVerification') _isSMSVerification = value;
      });
      showCustomSnackBar(
        context: context,
        message:
            '${field == 'isEmailVerification' ? 'E-posta' : 'SMS'} bildirimleri güncellendi',
        isError: false,
      );
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'Bildirim ayarları güncellenirken hata oluştu: $e',
        isError: true,
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppRouter.login, (route) => false);
                }
              } catch (e) {
                if (mounted) {
                  showCustomSnackBar(
                    context: context,
                    message: 'Çıkış yapılırken hata oluştu: ${e.toString()}',
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Çıkış Yap',
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hesabı Sil',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              // Implement account deletion logic
              Navigator.pop(context);
            },
            child: const Text('Sil',
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ayarlar',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            SettingsHeaderWidget(email: widget.user?.email),
            const SizedBox(height: 24),
            LanguageSettingsCard(
              selectedLanguage: _selectedLanguage,
              isLoadingLanguages: _isLoadingLanguages,
              languages: _languages,
              onLanguageTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) {
                    return DraggableScrollableSheet(
                      initialChildSize: 0.6,
                      minChildSize: 0.3,
                      maxChildSize: 0.9,
                      expand: false,
                      builder: (context, scrollController) {
                        return Container(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Container(
                                width: 40,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Dil Seçin',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.builder(
                                  controller: scrollController,
                                  itemCount: _languages.length,
                                  itemBuilder: (context, index) {
                                    final language = _languages[index];
                                    return ListTile(
                                      leading: language['flagCode'] != null
                                          ? CountryFlag.fromCountryCode(
                                              language['flagCode'],
                                              width: 40,
                                              height: 30,
                                            )
                                          : const Icon(Icons.language,
                                              color: Colors.black54),
                                      title: Text(
                                        language['name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      trailing:
                                          _selectedLanguage == language['name']
                                              ? const Icon(Icons.check_circle,
                                                  color: Colors.green)
                                              : null,
                                      onTap: () {
                                        _changeSelectedLanguage(
                                            language['name']);
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            NotificationSettingsCard(
              isEmailVerification: _isEmailVerification,
              isSMSVerification: _isSMSVerification,
              onEmailChanged: (value) =>
                  _updateNotificationSetting('isEmailVerification', value),
              onSMSChanged: (value) =>
                  _updateNotificationSetting('isSMSVerification', value),
            ),
            const SizedBox(height: 16),
            AccountSettingsCard(
              onChangePassword: () {},
              onDeleteAccount: _showDeleteAccountDialog,
            ),
            const SizedBox(height: 24),
            LogoutButtonWidget(onLogout: _showLogoutDialog),
          ],
        ),
      ),
    );
  }
}
