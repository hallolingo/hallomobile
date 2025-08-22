import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpeakingPage extends StatefulWidget {
  final String selectedLanguage;

  const SpeakingPage({super.key, required this.selectedLanguage});

  @override
  State<SpeakingPage> createState() => _SpeakingPageState();
}

class _SpeakingPageState extends State<SpeakingPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    debugPrint('Selected language in SpeakingPage: ${widget.selectedLanguage}');
    _checkAndShowDialog(); // Diyalogu kontrol et ve göster
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

  // Diyalogu kontrol et ve göster
  Future<void> _checkAndShowDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShownDialog = prefs.getBool('hasShownSpeakingDialog') ?? false;

      if (!hasShownDialog) {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ColorConstants.WHITE,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.MAINCOLOR.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon ve başlık
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ColorConstants.MAINCOLOR,
                            ColorConstants.SECONDARY_COLOR,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.translate,
                        color: ColorConstants.WHITE,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Başlık
                    const Text(
                      'Çeviri Dili Kurulumu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.TEXT_COLOR,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Ana mesaj
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorConstants.MAINCOLOR.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ColorConstants.MAINCOLOR.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: ColorConstants.MAINCOLOR,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.info_outline,
                                  color: ColorConstants.WHITE,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Önemli Bilgi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: ColorConstants.MAINCOLOR,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                color: ColorConstants.TEXT_COLOR,
                                height: 1.5,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Telefonunuzdan ',
                                ),
                                const TextSpan(
                                  text: 'Translate (Çeviri)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: ColorConstants.MAINCOLOR,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' uygulamasına girin ve oradan ',
                                ),
                                TextSpan(
                                  text: '${widget.selectedLanguage}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: ColorConstants.MAINCOLOR,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' dilini indirin.',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Aksi takdirde HALLOLINGO konuşmalarınızı anlayamayacaktır.',
                            style: TextStyle(
                              fontSize: 13,
                              color: ColorConstants.TEXT_COLOR,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Alt bilgi
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.green.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Eğer dil zaten yüklü ise bir şey yapmanıza gerek yoktur.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buton
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ColorConstants.MAINCOLOR,
                            ColorConstants.SECONDARY_COLOR,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: ColorConstants.MAINCOLOR.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            Navigator.of(context).pop();
                            await prefs.setBool('hasShownSpeakingDialog', true);
                          },
                          child: const Center(
                            child: Text(
                              'Anladım',
                              style: TextStyle(
                                color: ColorConstants.WHITE,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
    } catch (e) {
      debugPrint('SharedPreferences hatası: $e');
      // Fallback olarak diyaloğu gösterme (isteğe bağlı)
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

  void _navigateToLevelSelection(String category) {
    Navigator.pushNamed(
      context,
      AppRouter.speakingLevelSelection,
      arguments: {
        'selectedLanguage': widget.selectedLanguage,
        'category': category,
      },
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
                              'Konuşma Alıştırmaları',
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
                                    Icons.mic,
                                    color: ColorConstants.WHITE,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Konuşma Seçenekleri',
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
                              icon: Icons.mic,
                              title: 'Telaffuz Alıştırması',
                              subtitle: 'Kelime telaffuzlarını öğren',
                              onTap: () =>
                                  _navigateToLevelSelection('pronunciation'),
                              color: ColorConstants.MAINCOLOR,
                            ),
                            const SizedBox(height: 8),
                            _buildSettingItem(
                              icon: Icons.chat,
                              title: 'Diyalog Tamamlama',
                              subtitle: 'Diyalogları tamamla',
                              onTap: () =>
                                  _navigateToLevelSelection('dialogue'),
                              color: ColorConstants.MAINCOLOR,
                            ),
                            const SizedBox(height: 8),
                            _buildSettingItem(
                              icon: Icons.question_answer,
                              title: 'Soru Yanıtlama',
                              subtitle: 'Sorulara sözlü yanıt ver',
                              onTap: () => _navigateToLevelSelection(
                                  'question_response'),
                              color: ColorConstants.MAINCOLOR,
                            ),
                            const SizedBox(height: 8),
                            _buildSettingItem(
                              icon: Icons.repeat,
                              title: 'Cümle Tekrarlama',
                              subtitle: 'Cümleleri tekrar ederek öğren',
                              onTap: () => _navigateToLevelSelection(
                                  'sentence_repetition'),
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
