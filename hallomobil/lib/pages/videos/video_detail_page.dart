import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/data/models/video_model.dart';
import 'package:video_player/video_player.dart';

class VideoDetailPage extends StatefulWidget {
  final Video video;
  final VideoPlayerController controller;

  const VideoDetailPage(
      {super.key, required this.video, required this.controller});

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage>
    with TickerProviderStateMixin {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  bool _isControlsVisible = true;
  bool _isFullScreen = false;
  bool _isVideoInitialized = false;
  bool _isDisposed = false;
  Timer? _controlsTimer;

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
    _cardAnimations = List.generate(3, (index) {
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

    // Video kontrolü
    if (widget.controller.value.isInitialized) {
      _initializeVideo();
    } else {
      widget.controller.addListener(_checkVideoInitialization);
    }
  }

  void _checkVideoInitialization() {
    if (widget.controller.value.isInitialized &&
        !_isVideoInitialized &&
        mounted) {
      setState(() {
        _isVideoInitialized = true;
      });
      widget.controller.removeListener(_checkVideoInitialization);
      _initializeVideo();
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isControlsVisible && !_isDisposed) {
        setState(() {
          _isControlsVisible = false;
        });
      }
    });
  }

  void _toggleControls() {
    if (!_isDisposed && mounted) {
      setState(() {
        _isControlsVisible = !_isControlsVisible;
      });
      if (_isControlsVisible) {
        _startControlsTimer();
      } else {
        _controlsTimer?.cancel();
      }
    }
  }

  void _initializeVideo() {
    if (!_isDisposed && mounted) {
      setState(() {
        _isVideoInitialized = true;
      });
      widget.controller.play();
      _startControlsTimer();
    }
  }

  void _togglePlayPause() {
    if (!_isDisposed && mounted) {
      setState(() {
        if (widget.controller.value.isPlaying) {
          widget.controller.pause();
        } else {
          widget.controller.play();
        }
        _isControlsVisible = true;
      });
      _startControlsTimer();
    }
  }

  void _toggleFullScreen() {
    if (!_isDisposed && mounted) {
      setState(() {
        _isFullScreen = !_isFullScreen;
        _isControlsVisible = true;
      });

      if (_isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
      _startControlsTimer();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _isDisposed = true;
    widget.controller.removeListener(_checkVideoInitialization);
    widget.controller.pause();
    _noteController.dispose();
    _questionController.dispose();
    _animationController.dispose();
    _cardAnimationController.dispose();
    _controlsTimer?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(_isFullScreen ? 0 : 16),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(ColorConstants.MAINCOLOR),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_isFullScreen ? 0 : 16),
        boxShadow: _isFullScreen
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_isFullScreen ? 0 : 16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AspectRatio(
              aspectRatio: widget.controller.value.aspectRatio,
              child: VideoPlayer(widget.controller),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControls,
                child: Container(color: Colors.transparent),
              ),
            ),
            AnimatedOpacity(
              opacity: _isControlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                ),
                child: Column(
                  children: [
                    if (_isFullScreen)
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _toggleFullScreen,
                              icon: const Icon(
                                Icons.fullscreen_exit,
                                color: ColorConstants.WHITE,
                                size: 28,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Ders ${widget.video.key}',
                                style: const TextStyle(
                                  color: ColorConstants.WHITE,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _togglePlayPause,
                        icon: Icon(
                          widget.controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: ColorConstants.WHITE,
                          size: 48,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          VideoProgressIndicator(
                            widget.controller,
                            allowScrubbing: true,
                            colors: VideoProgressColors(
                              playedColor: ColorConstants.MAINCOLOR,
                              bufferedColor: Colors.grey[400]!,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ValueListenableBuilder(
                                valueListenable: widget.controller,
                                builder: (context, value, child) {
                                  return Text(
                                    '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                                    style: const TextStyle(
                                      color: ColorConstants.WHITE,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                onPressed: _toggleFullScreen,
                                icon: Icon(
                                  _isFullScreen
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                  color: ColorConstants.WHITE,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleControls,
            child: _buildVideoPlayer(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
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
                            // Video Icon
                            Hero(
                              tag: 'video_detail_icon_${widget.video.id}',
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
                            Text(
                              'Ders ${widget.video.key}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.WHITE,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Subtitle
                            Text(
                              'Video dersi izle ve öğren',
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
                automaticallyImplyLeading: true,
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
                          // Video Player Card
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
                                          Icons.video_library,
                                          color: ColorConstants.WHITE,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Video Ders',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: ColorConstants.TEXT_COLOR,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: _buildVideoPlayer(),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Note Card
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
                                          Icons.edit_note,
                                          color: ColorConstants.WHITE,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Not Al',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: ColorConstants.TEXT_COLOR,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _noteController,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Ders hakkındaki notlarınızı buraya yazın...',
                                      hintStyle:
                                          TextStyle(color: Colors.grey[400]),
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: ColorConstants.MAINCOLOR
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: ColorConstants.MAINCOLOR,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: ColorConstants.MAINCOLOR,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    maxLines: 4,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Question Card
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
                                          Icons.help_outline,
                                          color: ColorConstants.WHITE,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Soru Sor',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: ColorConstants.TEXT_COLOR,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _questionController,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Ders ile ilgili sorularınızı buraya yazın...',
                                      hintStyle:
                                          TextStyle(color: Colors.grey[400]),
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: ColorConstants.MAINCOLOR
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.question_mark,
                                          color: ColorConstants.MAINCOLOR,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: ColorConstants.MAINCOLOR,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    maxLines: 4,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Save Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  ColorConstants.MAINCOLOR,
                                  ColorConstants.SECONDARY_COLOR,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      ColorConstants.MAINCOLOR.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (_noteController.text.isNotEmpty ||
                                    _questionController.text.isNotEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: ColorConstants.WHITE),
                                          SizedBox(width: 8),
                                          Text(
                                              'Not ve soru başarıyla kaydedildi!'),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                  _noteController.clear();
                                  _questionController.clear();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.info,
                                              color: ColorConstants.WHITE),
                                          SizedBox(width: 8),
                                          Text(
                                              'Lütfen en az bir alan doldurun'),
                                        ],
                                      ),
                                      backgroundColor: Colors.orange,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Kaydet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ColorConstants.WHITE,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
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
