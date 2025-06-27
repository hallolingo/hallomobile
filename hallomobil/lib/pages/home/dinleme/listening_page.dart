import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/app_router.dart';

class ListeningPage extends StatefulWidget {
  final String selectedLanguage;

  const ListeningPage({super.key, required this.selectedLanguage});

  @override
  State<ListeningPage> createState() => _ListeningPageState();
}

class _ListeningPageState extends State<ListeningPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();

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

    _cardAnimations = List.generate(1, (index) {
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

  void _navigateToFillBlank() async {
    Navigator.pushNamed(
      context,
      AppRouter.levelSelection, // Navigate to LevelSelectionPage
      arguments: widget.selectedLanguage,
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
                expandedHeight: 110,
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
                              'Dinleme Alıştırmaları',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.WHITE,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Seçili Dil: ${widget.selectedLanguage}',
                              style: TextStyle(
                                fontSize: 14,
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
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildModernCard(
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
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.headset,
                                    color: ColorConstants.WHITE,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Dinleme Seçenekleri',
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
                              icon: Icons.question_answer,
                              title: 'Sorular',
                              subtitle: 'Dinleme soruları çöz',
                              onTap: () {},
                              color: ColorConstants.MAINCOLOR,
                            ),
                            const SizedBox(height: 8),
                            _buildSettingItem(
                              icon: Icons.format_list_bulleted,
                              title: 'Kelimeler',
                              subtitle: 'Kelime alıştırmaları yap',
                              onTap: () {},
                              color: ColorConstants.MAINCOLOR,
                            ),
                            const SizedBox(height: 8),
                            _buildSettingItem(
                              icon: Icons.check_circle,
                              title: 'Doğru/Yanlış',
                              subtitle: 'Doğru yanlış testi yap',
                              onTap: () {},
                              color: ColorConstants.MAINCOLOR,
                            ),
                            const SizedBox(height: 8),
                            _buildSettingItem(
                              icon: Icons.edit,
                              title: 'Boşluk Doldurma',
                              subtitle: 'Boşluk doldurma soruları çöz',
                              onTap: _navigateToFillBlank,
                              color: ColorConstants.MAINCOLOR,
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
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
