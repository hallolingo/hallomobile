import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hallomobil/app_router.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/widgets/custom_snackbar.dart';
import 'package:country_flags/country_flags.dart';
import 'package:hallomobil/widgets/router/profile/account_actions_widget.dart';
import 'package:hallomobil/widgets/router/profile/level_progress_widget.dart';
import 'package:hallomobil/widgets/router/profile/profile_header_widget.dart';
import 'package:hallomobil/widgets/router/profile/skills_progress_widget.dart';

class ProfilePage extends StatefulWidget {
  final User? user;
  final DocumentSnapshot? userData;

  const ProfilePage({
    super.key,
    this.user,
    this.userData,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late Map<String, dynamic> _levelData;
  late Map<String, dynamic> _skills;
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<double>> _cardAnimations;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _languages = [];
  String? _selectedLanguage;
  bool _isLoadingLanguages = false;

  // Helper function to map English level names to Turkish
  String getTurkishLevel(String? englishLevel) {
    switch (englishLevel?.toLowerCase()) {
      case 'beginner':
        return 'Başlangıç';
      case 'intermediate':
        return 'Orta';
      case 'advanced':
        return 'İleri';
      default:
        return 'Başlangıç';
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.userData?['selectedLanguage'] ?? 'Almanca';
    final languages =
        widget.userData?['languages'] as Map<String, dynamic>? ?? {};
    final languageData =
        languages[_selectedLanguage] as Map<String, dynamic>? ?? {};
    _levelData = languageData['level'] as Map<String, dynamic>? ?? {};
    _skills = _levelData['skills'] as Map<String, dynamic>? ?? {};

    // Animation setup
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
    _cardAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _cardAnimationController,
          curve: Interval(
            index * 0.2,
            0.6 + index * 0.2,
            curve: Curves.easeOutBack,
          ),
        ),
      );
    });

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardAnimationController.forward();
    });

    _fetchLanguages();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchLanguages() async {
    setState(() => _isLoadingLanguages = true);
    try {
      final snapshot = await _firestore.collection('languages').get();
      setState(() {
        _languages = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
            'flagCode': doc['flagCode'],
          };
        }).toList();
      });
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'Diller yüklenirken hata oluştu: $e',
        isError: true,
      );
    } finally {
      setState(() => _isLoadingLanguages = false);
    }
  }

  Future<void> _changeSelectedLanguage(String newLanguage) async {
    try {
      await _firestore.collection('users').doc(widget.user?.uid).update({
        'selectedLanguage': newLanguage,
      });

      final languages =
          widget.userData?['languages'] as Map<String, dynamic>? ?? {};
      final languageData =
          languages[newLanguage] as Map<String, dynamic>? ?? {};
      setState(() {
        _selectedLanguage = newLanguage;
        _levelData = languageData['level'] as Map<String, dynamic>? ?? {};
        _skills = _levelData['skills'] as Map<String, dynamic>? ?? {};
      });

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

  void _showLanguageBottomSheet() {
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                        _changeSelectedLanguage(language['name']);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ColorConstants.ACCENT_COLOR.withOpacity(0.3)
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
                                child: language['flagCode'] != null
                                    ? CountryFlag.fromCountryCode(
                                        language['flagCode'],
                                        width: 50,
                                        height: 35,
                                      )
                                    : Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.language,
                                            size: 20),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                language['name'],
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
                        if (mounted) {
                          showCustomSnackBar(
                            context: context,
                            message:
                                'Çıkış yapılırken hata oluştu: ${e.toString()}',
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

  Map<String, dynamic>? _extractUserDataMap() {
    try {
      if (widget.userData == null || !widget.userData!.exists) {
        debugPrint('UserData is null or does not exist');
        return null;
      }

      final data = widget.userData!.data();
      debugPrint('UserData from Firestore: $data');
      debugPrint('UserData type: ${data.runtimeType}');

      if (data == null) {
        debugPrint('UserData.data() returned null');
        return null;
      }

      if (data is Map<String, dynamic>) {
        return {
          'selectedLanguage': data['selectedLanguage'] ?? 'Almanca',
          'languages': data['languages'] ?? {},
          'isEmailVerification': data['isEmailVerification'] ?? false,
          'isSMSVerification': data['isSMSVerification'] ?? false,
          'email': data['email'] ?? widget.user?.email ?? '',
          'name': data['name'] ?? 'Misafir',
          'uid': data['uid'] ?? widget.user?.uid ?? '',
          ...data,
        };
      } else {
        debugPrint(
            'UserData is not Map<String, dynamic>, it is ${data.runtimeType}');
        return null;
      }
    } catch (e) {
      debugPrint('Error extracting userData: $e');
      return null;
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
            opacity: animationValue.clamp(0.0, 1.0), // Burada clamp ekledik
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

  @override
  Widget build(BuildContext context) {
    final String userName =
        widget.user?.displayName ?? widget.userData?['name'] ?? 'Misafir';
    final String? photoUrl =
        widget.user?.photoURL ?? widget.userData?['photoUrl'];
    final String initial = userName.isNotEmpty ? userName[0] : 'M';
    final String? email = widget.user?.email;
    final String currentLevel =
        getTurkishLevel(_levelData['currentLevel']).toUpperCase();
    final double progress = (_levelData['progress'] ?? 0.0) / 100;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              // Modern Header
              SliverAppBar(
                expandedHeight: 280,
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
                            const SizedBox(height: 15),

                            // Profile Picture
                            Hero(
                              tag: 'profile_picture',
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ColorConstants.WHITE,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundImage: photoUrl != null
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  backgroundColor: ColorConstants.WHITE,
                                  child: photoUrl == null
                                      ? Text(
                                          initial,
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: ColorConstants.MAINCOLOR,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // User Name
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.WHITE,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Email
                            if (email != null)
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ColorConstants.WHITE.withOpacity(0.8),
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Language Selector
                            GestureDetector(
                              onTap: _showLanguageBottomSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorConstants.WHITE.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        ColorConstants.WHITE.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.language,
                                      color: ColorConstants.WHITE,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedLanguage ?? 'Dil Seç',
                                      style: const TextStyle(
                                        color: ColorConstants.WHITE,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: ColorConstants.WHITE,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                automaticallyImplyLeading: false,
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: ColorConstants.WHITE.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings_rounded,
                          color: ColorConstants.WHITE),
                      onPressed: () {
                        if (widget.user == null) {
                          debugPrint(
                              'User is null, cannot navigate to settings');
                          showCustomSnackBar(
                            context: context,
                            message: 'Kullanıcı bilgileri yüklenemedi',
                            isError: true,
                          );
                          return;
                        }

                        final userDataMap = _extractUserDataMap() ?? {};

                        Navigator.pushNamed(
                          context,
                          AppRouter.settingsPage,
                          arguments: {
                            'user': widget.user,
                            'userData': userDataMap,
                          },
                        ).catchError((error) {
                          debugPrint('Navigation error: $error');
                          if (mounted) {
                            showCustomSnackBar(
                              context: context,
                              message:
                                  'Ayarlar sayfasına geçiş sırasında hata oluştu',
                              isError: true,
                            );
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),

              // Content
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Level Progress Card
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
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.trending_up_rounded,
                                        color: ColorConstants.WHITE,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Seviye İlerlemen',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: ColorConstants.TEXT_COLOR,
                                            ),
                                          ),
                                          Text(
                                            'Mevcut Seviye: $currentLevel',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: ColorConstants.TEXT_COLOR
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Progress Bar
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'İlerleme',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: ColorConstants.TEXT_COLOR
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                        Text(
                                          '${(progress * 100).round()}%',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: ColorConstants.MAINCOLOR,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: ColorConstants.ACCENT_COLOR
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: progress,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                ColorConstants.MAINCOLOR,
                                                ColorConstants.SECONDARY_COLOR,
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
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

                        // Skills Card
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
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.psychology_rounded,
                                        color: ColorConstants.WHITE,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'Beceri İstatistiklerin',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: ColorConstants.TEXT_COLOR,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Skills Progress - You can customize this based on your SkillsProgressWidget
                                // Skills Progress - Düzeltilmiş versiyon
                                if (_skills.isNotEmpty)
                                  ..._skills.entries.map((skill) {
                                    // skill.value'yu doğru şekilde çıkar
                                    double skillProgress = 0.0;

                                    if (skill.value is num) {
                                      skillProgress =
                                          (skill.value as num).toDouble() / 100;
                                    } else if (skill.value
                                        is Map<String, dynamic>) {
                                      // Eğer skill.value bir Map ise, progress değerini çıkar
                                      skillProgress = ((skill.value as Map<
                                                  String,
                                                  dynamic>)['progress'] ??
                                              0.0) /
                                          100;
                                    } else {
                                      skillProgress = 0.0;
                                    }

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                skill.key,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: ColorConstants
                                                      .TEXT_COLOR
                                                      .withOpacity(0.8),
                                                ),
                                              ),
                                              Text(
                                                '${(skillProgress * 100).round()}%',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: ColorConstants
                                                      .SECONDARY_COLOR,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: skillProgress.clamp(
                                                  0.0,
                                                  1.0), // 0-1 arasında sınırla
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: ColorConstants
                                                      .SECONDARY_COLOR,
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList()
                                else
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.grey[400],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Henüz beceri verisi yok',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Account Actions Card
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
                                            ColorConstants.MAINCOLOR
                                                .withOpacity(0.7),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.manage_accounts_rounded,
                                        color: ColorConstants.WHITE,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'Hesap İşlemleri',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: ColorConstants.TEXT_COLOR,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Action Buttons
                                _buildActionButton(
                                  icon: Icons.edit_rounded,
                                  title: 'Profili Düzenle',
                                  subtitle: 'Kişisel bilgilerinizi güncelleyin',
                                  onTap: () {
                                    // Navigate to profile edit page
                                  },
                                  color: ColorConstants.MAINCOLOR,
                                ),

                                const SizedBox(height: 12),

                                _buildActionButton(
                                  icon: Icons.logout_rounded,
                                  title: 'Çıkış Yap',
                                  subtitle: 'Hesabınızdan güvenli çıkış yapın',
                                  onTap: _showLogoutDialog,
                                  color: Colors.red[400]!,
                                  isDestructive: true,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 100), // Bottom spacing for FAB
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red[50] : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDestructive ? Colors.red[200]! : color.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      isDestructive ? Colors.red[100] : color.withOpacity(0.1),
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
}
