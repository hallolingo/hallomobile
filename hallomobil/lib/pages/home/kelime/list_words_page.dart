import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:flutter_tts/flutter_tts.dart';

class WordDetailPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String selectedLanguage;

  const WordDetailPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.selectedLanguage,
  });

  @override
  State<WordDetailPage> createState() => _WordDetailPageState();
}

class _WordDetailPageState extends State<WordDetailPage>
    with TickerProviderStateMixin {
  late int _currentIndex = 0;
  late AnimationController _flipController;
  late AnimationController _slideController;
  late Animation<double> _flipAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isFront = true;
  List<Map<String, dynamic>> _words = [];
  bool _showAllWords = false;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _fetchWords();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.1),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _flipController.dispose();
    _slideController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _fetchWords() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('contents')
        .where('categoryId', isEqualTo: widget.categoryId)
        .orderBy('key')
        .get();
    setState(() {
      _words = snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    });
  }

  void _nextWord() {
    if (_currentIndex < _words.length - 1) {
      _slideController.forward().then((_) {
        setState(() {
          _currentIndex++;
          _isFront = true;
          _flipController.reset();
        });
        _slideController.reverse();
      });
    }
  }

  void _previousWord() {
    if (_currentIndex > 0) {
      _slideController.forward().then((_) {
        setState(() {
          _currentIndex--;
          _isFront = true;
          _flipController.reset();
        });
        _slideController.reverse();
      });
    }
  }

  void _flipCard() {
    if (_flipController.isCompleted) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  void _toggleAllWords() {
    setState(() {
      _showAllWords = !_showAllWords;
    });
  }

  Future<void> _speak(String text, String language) async {
    await _flutterTts.stop();
    await _flutterTts.setLanguage(language);
    await _flutterTts.setSpeechRate(0.5); // Konuşma hızı
    await _flutterTts.setVolume(1.0); // Ses seviyesi
    await _flutterTts.setPitch(1.0); // Ton
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: ColorConstants.WHITE,
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ColorConstants.MAINCOLOR,
                ColorConstants.MAINCOLOR.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: _words.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ColorConstants.MAINCOLOR,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kelimeler yükleniyor...',
                    style: TextStyle(
                      color: ColorConstants.MAINCOLOR,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _flipCard,
                                  child: AnimatedBuilder(
                                    animation: _flipAnimation,
                                    builder: (context, child) {
                                      final isFrontSide =
                                          _flipAnimation.value <= 0.5;
                                      return Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, 0.001)
                                          ..rotateY(isFrontSide
                                              ? _flipAnimation.value * 3.14159
                                              : (1 - _flipAnimation.value) *
                                                  3.14159),
                                        child: Container(
                                          width: double.infinity,
                                          height: 220,
                                          child: ClipRRect(
                                            child: Stack(
                                              children: [
                                                isFrontSide
                                                    ? Image.network(
                                                        _words[_currentIndex]
                                                            ['frontImageUrl'],
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                        errorBuilder: (context,
                                                                error,
                                                                stackTrace) =>
                                                            Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            gradient:
                                                                LinearGradient(
                                                              colors: [
                                                                Colors
                                                                    .grey[300]!,
                                                                Colors
                                                                    .grey[200]!,
                                                              ],
                                                            ),
                                                          ),
                                                          child: const Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            size: 50,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      )
                                                    : Image.network(
                                                        _words[_currentIndex]
                                                            ['backImageUrl'],
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                        errorBuilder: (context,
                                                                error,
                                                                stackTrace) =>
                                                            Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            gradient:
                                                                LinearGradient(
                                                              colors: [
                                                                Colors
                                                                    .grey[300]!,
                                                                Colors
                                                                    .grey[200]!,
                                                              ],
                                                            ),
                                                          ),
                                                          child: const Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            size: 50,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ),
                                                Positioned(
                                                  bottom: 8,
                                                  right: 8,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.6),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Icon(
                                                      isFrontSide
                                                          ? Icons.flip_to_back
                                                          : Icons.flip_to_front,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: _buildInfoCard(
                                    Icons.record_voice_over,
                                    'Türkçe Okunuş',
                                    _words[_currentIndex]
                                        ['turkishPronunciation'],
                                    Colors.blue,
                                    _words[_currentIndex]
                                        ['turkishPronunciation'],
                                    'tr-TR', // Türkçe için sabit dil
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: _buildInfoCard(
                                    Icons.translate,
                                    'Türkçe Cümle',
                                    _words[_currentIndex]['turkishSentence'],
                                    Colors.green,
                                    _words[_currentIndex]['turkishSentence'],
                                    'tr-TR', // Türkçe için sabit dil
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: _buildInfoCard(
                                    Icons.language,
                                    '${widget.selectedLanguage} Cümle',
                                    _words[_currentIndex]['foreignSentence'],
                                    Colors.orange,
                                    _words[_currentIndex]['foreignSentence'],
                                    widget.selectedLanguage == 'Almanca'
                                        ? 'de-DE'
                                        : 'tr-TR', // Dinamik dil
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: ElevatedButton.icon(
                              onPressed: _toggleAllWords,
                              icon: Icon(
                                _showAllWords
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white,
                              ),
                              label: Text(
                                _showAllWords
                                    ? 'Kelimeleri Gizle'
                                    : 'Tüm Kelimeleri Göster',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorConstants.MAINCOLOR,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 8,
                                shadowColor:
                                    ColorConstants.MAINCOLOR.withOpacity(0.3),
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: _showAllWords ? null : 0,
                            child: _showAllWords
                                ? Container(
                                    margin: const EdgeInsets.only(
                                        top: 16, left: 8, right: 8),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 2,
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.list_alt,
                                              color: ColorConstants.MAINCOLOR,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Tüm Kelimeler',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: ColorConstants.MAINCOLOR,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        ..._words.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final word = entry.value;

                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: ColorConstants.MAINCOLOR
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: ColorConstants.MAINCOLOR,
                                                width: 2,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    color: ColorConstants
                                                        .MAINCOLOR,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '${index + 1}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        word['word'] ??
                                                            'Kelime bulunamadı',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: ColorConstants
                                                              .MAINCOLOR,
                                                        ),
                                                      ),
                                                      Text(
                                                        ' - ',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: ColorConstants
                                                              .MAINCOLOR,
                                                        ),
                                                      ),
                                                      Text(
                                                        word['wordTurkish'] ??
                                                            'Kelime bulunamadı',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: ColorConstants
                                                              .MAINCOLOR,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  height: MediaQuery.of(context).size.height * 0.109,
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavButton(
                        onPressed: _currentIndex > 0 ? _previousWord : null,
                        icon: Icons.arrow_back_ios,
                        label: 'Geri',
                        isEnabled: _currentIndex > 0,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: ColorConstants.MAINCOLOR.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: ColorConstants.MAINCOLOR.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${_words.length}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.MAINCOLOR,
                          ),
                        ),
                      ),
                      _buildNavButton(
                        onPressed: _currentIndex < _words.length - 1
                            ? _nextWord
                            : null,
                        icon: Icons.arrow_forward_ios,
                        label: 'İleri',
                        isEnabled: _currentIndex < _words.length - 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String content,
      Color color, String textToSpeak, String language) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up, size: 20),
                      color: color,
                      onPressed: () => _speak(textToSpeak, language),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isEnabled,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: isEnabled ? Colors.white : Colors.grey[400],
        size: 18,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isEnabled ? Colors.white : Colors.grey[400],
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isEnabled ? ColorConstants.MAINCOLOR : Colors.grey[300],
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: isEnabled ? 5 : 0,
        shadowColor:
            isEnabled ? ColorConstants.MAINCOLOR.withOpacity(0.3) : null,
      ),
    );
  }
}
