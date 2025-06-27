import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hallomobil/app_router.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/data/models/video_model.dart';
import 'package:video_player/video_player.dart';
import 'package:country_flags/country_flags.dart';

class VideosPage extends StatefulWidget {
  const VideosPage({super.key});

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> with TickerProviderStateMixin {
  List<Map<String, String?>> _languages = [];
  String? _selectedLanguage;
  Map<String, VideoPlayerController?> _controllers = {};
  Map<String, String?> _videoErrors = {};
  Map<String, bool> _videoCacheStatus = {};
  bool _isDisposed = false;
  bool? _isPremium;
  bool _isLoadingPremiumStatus = true;

  // Animation Controllers - DictionaryPage tarzında
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();

    // Animation setup - DictionaryPage ile aynı
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
    _cardAnimations = List.generate(2, (index) {
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
      if (!_isDisposed && mounted) {
        _cardAnimationController.forward();
      }
    });

    _fetchLanguages();
    _checkPremiumStatus();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    _cardAnimationController.dispose();
    _controllers.forEach((key, controller) {
      controller?.dispose();
    });
    super.dispose();
  }

  Future<void> _checkPremiumStatus() async {
    if (_isDisposed || !mounted) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!_isDisposed && mounted) {
          setState(() {
            _isPremium =
                userDoc.exists && (userDoc.data()?['isPremium'] ?? false);
            _isLoadingPremiumStatus = false;
          });
          if (_isPremium!) {
            _fetchLanguages(); // Premium ise dilleri yükle
          }
        }
      } else {
        if (!_isDisposed && mounted) {
          setState(() {
            _isPremium = false;
            _isLoadingPremiumStatus = false;
          });
        }
      }
    } catch (e) {
      print('Premium durumu kontrol edilirken hata oluştu: $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _isPremium = false;
          _isLoadingPremiumStatus = false;
        });
      }
    }
  }

  Future<void> _fetchLanguages() async {
    if (_isDisposed || !mounted) return;
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('languages').get();
      if (!_isDisposed && mounted) {
        setState(() {
          _languages = snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'name': doc['name'] as String? ?? 'Bilinmeyen Dil',
              'flagCode': doc['flagCode'] as String?,
            };
          }).toList();

          if (_languages.isNotEmpty) {
            _selectedLanguage = _languages.first['name'];
          }
        });
      }
    } catch (e) {
      print('Diller çekilirken hata oluştu: $e');
    }
  }

  Future<void> _initializeVideoController(
      String videoId, String videoUrl) async {
    if (_isDisposed || !mounted) return;
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: {
          'Cache-Control': 'max-age=86400',
          'User-Agent': 'Flutter App',
        },
      );

      _controllers[videoId] = controller;

      controller.addListener(() {
        if (controller.value.isInitialized &&
            !_videoCacheStatus.containsKey(videoId)) {
          if (!_isDisposed && mounted) {
            setState(() {
              _videoCacheStatus[videoId] = true;
            });
          }
        }
      });

      await controller.initialize();
      if (!_isDisposed && mounted) {
        _videoErrors.remove(videoId);
        setState(() {});
      }
    } catch (e) {
      print('Video yüklenirken hata oluştu (ID: $videoId): $e');
      if (!_isDisposed && mounted) {
        _videoErrors[videoId] = 'Video yüklenemedi: $e';
        _controllers[videoId] = null;
        setState(() {});
      }
    }
  }

  void _navigateToVideoDetail(Video video, VideoPlayerController controller) {
    if (!_isDisposed && mounted) {
      Navigator.pushNamed(
        context,
        AppRouter.videoDetail,
        arguments: {
          'video': video,
          'controller': controller,
        },
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

  Widget _buildLanguageBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
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
                        setState(() {
                          _selectedLanguage = language['name'];
                          _controllers.forEach((key, controller) {
                            controller?.dispose();
                          });
                          _controllers.clear();
                          _videoErrors.clear();
                          _videoCacheStatus.clear();
                        });
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
                            if (language['flagCode'] != null)
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: CountryFlag.fromCountryCode(
                                  language['flagCode']!.toUpperCase(),
                                  width: 28,
                                  height: 20,
                                  shape: const RoundedRectangle(4),
                                ),
                              ),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPremiumStatus) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(ColorConstants.MAINCOLOR),
          ),
        ),
      );
    }

    // Premium değilse PremiumPage'e yönlendir
    if (_isPremium == false) {
      // Navigasyonu build dışında tetikle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRouter.premium);
        }
      });
      // Boş bir widget döndür
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(ColorConstants.MAINCOLOR),
          ),
        ),
      );
      // Eğer AppRouter.premium yoksa, PremiumPage widget'ını direkt gösterebilirsiniz:
      // return const PremiumPage();
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(slivers: [
            // Modern Header - DictionaryPage tarzında
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: false,
              backgroundColor: ColorConstants.MAINCOLOR,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: ColorConstants.MAINCOLOR,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Hero(
                            tag: 'videos_icon',
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ColorConstants.WHITE,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.video_library,
                                size: 30,
                                color: ColorConstants.MAINCOLOR,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Title
                          const Text(
                            'Ders Videoları',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ColorConstants.WHITE,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Subtitle
                          Text(
                            'Dil öğrenme videolarını keşfedin',
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
              automaticallyImplyLeading: false,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: ColorConstants.MAINCOLOR,
                statusBarIconBrightness: Brightness.light,
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
                        // Language Selection Card
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
                                        borderRadius: BorderRadius.circular(8),
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
                                const SizedBox(height: 16),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      if (_languages.isNotEmpty) {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) =>
                                              _buildLanguageBottomSheet(),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: ColorConstants.MAINCOLOR
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          if (_selectedLanguage != null)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  right: 12),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 2,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child:
                                                  CountryFlag.fromCountryCode(
                                                _languages
                                                    .firstWhere(
                                                        (lang) =>
                                                            lang['name'] ==
                                                            _selectedLanguage,
                                                        orElse: () => {
                                                              'flagCode': 'TR'
                                                            })['flagCode']!
                                                    .toUpperCase(),
                                                width: 28,
                                                height: 20,
                                                shape:
                                                    const RoundedRectangle(4),
                                              ),
                                            ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Öğrenme Dili',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Text(
                                                  _selectedLanguage ??
                                                      'Dil seçiniz...',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: _selectedLanguage !=
                                                            null
                                                        ? ColorConstants
                                                            .TEXT_COLOR
                                                        : Colors.grey[400],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: ColorConstants.TEXT_COLOR
                                                .withOpacity(0.4),
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Video List Card
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
                                            ColorConstants.ACCENT_COLOR,
                                            ColorConstants.MAINCOLOR,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.video_library,
                                        color: ColorConstants.WHITE,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'Video Dersleri',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: ColorConstants.TEXT_COLOR,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _selectedLanguage == null
                                    ? Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Lütfen bir dil seçin',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('videos')
                                            .where('language',
                                                isEqualTo: _selectedLanguage)
                                            .orderBy('key')
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {
                                            return Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'Hata: ${snapshot.error}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            );
                                          }

                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation(
                                                          ColorConstants
                                                              .MAINCOLOR),
                                                ),
                                              ),
                                            );
                                          }

                                          final videos =
                                              snapshot.data!.docs.map((doc) {
                                            return Video.fromJson(doc.data()
                                                as Map<String, dynamic>)
                                              ..id = doc.id;
                                          }).toList();

                                          if (videos.isEmpty) {
                                            return Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'Bu dilde video bulunamadı',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            );
                                          }

                                          return ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: videos.length,
                                            itemBuilder: (context, index) {
                                              final video = videos[index];
                                              final videoId = video.id ??
                                                  'default_${index.toString()}';

                                              if (!_controllers
                                                      .containsKey(videoId) &&
                                                  !_videoErrors
                                                      .containsKey(videoId)) {
                                                _initializeVideoController(
                                                    videoId, video.videoUrl);
                                              }

                                              final controller =
                                                  _controllers[videoId];
                                              final errorMessage =
                                                  _videoErrors[videoId];

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 16),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    onTap: controller != null &&
                                                            controller.value
                                                                .isInitialized
                                                        ? () =>
                                                            _navigateToVideoDetail(
                                                                video,
                                                                controller)
                                                        : null,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[50],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                          color:
                                                              Colors.grey[200]!,
                                                        ),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Ders ${video.key}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  ColorConstants
                                                                      .TEXT_COLOR,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 8),
                                                          if (errorMessage !=
                                                              null)
                                                            Text(
                                                              errorMessage,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            )
                                                          else if (controller !=
                                                                  null &&
                                                              controller.value
                                                                  .isInitialized)
                                                            SizedBox(
                                                              height: 200,
                                                              child: Stack(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                children: [
                                                                  AspectRatio(
                                                                    aspectRatio:
                                                                        controller
                                                                            .value
                                                                            .aspectRatio,
                                                                    child:
                                                                        ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12),
                                                                      child: VideoPlayer(
                                                                          controller),
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.5),
                                                                      shape: BoxShape
                                                                          .circle,
                                                                    ),
                                                                    child:
                                                                        IconButton(
                                                                      icon:
                                                                          Icon(
                                                                        controller.value.isPlaying
                                                                            ? Icons.pause
                                                                            : Icons.play_arrow,
                                                                        size:
                                                                            50,
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                      onPressed: () => _navigateToVideoDetail(
                                                                          video,
                                                                          controller),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                          else
                                                            Container(
                                                              height: 150,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .grey[100],
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                              ),
                                                              child:
                                                                  const Center(
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    CircularProgressIndicator(
                                                                      valueColor:
                                                                          AlwaysStoppedAnimation(
                                                                              ColorConstants.MAINCOLOR),
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            8),
                                                                    Text(
                                                                      'Video yükleniyor...',
                                                                      style:
                                                                          TextStyle(
                                                                        color: Colors
                                                                            .grey,
                                                                        fontSize:
                                                                            12,
                                                                      ),
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
                                              );
                                            },
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
