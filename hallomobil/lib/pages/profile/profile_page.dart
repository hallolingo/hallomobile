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
    with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _levelData;
  late Map<String, dynamic> _skills;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
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
        return 'Başlangıç'; // Default to Başlangıç if level is unknown
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch selected language and level data
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
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Fetch available languages
    _fetchLanguages();
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

      // Update local data
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap'),
        content:
            const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'İptal',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
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
                    message: 'Çıkış yapılırken hata oluştu: ${e.toString()}',
                    isError: true,
                  );
                }
              }
            },
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
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
    final String? email = widget.user?.email;
    final String currentLevel =
        getTurkishLevel(_levelData['currentLevel']).toUpperCase();
    final double progress = (_levelData['progress'] ?? 0.0) / 100;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColorConstants.MAINCOLOR,
                        ColorConstants.MAINCOLOR
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: ProfileHeaderWidget(
                      userName: userName,
                      photoUrl: photoUrl,
                      initial: initial,
                      email: email,
                      currentLevel: currentLevel,
                      onLanguageTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) {
                            return Container(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Dil Seçin',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Flexible(
                                    child: ListView.builder(
                                      shrinkWrap: true,
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
                                              : const Icon(Icons.language),
                                          title: Text(
                                            language['name'],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                          trailing: _selectedLanguage ==
                                                  language['name']
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
                      isLoadingLanguages: _isLoadingLanguages,
                      languages: _languages,
                      selectedLanguage: _selectedLanguage,
                    ),
                  ),
                ),
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    // Fixed: Extract userData properly and convert to Map<String, dynamic>
                    Map<String, dynamic>? userDataMap;
                    if (widget.userData != null && widget.userData!.exists) {
                      userDataMap =
                          widget.userData!.data() as Map<String, dynamic>;
                    }

                    Navigator.pushNamed(
                      context,
                      AppRouter.settingsPage,
                      arguments: {
                        'user': widget.user,
                        'userData': userDataMap,
                      },
                    );
                  },
                ),
              ],
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LevelProgressWidget(
                        progress: progress,
                        currentLevel: currentLevel,
                      ),
                      const SizedBox(height: 16),
                      SkillsProgressWidget(skills: _skills),
                      const SizedBox(height: 16),
                      AccountActionsWidget(
                        onEditProfile: () {
                          // Navigate to profile edit page
                        },
                        onLogout: _showLogoutDialog,
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorConstants.MAINCOLOR,
        child: const Icon(Icons.edit),
        onPressed: () {
          // Navigate to profile edit page
        },
      ),
    );
  }
}
