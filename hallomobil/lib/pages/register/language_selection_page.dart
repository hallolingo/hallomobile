import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/services.dart';
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

class _LanguageSelectionPageState extends State<LanguageSelectionPage>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedLanguage;
  bool _isLoading = false;
  List<Map<String, dynamic>> _languages = [];

  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _cardAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    _fetchLanguages();

    // Page animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
    ));

    _logoAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    // Card animation setup
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _cardAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _cardAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchLanguages() async {
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
                'words': {'progress': 0.0, 'lastPracticed': null},
              },
            },
            'createdAt': FieldValue.serverTimestamp(),
          }
        },
      });

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

  Widget _buildGlassmorphicCard({
    required Widget child,
    EdgeInsets? margin,
  }) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_cardAnimation.value * 0.2),
          child: Opacity(
            opacity: _cardAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin:
            margin ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.MAINCOLOR.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: -5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = true,
  }) {
    return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  colors: [
                    ColorConstants.MAINCOLOR,
                    ColorConstants.SECONDARY_COLOR,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: ColorConstants.MAINCOLOR.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      text,
                      style: TextStyle(
                        color:
                            isPrimary ? Colors.white : ColorConstants.MAINCOLOR,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorConstants.SECONDARY_COLOR.withOpacity(0.1),
              Colors.white,
              ColorConstants.MAINCOLOR.withOpacity(0.05),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Modern Header

                  // Content
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _buildGlassmorphicCard(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Card Header
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
                                        'Dil Seçimi',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: ColorConstants.TEXT_COLOR,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Instruction Text
                                  Text(
                                    'Hangi dili öğrenmek istiyorsunuz?',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: ColorConstants.MAINCOLOR,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Size en uygun olan dili seçerek öğrenme yolculuğunuza başlayın.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: ColorConstants.TEXT_COLOR
                                          .withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  // Language List
                                  _languages.isEmpty
                                      ? Center(
                                          child: CircularProgressIndicator(
                                            color: ColorConstants.MAINCOLOR,
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: _languages.length,
                                          itemBuilder: (context, index) {
                                            final language = _languages[index];
                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedLanguage =
                                                      language['name'];
                                                });
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 12),
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: _selectedLanguage ==
                                                          language['name']
                                                      ? ColorConstants.MAINCOLOR
                                                          .withOpacity(0.1)
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: _selectedLanguage ==
                                                            language['name']
                                                        ? ColorConstants
                                                            .MAINCOLOR
                                                        : Colors.grey
                                                            .withOpacity(0.3),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.05),
                                                      blurRadius: 10,
                                                      offset:
                                                          const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    language['flagCode'] != null
                                                        ? CountryFlag
                                                            .fromCountryCode(
                                                            language[
                                                                'flagCode'],
                                                            width: 40,
                                                            height: 30,
                                                          )
                                                        : const Icon(
                                                            Icons.language,
                                                            color:
                                                                ColorConstants
                                                                    .MAINCOLOR,
                                                          ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: Text(
                                                        language['name'],
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: ColorConstants
                                                              .TEXT_COLOR,
                                                        ),
                                                      ),
                                                    ),
                                                    if (_selectedLanguage ==
                                                        language['name'])
                                                      Icon(
                                                        Icons.check_circle,
                                                        color: ColorConstants
                                                            .MAINCOLOR,
                                                        size: 24,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                  const SizedBox(height: 24),
                                  // Continue Button
                                  _buildGradientButton(
                                    text: 'DEVAM ET',
                                    onPressed: _saveLanguageSelection,
                                    isPrimary: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
