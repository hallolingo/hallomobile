import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class DialogueExercisePage extends StatefulWidget {
  final String selectedLanguage;
  final String selectedLevel;

  const DialogueExercisePage({
    super.key,
    required this.selectedLanguage,
    required this.selectedLevel,
  });

  @override
  State<DialogueExercisePage> createState() => _DialogueExercisePageState();
}

class _DialogueExercisePageState extends State<DialogueExercisePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late AnimationController _pulseAnimationController; // For recording indicator
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late List<Animation<double>> _cardAnimations;
  int _currentExerciseIndex = 0;
  List<DocumentSnapshot> _exercises = [];
  bool _isDialogueCorrect = false; // Tracks if dialogue line is correct
  bool _isResponseCorrect = false; // Tracks if expected response is correct
  bool _isRecording = false;
  String _recognizedText = '';
  String _feedbackMessage = '';
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _fetchExercises();
    _initSpeechToText();
    _initTts();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

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
  }

  void _startAnimations() {
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardAnimationController.forward();
    });
  }

  Future<void> _initSpeechToText() async {
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        debugPrint('SpeechToText status: $status');
        setState(() => _isRecording = status == 'listening');
        if (status == 'done' && _recognizedText.isEmpty) {
          setState(() {
            _isRecording = false;
            _feedbackMessage = 'Hiçbir şey söylenmedi, tekrar deneyin!';
          });
        }
      },
      onError: (error) {
        debugPrint('SpeechToText error: ${error.errorMsg}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${error.errorMsg}')),
        );
        setState(() {
          _isRecording = false;
          _feedbackMessage = 'Ses tanınamadı, hata: ${error.errorMsg}';
        });
      },
    );
    if (available) {
      final locales = await _speechToText.locales();
      final selectedLocale =
          widget.selectedLanguage == 'Almanca' ? 'de_DE' : 'en_US';
      debugPrint(
          'Available locales: ${locales.map((l) => l.localeId).toList()}');
      debugPrint(
          'Selected language: ${widget.selectedLanguage}, Using locale: $selectedLocale');
      if (!locales.any((l) => l.localeId == selectedLocale)) {
        debugPrint(
            'Selected locale ($selectedLocale) not supported, falling back to default');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Seçili dil ($selectedLocale) desteklenmiyor, varsayılan dil kullanılıyor')),
        );
      } else {
        debugPrint('Locale $selectedLocale is supported');
      }
    } else {
      debugPrint('SpeechToText initialization failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ses tanıma başlatılamadı')),
      );
      setState(() {
        _feedbackMessage = 'Ses tanıma başlatılamadı!';
      });
    }
  }

  Future<void> _initTts() async {
    String languageCode =
        widget.selectedLanguage == 'Almanca' ? 'de-DE' : 'en-US';
    await _flutterTts.setLanguage(languageCode);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    debugPrint('TTS initialized with language: $languageCode');
  }

  Future<void> _fetchExercises() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('speaking_dialogue')
          .where('languageName', isEqualTo: widget.selectedLanguage)
          .where('level', isEqualTo: widget.selectedLevel)
          .orderBy('createdAt')
          .get();
      setState(() {
        _exercises = querySnapshot.docs;
        _isDialogueCorrect = false;
        _isResponseCorrect = false;
        _recognizedText = '';
        _feedbackMessage = '';
      });
      debugPrint('Fetched ${_exercises.length} exercises');
    } catch (e) {
      debugPrint('Error fetching exercises: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Egzersizler yüklenemedi: $e')),
      );
    }
  }

  void _nextExercise() {
    setState(() {
      _currentExerciseIndex = (_currentExerciseIndex + 1) % _exercises.length;
      _isDialogueCorrect = false;
      _isResponseCorrect = false;
      _recognizedText = '';
      _feedbackMessage = '';
      _cardAnimationController.reset();
      _cardAnimationController.forward();
    });
    debugPrint('Moved to next exercise: $_currentExerciseIndex');
  }

  Future<void> _recordSpeech() async {
    if (!_isRecording) {
      setState(() {
        _isRecording = true;
        _feedbackMessage = '';
        _recognizedText = '';
      });
      debugPrint(
          'Starting speech recording with locale: ${widget.selectedLanguage == 'Almanca' ? 'de_DE' : 'en_US'}');
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords ?? '';
            debugPrint('Recognized text: $_recognizedText');
            if (_exercises.isNotEmpty) {
              if (!_isDialogueCorrect) {
                // Dialogue line phase: Check if the dialogue line is pronounced correctly
                String expectedDialogue = _exercises[_currentExerciseIndex]
                        ['dialogueLine']
                    .toString()
                    .toLowerCase();
                _isDialogueCorrect = _recognizedText
                    .toLowerCase()
                    .contains(expectedDialogue.split(' ').first.toLowerCase());
                _feedbackMessage = _isDialogueCorrect
                    ? 'Diyalog doğru! Şimdi yanıtı söyleyin.'
                    : 'Diyalog yanlış, tekrar deneyin!';
              } else {
                // Response phase: Check if the expected response is pronounced correctly
                String expectedResponse = _exercises[_currentExerciseIndex]
                        ['expectedResponse']
                    .toString()
                    .toLowerCase();
                _isResponseCorrect = _recognizedText
                    .toLowerCase()
                    .contains(expectedResponse.split(' ').first.toLowerCase());
                _feedbackMessage = _isResponseCorrect
                    ? 'Doğru!'
                    : 'Yanıt yanlış, tekrar deneyin!';
              }
            } else {
              _feedbackMessage = 'Diyalog bulunamadı!';
            }
            debugPrint(
                'Feedback: $_feedbackMessage, isDialogueCorrect: $_isDialogueCorrect, isResponseCorrect: $_isResponseCorrect');
          });
        },
        localeId: widget.selectedLanguage == 'Almanca' ? 'de_DE' : 'en_US',
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 7),
        partialResults: true,
      );
    } else {
      await _speechToText.stop();
      setState(() {
        _isRecording = false;
        if (_recognizedText.isEmpty && _feedbackMessage.isEmpty) {
          _feedbackMessage = 'Hiçbir şey söylenmedi, tekrar deneyin!';
        }
      });
      debugPrint(
          'Stopped recording. Recognized: $_recognizedText, Feedback: $_feedbackMessage');
    }
  }

  void _markAsCorrect() {
    setState(() {
      if (!_isDialogueCorrect) {
        _isDialogueCorrect = true;
        _feedbackMessage =
            'Diyalog doğru (Manuel onay)! Şimdi yanıtı söyleyin.';
        _recognizedText =
            _exercises[_currentExerciseIndex]['dialogueLine'].toString();
      } else {
        _isResponseCorrect = true;
        _feedbackMessage = 'Doğru (Manuel onay)!';
        _recognizedText =
            _exercises[_currentExerciseIndex]['expectedResponse'].toString();
      }
    });
    debugPrint('Manually marked as correct');
  }

  Future<void> _playText(String text, {bool isTurkish = false}) async {
    String originalLanguage =
        widget.selectedLanguage == 'Almanca' ? 'de-DE' : 'en-US';
    String turkishLanguage = 'tr-TR';

    await _flutterTts
        .setLanguage(isTurkish ? turkishLanguage : originalLanguage);
    await _flutterTts.speak(text);

    await _flutterTts.setLanguage(originalLanguage);
    debugPrint(
        'Playing text: $text in ${isTurkish ? 'Turkish' : originalLanguage}');
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
                              'Diyalog Tamamlama',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.WHITE,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.selectedLanguage} - ${widget.selectedLevel}',
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
                    child: _exercises.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: ColorConstants.MAINCOLOR,
                            ),
                          )
                        : _buildModernCard(
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
                                          Icons.chat,
                                          color: ColorConstants.WHITE,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Diyalog Tamamlama',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: ColorConstants.TEXT_COLOR,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Bağlam: ${_exercises[_currentExerciseIndex]['context']}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: ColorConstants.TEXT_COLOR
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.volume_up,
                                          color: ColorConstants.MAINCOLOR,
                                          size: 24,
                                        ),
                                        onPressed: () => _playText(
                                            _exercises[_currentExerciseIndex]
                                                ['context']),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Türkçe Bağlam: ${_exercises[_currentExerciseIndex]['contextTurkish']}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: ColorConstants.TEXT_COLOR
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.volume_up,
                                          color: ColorConstants.MAINCOLOR,
                                          size: 24,
                                        ),
                                        onPressed: () => _playText(
                                            _exercises[_currentExerciseIndex]
                                                ['contextTurkish'],
                                            isTurkish: true),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Diyalog: ${_exercises[_currentExerciseIndex]['dialogueLine']}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: ColorConstants.TEXT_COLOR,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.volume_up,
                                          color: ColorConstants.MAINCOLOR,
                                          size: 24,
                                        ),
                                        onPressed: () => _playText(
                                            _exercises[_currentExerciseIndex]
                                                ['dialogueLine']),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (_isDialogueCorrect) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Beklenen Yanıt: ${_exercises[_currentExerciseIndex]['expectedResponse']}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: ColorConstants.TEXT_COLOR
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.volume_up,
                                            color: ColorConstants.MAINCOLOR,
                                            size: 24,
                                          ),
                                          onPressed: () => _playText(
                                              _exercises[_currentExerciseIndex]
                                                  ['expectedResponse']),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Türkçe Yanıt: ${_exercises[_currentExerciseIndex]['expectedResponseTurkish']}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: ColorConstants.TEXT_COLOR
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.volume_up,
                                            color: ColorConstants.MAINCOLOR,
                                            size: 24,
                                          ),
                                          onPressed: () => _playText(
                                              _exercises[_currentExerciseIndex]
                                                  ['expectedResponseTurkish'],
                                              isTurkish: true),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  Center(
                                    child: AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _isRecording
                                              ? _pulseAnimation.value
                                              : 1.0,
                                          child: InkWell(
                                            onTap: _recordSpeech,
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            child: Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: _isRecording
                                                      ? [
                                                          Colors.red,
                                                          Colors.redAccent
                                                        ]
                                                      : [
                                                          ColorConstants
                                                              .MAINCOLOR,
                                                          ColorConstants
                                                              .SECONDARY_COLOR
                                                        ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _isRecording
                                                        ? Colors.red
                                                            .withOpacity(0.3)
                                                        : ColorConstants
                                                            .MAINCOLOR
                                                            .withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                _isRecording
                                                    ? Icons.stop
                                                    : Icons.mic,
                                                color: ColorConstants.WHITE,
                                                size: 30,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (_feedbackMessage.isNotEmpty &&
                                      !_isRecording) ...[
                                    const SizedBox(height: 16),
                                    Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _isDialogueCorrect &&
                                                    _isResponseCorrect
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color: _isDialogueCorrect &&
                                                    _isResponseCorrect
                                                ? Colors.green
                                                : Colors.red,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _feedbackMessage,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: _isDialogueCorrect &&
                                                      _isResponseCorrect
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_recognizedText.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Center(
                                        child: Text(
                                          'Tanınan: $_recognizedText',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: ColorConstants.TEXT_COLOR
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                  const SizedBox(height: 16),
                                  if (_isDialogueCorrect &&
                                      _isResponseCorrect) ...[
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: _nextExercise,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              ColorConstants.SECONDARY_COLOR,
                                          foregroundColor: ColorConstants.WHITE,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32, vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: const Text(
                                          'Devam Et',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  Center(
                                    child: TextButton(
                                      onPressed: _markAsCorrect,
                                      child: Text(
                                        _isDialogueCorrect
                                            ? 'Yanıtı doğru olarak işaretle'
                                            : 'Diyalogu doğru olarak işaretle',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: ColorConstants.MAINCOLOR,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
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

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    _pulseAnimationController.dispose();
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
  }
}
