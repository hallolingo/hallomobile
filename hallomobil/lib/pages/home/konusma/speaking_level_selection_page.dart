import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/app_router.dart';

class SpeakingLevelSelectionPage extends StatefulWidget {
  final String selectedLanguage;
  final String category;

  const SpeakingLevelSelectionPage({
    super.key,
    required this.selectedLanguage,
    required this.category,
  });

  @override
  State<SpeakingLevelSelectionPage> createState() =>
      _SpeakingLevelSelectionPageState();
}

class _SpeakingLevelSelectionPageState extends State<SpeakingLevelSelectionPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<double>> _cardAnimations;

  final List<Map<String, dynamic>> _levels = [
    {
      'level': 'A1',
      'title': 'Başlangıç',
      'description': 'Temel kelimeler ve basit cümleler',
      'color': Colors.green,
      'icon': Icons.star_border,
    },
    {
      'level': 'A2',
      'title': 'Temel',
      'description': 'Günlük konuları anlamak',
      'color': Colors.lightGreen,
      'icon': Icons.star_half,
    },
    {
      'level': 'B1',
      'title': 'Orta',
      'description': 'Genel konuları kavramak',
      'color': Colors.orange,
      'icon': Icons.star,
    },
    {
      'level': 'B2',
      'title': 'Orta-İleri',
      'description': 'Karmaşık metinleri anlamak',
      'color': Colors.deepOrange,
      'icon': Icons.stars,
    },
    {
      'level': 'C1',
      'title': 'İleri',
      'description': 'Akademik ve profesyonel metinler',
      'color': Colors.red,
      'icon': Icons.military_tech,
    },
    {
      'level': 'C2',
      'title': 'Uzman',
      'description': 'Ana dil seviyesinde anlama',
      'color': Colors.purple,
      'icon': Icons.emoji_events,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    debugPrint(
        'Selected language in SpeakingLevelSelectionPage: ${widget.selectedLanguage}');
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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

    _cardAnimations = List.generate(_levels.length, (index) {
      final startTime = (index * 0.1).clamp(0.0, 0.8);
      final endTime = (0.3 + index * 0.1).clamp(0.1, 1.0);

      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _cardAnimationController,
          curve: Interval(
            startTime,
            endTime,
            curve: Curves.easeOutBack,
          ),
        ),
      );
    });
  }

  void _startAnimations() {
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardAnimationController.forward();
    });
  }

  void _navigateToExercise(String selectedLevel) {
    // Replace with the actual route for the specific exercise page
    Navigator.pushNamed(
      context,
      AppRouter.speakingExercise, // Placeholder route for exercise page
      arguments: {
        'selectedLanguage': widget.selectedLanguage,
        'selectedLevel': selectedLevel,
        'category': widget.category,
      },
    );
  }

  Widget _buildLevelCard(Map<String, dynamic> levelData, int index) {
    return AnimatedBuilder(
      animation: _cardAnimations[index],
      builder: (context, child) {
        final animationValue = _cardAnimations[index].value;
        return Transform.scale(
          scale: animationValue,
          child: Opacity(
            opacity: animationValue.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _navigateToExercise(levelData['level']),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    levelData['color'].withOpacity(0.1),
                    levelData['color'].withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: levelData['color'].withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          levelData['color'],
                          levelData['color'].withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: levelData['color'].withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      levelData['icon'],
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: levelData['color'],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                levelData['level'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              levelData['title'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.TEXT_COLOR,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          levelData['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: ColorConstants.TEXT_COLOR.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: levelData['color'],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
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
                            const SizedBox(height: 8),
                            const Text(
                              'Seviye Seçimi',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.WHITE,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_getCategoryTitle(widget.category)} - ${widget.selectedLanguage}',
                              style: TextStyle(
                                fontSize: 16,
                                color: ColorConstants.WHITE.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Seviyenizi seçin ve başlayın',
                              style: TextStyle(
                                fontSize: 14,
                                color: ColorConstants.WHITE.withOpacity(0.7),
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
              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ColorConstants.MAINCOLOR.withOpacity(0.1),
                            ColorConstants.MAINCOLOR.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ColorConstants.MAINCOLOR.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ColorConstants.MAINCOLOR,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Seviyenize uygun alıştırmalarla konuşma becerinizi geliştirin',
                              style: TextStyle(
                                fontSize: 14,
                                color: ColorConstants.TEXT_COLOR,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._levels.asMap().entries.map((entry) {
                    final index = entry.key;
                    final level = entry.value;
                    return _buildLevelCard(level, index);
                  }).toList(),
                  const SizedBox(height: 40),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryTitle(String category) {
    switch (category) {
      case 'pronunciation':
        return 'Telaffuz Alıştırması';
      case 'dialogue':
        return 'Diyalog Tamamlama';
      case 'question_response':
        return 'Soru Yanıtlama';
      case 'sentence_repetition':
        return 'Cümle Tekrarlama';
      default:
        return 'Konuşma Alıştırması';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }
}
