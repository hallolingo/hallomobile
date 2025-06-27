import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hallomobil/constants/color/color_constants.dart';

class ListeningFillBlankPage extends StatefulWidget {
  final String selectedLanguage;
  final String selectedLevel;

  const ListeningFillBlankPage({
    super.key,
    required this.selectedLanguage,
    required this.selectedLevel,
  });

  @override
  State<ListeningFillBlankPage> createState() => _ListeningFillBlankPageState();
}

class _ListeningFillBlankPageState extends State<ListeningFillBlankPage>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isAnswered = false;
  String? _userAnswer;
  String? _correctAnswer;
  List<String> _options = [];
  String _sentence = '';
  String _targetWord = '';
  String _sentenceTurkish = '';

  late AnimationController _bounceController;
  late AnimationController _slideController;
  late Animation<double> _bounceAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchQuestions();
  }

  void _initAnimations() {
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.bounceOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _fetchQuestions() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('listening_fill_blank')
          .where('languageName', isEqualTo: widget.selectedLanguage)
          .where('level', isEqualTo: widget.selectedLevel) // Filter by level
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _questions = snapshot.docs.map((doc) => doc.data()).toList();
          _loadCurrentQuestion();
          _isLoading = false;
        });
        _slideController.forward();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching questions: $e');
    }
  }

  void _loadCurrentQuestion() {
    if (_questions.isNotEmpty && _currentQuestionIndex < _questions.length) {
      final question = _questions[_currentQuestionIndex];
      setState(() {
        _sentence = question['sentence'] ?? '';
        _targetWord = question['targetWord'] ?? '';
        _options = List<String>.from(question['options'] ?? []);
        _correctAnswer = _targetWord;
        _userAnswer = null;
        _isAnswered = false;
        _sentenceTurkish =
            question['sentenceTurkish'] ?? ''; // Bu satırı ekleyin
      });
    }
  }

  Future<void> _playSound(bool isCorrect) async {
    try {
      final soundPath = isCorrect
          ? 'assets/sounds/correct.wav'
          : 'assets/sounds/incorrect.mp3';
      await _audioPlayer.play(AssetSource(soundPath));
      print('Ses çalındı: $soundPath');
    } catch (e) {
      print('Ses çalınamadı: $e');
    }
  }

  void _checkAnswer() {
    if (_userAnswer == null) return;

    final isCorrect =
        _userAnswer!.toLowerCase() == _correctAnswer?.toLowerCase();

    setState(() {
      _isAnswered = true;
    });

    _playSound(isCorrect).then((_) {
      _bounceController.forward();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isAnswered) {
          _nextQuestion();
        }
      });
    });
  }

  void _nextQuestion() {
    _bounceController.reset();
    _slideController.reset();

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _loadCurrentQuestion();
      _slideController.forward();
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber, size: 30),
            SizedBox(width: 10),
            Text('Tebrikler!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tüm soruları tamamladınız!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorConstants.MAINCOLOR.withOpacity(0.1),
                    ColorConstants.MAINCOLOR.withOpacity(0.2)
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_questions.length} soruyu bitirdiniz',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Ana Sayfaya Dön'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentQuestionIndex = 0;
              });
              _loadCurrentQuestion();
              _slideController.forward();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.MAINCOLOR,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tekrar Başla'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soru ${_currentQuestionIndex + 1}/${_questions.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.MAINCOLOR,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ColorConstants.MAINCOLOR.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.selectedLanguage} - ${widget.selectedLevel}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ColorConstants.MAINCOLOR,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(ColorConstants.MAINCOLOR),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceWithBlank() {
    final words = _sentence.split(' ');
    final targetIndex = words.indexWhere(
        (word) => word.toLowerCase().contains(_targetWord.toLowerCase()));

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.indigo[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: words.asMap().entries.map((entry) {
          final index = entry.key;
          final word = entry.value;

          if (index == targetIndex) {
            return _buildDropZone();
          }

          return Text(
            word,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDropZone() {
    return DragTarget<String>(
      onAccept: (data) {
        setState(() {
          _userAnswer = data;
        });
        _checkAnswer();
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 120,
          height: 40,
          decoration: BoxDecoration(
            color: _userAnswer != null
                ? (_userAnswer == _correctAnswer
                    ? Colors.green[100]
                    : Colors.red[100])
                : (candidateData.isNotEmpty
                    ? ColorConstants.MAINCOLOR.withOpacity(0.2)
                    : Colors.white),
            border: Border.all(
              color: _userAnswer != null
                  ? (_userAnswer == _correctAnswer ? Colors.green : Colors.red)
                  : (candidateData.isNotEmpty
                      ? ColorConstants.MAINCOLOR
                      : Colors.grey[400]!),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: candidateData.isNotEmpty
                ? [
                    BoxShadow(
                      color: ColorConstants.MAINCOLOR.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: _userAnswer != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _userAnswer!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _userAnswer == _correctAnswer
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        _userAnswer == _correctAnswer
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: _userAnswer == _correctAnswer
                            ? Colors.green[700]
                            : Colors.red[700],
                        size: 18,
                      ),
                    ],
                  )
                : Text(
                    candidateData.isNotEmpty
                        ? (candidateData.first ?? '____')
                        : '____',
                    style: TextStyle(
                      fontSize: 16,
                      color: candidateData.isNotEmpty
                          ? ColorConstants.MAINCOLOR
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildOptions() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kelimeyi sürükleyip boşluğa bırakın:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _options
                .map((option) => _buildDraggableOption(option))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableOption(String option) {
    final isUsed = _userAnswer == option;

    return Draggable<String>(
      data: option,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorConstants.MAINCOLOR,
                ColorConstants.MAINCOLOR.withOpacity(0.8)
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            option,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: Text(
          option,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isUsed ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isUsed
                ? LinearGradient(colors: [Colors.grey[400]!, Colors.grey[300]!])
                : LinearGradient(
                    colors: [
                      ColorConstants.MAINCOLOR.withOpacity(0.9),
                      ColorConstants.MAINCOLOR,
                    ],
                  ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isUsed
                ? null
                : [
                    BoxShadow(
                      color: ColorConstants.MAINCOLOR.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Text(
            option,
            style: TextStyle(
              color: isUsed ? Colors.grey[600] : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    if (!_isAnswered) return const SizedBox.shrink();

    final isCorrect = _userAnswer == _correctAnswer;

    return ScaleTransition(
      scale: _bounceAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCorrect
                ? [Colors.green[100]!, Colors.green[50]!]
                : [Colors.red[100]!, Colors.red[50]!],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCorrect ? Colors.green : Colors.red,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.error,
              color: isCorrect ? Colors.green[700] : Colors.red[700],
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect ? 'Doğru!' : 'Yanlış!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  if (!isCorrect) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Doğru cevap: $_correctAnswer',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Türkçe: $_sentenceTurkish',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(
          'Dinleme - Boşluk Doldurma (${widget.selectedLevel})',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorConstants.MAINCOLOR,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: ColorConstants.MAINCOLOR),
                  SizedBox(height: 20),
                  Text(
                    'Sorular yükleniyor...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : _questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.quiz_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${widget.selectedLanguage} dilinde ${widget.selectedLevel} seviyesinde soru bulunamadı',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgressIndicator(),
                        const SizedBox(height: 20),
                        _buildSentenceWithBlank(),
                        const SizedBox(height: 30),
                        _buildOptions(),
                        _buildFeedback(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _bounceController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
