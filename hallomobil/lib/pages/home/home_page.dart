import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/constants/home/home_constants.dart';
import 'package:hallomobil/pages/home/dinleme/listening_page.dart';
import 'package:hallomobil/pages/home/kelime/list_categories_page.dart';
import 'package:hallomobil/pages/home/konusma/speaking_page.dart';
import 'package:hallomobil/pages/home/private_lesson_page.dart';
import 'package:hallomobil/widgets/router/home/app_bar_points.dart';
import 'package:hallomobil/widgets/router/home/language_level_card.dart';
import 'package:hallomobil/widgets/router/home/lesson_progress_card.dart';
import 'package:hallomobil/widgets/router/home/section_title.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final User? user;
  final DocumentSnapshot? userData;

  const HomePage({
    super.key,
    this.user,
    this.userData,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();

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

    // Show dialog on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLessonDialog();
      _checkAndShowLessonDialog();
    });
  }

  Future<void> _checkAndShowLessonDialog() async {
    final prefs = await SharedPreferences.getInstance();
    const dialogShownKey = 'lesson_dialog_shown';
    final bool dialogShown = prefs.getBool(dialogShownKey) ?? false;

    if (!dialogShown) {
      _showLessonDialog();
      await prefs.setBool(dialogShownKey, true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
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

  void _showLessonDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: ColorConstants.MAINCOLOR.withOpacity(0.9),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative elements
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),

                // Main content
                Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 15),

                      // Icon
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        'Özel Canlı Almanca Eğitimi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Description
                      const Text(
                        'Profesyonel eğitmenlerle birebir Almanca dersleri alın ve hızla ilerleyin!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Daha Sonra',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PrivateLessonsPage(user: widget.user),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: ColorConstants.MAINCOLOR,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Hemen Katıl',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Close button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String selectedLanguage =
        widget.userData?['selectedLanguage'] ?? 'Almanca';
    final languages =
        widget.userData?['languages'] as Map<String, dynamic>? ?? {};
    final languageData =
        languages[selectedLanguage] as Map<String, dynamic>? ?? {};
    final levelData = languageData['level'] as Map<String, dynamic>? ?? {};
    final skills = levelData['skills'] as Map<String, dynamic>? ?? {};

    final String? photoUrl =
        widget.user?.photoURL ?? widget.userData?['photoUrl'];
    final String userName =
        widget.user?.displayName ?? widget.userData?['name'] ?? 'Misafir';
    final String initial = userName.isNotEmpty ? userName[0] : 'M';

    final List<Map<String, dynamic>> lessons = [
      {'title': 'Kelime', 'progress': skills['words']?['progress'] ?? 0.0},
      {'title': 'Okuma', 'progress': skills['reading']?['progress'] ?? 0.0},
      {'title': 'Konuşma', 'progress': skills['writing']?['progress'] ?? 0.0},
      {'title': 'Dinleme', 'progress': skills['listening']?['progress'] ?? 0.0},
    ];

    return Scaffold(
      backgroundColor: ColorConstants.WHITE,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 95,
                floating: false,
                pinned: false,
                backgroundColor: ColorConstants.WHITE,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset(
                              HomeConstants.APPBARLOGO,
                              width: MediaQuery.of(context).size.width * 0.5,
                            ),
                            AppBarPoints(
                              points: widget.userData?['score'] ?? 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: ColorConstants.MAINCOLOR,
                  statusBarIconBrightness: Brightness.light,
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModernCard(
                          animationIndex: 0,
                          child: LanguageLevelCard(
                            language: selectedLanguage,
                            level: levelData['currentLevel'] ?? 'Başlangıç',
                            imagePath: photoUrl,
                            userName: userName,
                            progress: levelData['progress'] ?? 0.0,
                          ),
                        ),
                        _buildModernCard(
                          animationIndex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
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
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.school,
                                        color: ColorConstants.WHITE,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'Ders Detayları',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: ColorConstants.TEXT_COLOR,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.2,
                                  children: lessons.map((lesson) {
                                    return LessonProgressCard(
                                      title: lesson['title'],
                                      progress: lesson['progress'],
                                      onTap: lesson['title'] == 'Dinleme'
                                          ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ListeningPage(
                                                    selectedLanguage:
                                                        selectedLanguage,
                                                  ),
                                                ),
                                              );
                                            }
                                          : lesson['title'] == 'Konuşma'
                                              ? () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          SpeakingPage(
                                                        selectedLanguage:
                                                            selectedLanguage,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              : lesson['title'] == 'Kelime'
                                                  ? () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              WordCategoriesPage(
                                                            selectedLanguage:
                                                                selectedLanguage,
                                                            user: widget.user,
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  : null,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildModernCard(
                          animationIndex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
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
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.leaderboard,
                                        color: ColorConstants.WHITE,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'Liderlik Tablosu',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: ColorConstants.TEXT_COLOR,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildLeaderboard(),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildLeaderboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('score', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: ColorConstants.MAINCOLOR,
            ),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Liderlik tablosu yüklenirken hata oluştu',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Henüz liderlik tablosu verisi yok',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          );
        }

        final users = snapshot.data!.docs;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final userName = userData['name'] ?? 'Anonim';
              final userScore = userData['score'] ?? 0;
              final userPhoto = userData['photoUrl'];
              final isCurrentUser = userDoc.id == widget.user?.uid;

              return Container(
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? ColorConstants.MAINCOLOR.withOpacity(0.1)
                      : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _getRankColor(index),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        backgroundImage:
                            userPhoto != null ? NetworkImage(userPhoto) : null,
                        child: userPhoto == null
                            ? Icon(
                                Icons.person,
                                color: Colors.grey[600],
                                size: 20,
                              )
                            : null,
                      ),
                    ],
                  ),
                  title: Text(
                    userName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isCurrentUser ? FontWeight.bold : FontWeight.w500,
                      color: isCurrentUser
                          ? ColorConstants.MAINCOLOR
                          : Colors.black87,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ColorConstants.MAINCOLOR.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${userScore} puan',
                      style: const TextStyle(
                        color: ColorConstants.MAINCOLOR,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Altın
      case 1:
        return const Color(0xFFC0C0C0); // Gümüş
      case 2:
        return const Color(0xFFCD7F32); // Bronz
      default:
        return ColorConstants.MAINCOLOR;
    }
  }
}
