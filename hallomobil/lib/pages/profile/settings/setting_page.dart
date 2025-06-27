import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hallomobil/app_router.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/widgets/custom_snackbar.dart';
import 'package:country_flags/country_flags.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<double>> _cardAnimations;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _languages = [];
  String? _selectedLanguage;
  bool _isLoadingLanguages = false;
  bool _isEmailVerification = false;
  bool _isSMSVerification = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    // Güvenli veri kontrolü
    try {
      debugPrint('SettingsPage init with userData: ${widget.userData}');
      debugPrint('UserData keys: ${widget.userData?.keys.toList()}');

      // Güvenli başlangıç değerleri
      _selectedLanguage = _getInitialLanguage();
      _isEmailVerification = _getInitialEmailVerification();
      _isSMSVerification = _getInitialSMSVerification();

      debugPrint(
          'Initial values - Language: $_selectedLanguage, Email: $_isEmailVerification, SMS: $_isSMSVerification');
    } catch (e) {
      debugPrint('Error in initState: $e');
      // Varsayılan değerleri ayarla
      _selectedLanguage = 'Almanca';
      _isEmailVerification = false;
      _isSMSVerification = false;
    }

    // Animation setup - Profile page ile aynı
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Create staggered animations for cards
    _cardAnimations = List.generate(4, (index) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _cardAnimationController,
          curve: Interval(
            index * 0.15,
            0.5 + index * 0.15,
            curve: Curves.easeOutBack,
          ),
        ),
      );
    });

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardAnimationController.forward();
    });

    // Async işlemleri güvenli şekilde başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _fetchLanguages();
        _fetchUserSettings();
      }
    });
  }

  String _getInitialLanguage() {
    try {
      final userData = widget.userData;
      if (userData == null || userData.isEmpty) {
        debugPrint('UserData is null or empty, using default language');
        return 'Almanca';
      }

      final selectedLanguage = userData['selectedLanguage'];
      debugPrint('Selected language from userData: $selectedLanguage');
      return selectedLanguage?.toString() ?? 'Almanca';
    } catch (e) {
      debugPrint('Error getting initial language: $e');
      return 'Almanca';
    }
  }

  bool _getInitialEmailVerification() {
    try {
      final userData = widget.userData;
      if (userData == null || userData.isEmpty) return false;

      final emailVerification = userData['isEmailVerification'];
      debugPrint('Email verification from userData: $emailVerification');

      if (emailVerification is bool) {
        return emailVerification;
      } else if (emailVerification is String?) {
        return emailVerification?.toLowerCase() == 'true';
      }
      return false;
    } catch (e) {
      debugPrint('Error getting initial email verification: $e');
      return false;
    }
  }

  bool _getInitialSMSVerification() {
    try {
      final userData = widget.userData;
      if (userData == null || userData.isEmpty) return false;

      final smsVerification = userData['isSMSVerification'];
      debugPrint('SMS verification from userData: $smsVerification');

      if (smsVerification is bool) {
        return smsVerification;
      } else if (smsVerification is String?) {
        return smsVerification?.toLowerCase() == 'true';
      }
      return false;
    } catch (e) {
      debugPrint('Error getting initial SMS verification: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchLanguages() async {
    if (!mounted) return;

    setState(() => _isLoadingLanguages = true);

    try {
      final snapshot = await _firestore.collection('languages').get();
      if (mounted) {
        setState(() {
          _languages = snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'name': doc.get('name')?.toString() ?? 'Unknown',
              'flagCode': doc.get('flagCode')?.toString(),
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Language fetch error: $e');
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Diller yüklenirken hata oluştu',
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
    if (_isDisposed) return;

    try {
      if (widget.user?.uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user!.uid)
          .get();

      if (!_isDisposed && mounted && doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          setState(() {
            _isEmailVerification = data['isEmailVerification'] ?? false;
            _isSMSVerification = data['isSMSVerification'] ?? false;
            _selectedLanguage =
                data['selectedLanguage']?.toString() ?? _selectedLanguage;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user settings: $e');
    }
  }

  Future<void> _changeSelectedLanguage(String newLanguage) async {
    if (_isDisposed) return;

    try {
      if (widget.user?.uid == null) {
        throw Exception('Kullanıcı kimliği bulunamadı.');
      }

      await _firestore.collection('users').doc(widget.user!.uid).update({
        'selectedLanguage': newLanguage,
      });

      if (!_isDisposed && mounted) {
        setState(() => _selectedLanguage = newLanguage);
        showCustomSnackBar(
          context: context,
          message: 'Dil başarıyla değiştirildi: $newLanguage',
          isError: false,
        );
      }
    } catch (e) {
      debugPrint('Error changing language: $e');
      if (!_isDisposed && mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Dil değiştirilirken hata oluştu',
          isError: true,
        );
      }
    }
  }

  Future<void> _updateNotificationSetting(String field, bool value) async {
    if (_isDisposed) return;

    try {
      if (widget.user?.uid == null) {
        throw Exception('Kullanıcı kimliği bulunamadı.');
      }

      await _firestore.collection('users').doc(widget.user!.uid).update({
        field: value,
      });

      if (!_isDisposed && mounted) {
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
      }
    } catch (e) {
      debugPrint('Error updating notification setting: $e');
      if (!_isDisposed && mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Bildirim ayarları güncellenirken hata oluştu',
          isError: true,
        );
      }
    }
  }

  void _showLanguageBottomSheet() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLanguageBottomSheet(),
    );
  }

  Widget _buildLanguageBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: ColorConstants.WHITE,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColorConstants.MAINCOLOR,
                        ColorConstants.SECONDARY_COLOR
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.language,
                      color: ColorConstants.WHITE, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Dil Seçin',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.TEXT_COLOR,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Languages list
          Expanded(
            child: _languages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          ColorConstants.MAINCOLOR),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    itemCount: _languages.length,
                    itemBuilder: (context, index) {
                      final language = _languages[index];
                      final isSelected = _selectedLanguage == language['name'];

                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              final languageName = language['name'];
                              if (languageName != null) {
                                _changeSelectedLanguage(languageName);
                                Navigator.pop(context);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ColorConstants.ACCENT_COLOR
                                        .withOpacity(0.3)
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? ColorConstants.MAINCOLOR
                                      : Colors.grey[200]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 35,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _buildLanguageFlag(
                                          language['flagCode']),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      language['name'] ?? 'Bilinmeyen Dil',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? ColorConstants.MAINCOLOR
                                            : ColorConstants.TEXT_COLOR,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: ColorConstants.MAINCOLOR,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: ColorConstants.WHITE,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildLogoutDialog(),
    );
  }

  Widget _buildLogoutDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ColorConstants.WHITE,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.red[400],
                size: 32,
              ),
            ),

            const SizedBox(height: 20),

            // Title
            const Text(
              'Çıkış Yap',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ColorConstants.TEXT_COLOR,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: ColorConstants.TEXT_COLOR.withOpacity(0.7),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: const Text(
                      'İptal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.TEXT_COLOR,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRouter.login,
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        debugPrint('Error signing out: $e');
                        if (mounted) {
                          showCustomSnackBar(
                            context: context,
                            message: 'Çıkış yapılırken hata oluştu',
                            isError: true,
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: ColorConstants.WHITE,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Çıkış Yap',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ColorConstants.WHITE,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red[600],
                  size: 32,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              const Text(
                'Hesabı Sil',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.TEXT_COLOR,
                ),
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz ve tüm verileriniz kalıcı olarak silinecektir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: ColorConstants.TEXT_COLOR.withOpacity(0.7),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: const Text(
                        'İptal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.TEXT_COLOR,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Implement account deletion logic
                        Navigator.pop(context);
                        showCustomSnackBar(
                          context: context,
                          message: 'Hesap silme özelliği henüz aktif değil',
                          isError: true,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: ColorConstants.WHITE,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Hesabı Sil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageFlag(String? flagCode) {
    if (flagCode == null || flagCode.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.language, size: 20),
      );
    }

    try {
      return CountryFlag.fromCountryCode(
        flagCode,
        width: 50,
        height: 35,
      );
    } catch (e) {
      debugPrint('Error loading flag for code $flagCode: $e');
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.language, size: 20),
      );
    }
  }

  Widget _buildModernCard({
    required Widget child,
    required int animationIndex,
    EdgeInsets? margin,
  }) {
    return AnimatedBuilder(
      animation:
          _cardAnimations[animationIndex.clamp(0, _cardAnimations.length - 1)],
      builder: (context, child) {
        final animationValue =
            _cardAnimations[animationIndex.clamp(0, _cardAnimations.length - 1)]
                .value;
        return Transform.scale(
          scale: animationValue,
          child: Opacity(
            opacity: animationValue.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: margin ?? const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: ColorConstants.WHITE,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.MAINCOLOR.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      isDestructive ? Colors.red[50] : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDestructive ? color : ColorConstants.TEXT_COLOR,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorConstants.TEXT_COLOR.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: ColorConstants.TEXT_COLOR.withOpacity(0.4),
                    size: 16,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.TEXT_COLOR,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorConstants.TEXT_COLOR.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ColorConstants.MAINCOLOR,
            activeTrackColor: ColorConstants.MAINCOLOR.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userName =
        widget.user?.displayName ?? widget.userData?['name'] ?? 'Misafir';
    final String? photoUrl =
        widget.user?.photoURL ?? widget.userData?['photoUrl'];
    final String initial = userName.isNotEmpty ? userName[0] : 'M';
    final String? email = widget.user?.email ?? 'Bilinmeyen E-posta';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              // Modern Header - Profile page tarzında
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: ColorConstants.MAINCOLOR,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColorConstants.MAINCOLOR,
                          ColorConstants.SECONDARY_COLOR,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            // Profile Picture
                            Hero(
                              tag: 'profile_picture',
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ColorConstants.WHITE,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 15,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 37,
                                  backgroundImage: photoUrl != null
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  backgroundColor: ColorConstants.WHITE,
                                  child: photoUrl == null
                                      ? Text(
                                          initial,
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: ColorConstants.MAINCOLOR,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // User Name
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.WHITE,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Email
                            Text(
                              email!,
                              style: TextStyle(
                                fontSize: 12,
                                color: ColorConstants.WHITE.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: ColorConstants.WHITE),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // Content
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Language Settings Card
                          _buildModernCard(
                            animationIndex: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              ColorConstants.MAINCOLOR,
                                              ColorConstants.SECONDARY_COLOR,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.language,
                                          color: ColorConstants.WHITE,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Dil Ayarları',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: ColorConstants.TEXT_COLOR,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildSettingItem(
                                    icon: Icons.translate,
                                    title: 'Uygulama Dili',
                                    subtitle: 'Arayüz dilini değiştirin',
                                    onTap: _showLanguageBottomSheet,
                                    color: ColorConstants.MAINCOLOR,
                                    trailing: _isLoadingLanguages
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                      ColorConstants.MAINCOLOR),
                                            ),
                                          )
                                        : Text(
                                            _selectedLanguage ?? 'Seçili Dil',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: ColorConstants.MAINCOLOR,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Notification Settings Card
                          _buildModernCard(
                            animationIndex: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              ColorConstants.SECONDARY_COLOR,
                                              ColorConstants.ACCENT_COLOR,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.notifications,
                                          color: ColorConstants.WHITE,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Bildirim Ayarları',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: ColorConstants.TEXT_COLOR,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildSwitchItem(
                                    icon: Icons.email,
                                    title: 'E-posta Bildirimleri',
                                    subtitle: 'E-posta ile bildirim al',
                                    value: _isEmailVerification,
                                    onChanged: (value) =>
                                        _updateNotificationSetting(
                                            'isEmailVerification', value),
                                    color: ColorConstants.SECONDARY_COLOR,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildSwitchItem(
                                    icon: Icons.sms,
                                    title: 'SMS Bildirimleri',
                                    subtitle: 'SMS ile bildirim al',
                                    value: _isSMSVerification,
                                    onChanged: (value) =>
                                        _updateNotificationSetting(
                                            'isSMSVerification', value),
                                    color: ColorConstants.SECONDARY_COLOR,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Account Settings Card
                          _buildModernCard(
                            animationIndex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              ColorConstants.ACCENT_COLOR,
                                              ColorConstants.MAINCOLOR,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.account_circle,
                                          color: ColorConstants.WHITE,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Hesap Ayarları',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: ColorConstants.TEXT_COLOR,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildSettingItem(
                                    icon: Icons.lock,
                                    title: 'Şifreyi Değiştir',
                                    subtitle: 'Hesap şifrenizi güncelleyin',
                                    onTap: () {
                                      showCustomSnackBar(
                                        context: context,
                                        message:
                                            'Şifre değiştirme özelliği henüz aktif değil',
                                        isError: true,
                                      );
                                    },
                                    color: ColorConstants.MAINCOLOR,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildSettingItem(
                                    icon: Icons.delete_forever,
                                    title: 'Hesabı Sil',
                                    subtitle: 'Hesabınızı kalıcı olarak silin',
                                    onTap: _showDeleteAccountDialog,
                                    color: Colors.red[600]!,
                                    isDestructive: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Logout Card
                          _buildModernCard(
                            animationIndex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.red[400]!,
                                              Colors.red[600]!,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.logout,
                                          color: ColorConstants.WHITE,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Çıkış Yap',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: ColorConstants.TEXT_COLOR,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildSettingItem(
                                    icon: Icons.logout,
                                    title: 'Oturumu Kapat',
                                    subtitle:
                                        'Hesabınızdan güvenli çıkış yapın',
                                    onTap: _showLogoutDialog,
                                    color: Colors.red[400]!,
                                    isDestructive: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 100), // Bottom spacing
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
