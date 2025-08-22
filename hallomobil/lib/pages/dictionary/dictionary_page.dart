import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _translatedText = '';
  bool _isLoading = false;
  String _searchQuery = '';
  bool _showLanguageOptions = false;
  bool _isDisposed = false;

  // Animation Controllers - SettingsPage tarzında
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<double>> _cardAnimations;

  // Sabit kaynak dil Türkçe, hedef dil seçilebilir
  final String _sourceLanguage = 'Türkçe';
  final List<String> _targetLanguages = ['Almanca', 'İngilizce', 'Fransızca'];
  String _targetLanguage = 'Almanca';

  // Alfabetik sıralı Türkçe kelime listesi ve çevirileri
  final List<Map<String, String>> _wordList = [
    {
      'turkce': 'araba',
      'almanca': 'Auto',
      'ingilizce': 'car',
      'fransızca': 'voiture'
    },
    {
      'turkce': 'bilgisayar',
      'almanca': 'Computer',
      'ingilizce': 'computer',
      'fransızca': 'ordinateur'
    },
    {
      'turkce': 'elma',
      'almanca': 'Apfel',
      'ingilizce': 'apple',
      'fransızca': 'pomme'
    },
    {
      'turkce': 'ev',
      'almanca': 'Haus',
      'ingilizce': 'house',
      'fransızca': 'maison'
    },
    {
      'turkce': 'güneş',
      'almanca': 'Sonne',
      'ingilizce': 'sun',
      'fransızca': 'soleil'
    },
    {
      'turkce': 'kitap',
      'almanca': 'Buch',
      'ingilizce': 'book',
      'fransızca': 'livre'
    },
    {
      'turkce': 'köpek',
      'almanca': 'Hund',
      'ingilizce': 'dog',
      'fransızca': 'chien'
    },
    {
      'turkce': 'merhaba',
      'almanca': 'Hallo',
      'ingilizce': 'hello',
      'fransızca': 'bonjour'
    },
    {
      'turkce': 'su',
      'almanca': 'Wasser',
      'ingilizce': 'water',
      'fransızca': 'eau'
    },
    {
      'turkce': 'teşekkür',
      'almanca': 'Danke',
      'ingilizce': 'thank you',
      'fransızca': 'merci'
    },
  ];

  @override
  void initState() {
    super.initState();

    // Animation setup - SettingsPage ile aynı
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
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    _cardAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Filtrelenmiş kelime listesi
  List<Map<String, String>> get _filteredWords {
    return _wordList; // Her zaman tüm kelime listesini döndür
  }

  String _getDictionaryKey(String language) {
    switch (language) {
      case 'Almanca':
        return 'almanca';
      case 'İngilizce':
        return 'ingilizce';
      case 'Fransızca':
        return 'fransızca';
      default:
        return 'almanca';
    }
  }

  String _getLangCode(String language) {
    switch (language) {
      case 'İngilizce':
        return 'en';
      case 'Türkçe':
        return 'tr';
      case 'Almanca':
        return 'de';
      case 'Fransızca':
        return 'fr';
      default:
        return 'en';
    }
  }

  Future<void> _translateWord(String word) async {
    if (_isDisposed) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _translatedText = '';
    });

    try {
      final sourceLang = _getLangCode(_sourceLanguage);
      final targetLang = _getLangCode(_targetLanguage);

      final response = await http.get(
        Uri.parse(
            'https://api.mymemory.translated.net/get?q=$word&langpair=$sourceLang|$targetLang'),
      );

      if (!_isDisposed && mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['responseData'] != null) {
            setState(() {
              _translatedText =
                  data['responseData']['translatedText'] ?? 'Çeviri bulunamadı';
            });
          } else {
            setState(() {
              _translatedText = 'Çeviri bulunamadı';
            });
          }
        } else {
          setState(() {
            _translatedText = 'API hatası: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _translatedText = 'Hata: ${e.toString()}';
        });
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLanguageBottomSheet() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLanguageBottomSheet(),
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
                  child: const Icon(Icons.translate,
                      color: ColorConstants.WHITE, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Hedef Dil Seçin',
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
              itemCount: _targetLanguages.length,
              itemBuilder: (context, index) {
                final language = _targetLanguages[index];
                final isSelected = _targetLanguage == language;

                return AnimatedContainer(
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          _targetLanguage = language;
                          _showLanguageOptions = false;
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ColorConstants.MAINCOLOR
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.language,
                                color: isSelected
                                    ? ColorConstants.WHITE
                                    : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                language,
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
              // Modern Header - SettingsPage tarzında
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
                            // Dictionary Icon
                            Hero(
                              tag: 'dictionary_icon',
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
                                  Icons.menu_book_rounded,
                                  size: 30,
                                  color: ColorConstants.MAINCOLOR,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Title
                            const Text(
                              'Türkçe Sözlük',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.WHITE,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Subtitle
                            Text(
                              'Kelime çevir ve öğren',
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
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Language Selection Card
                          _buildModernCard(
                            animationIndex: 0,
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
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.translate,
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
                                      onTap: _showLanguageBottomSheet,
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: ColorConstants.MAINCOLOR
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: ColorConstants.MAINCOLOR,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.language,
                                                color: ColorConstants.WHITE,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Hedef Dil',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    _targetLanguage,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: ColorConstants
                                                          .TEXT_COLOR,
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

                          // Search Card
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
                                          Icons.search,
                                          color: ColorConstants.WHITE,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Kelime Ara',
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
                                    controller: _searchController,
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Türkçe kelime yazın...',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                      ),
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: ColorConstants.MAINCOLOR
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.search,
                                          color: ColorConstants.MAINCOLOR,
                                        ),
                                      ),
                                      suffixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: ColorConstants.MAINCOLOR,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.translate,
                                              color: Colors.white),
                                          onPressed: () {
                                            if (_searchController
                                                .text.isNotEmpty) {
                                              _translateWord(
                                                  _searchController.text);
                                            }
                                          },
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
                                    onSubmitted: (_) {
                                      if (_searchController.text.isNotEmpty) {
                                        _translateWord(_searchController.text);
                                      }
                                    },
                                  ),

                                  // Translation Result
                                  if (_isLoading || _translatedText.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 16),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: _isLoading
                                            ? Colors.blue[50]
                                            : ColorConstants.ACCENT_COLOR
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _isLoading
                                              ? Colors.blue[200]!
                                              : ColorConstants.ACCENT_COLOR
                                                  .withOpacity(0.3),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? Row(
                                              children: [
                                                const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                            ColorConstants
                                                                .MAINCOLOR),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Çeviriliyor...',
                                                  style: TextStyle(
                                                    color: Colors.blue[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              6),
                                                      decoration: BoxDecoration(
                                                        color: ColorConstants
                                                            .MAINCOLOR,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: const Icon(
                                                        Icons.translate,
                                                        color: ColorConstants
                                                            .WHITE,
                                                        size: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      _searchController.text,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: ColorConstants
                                                            .TEXT_COLOR,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(height: 16),
                                                Text(
                                                  _translatedText,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: ColorConstants
                                                        .SECONDARY_COLOR,
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // Word List Card
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
                                          Icons.list_alt,
                                          color: ColorConstants.WHITE,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Kelime Listesi',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: ColorConstants.TEXT_COLOR,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Headers
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: ColorConstants.MAINCOLOR
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Türkçe',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: ColorConstants.MAINCOLOR,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Container(
                                          height: 20,
                                          width: 1,
                                          color: Colors.grey[300],
                                        ),
                                        Expanded(
                                          child: Text(
                                            _targetLanguage,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: ColorConstants.MAINCOLOR,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Word List
                                  const SizedBox(height: 12),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _filteredWords.length,
                                    itemBuilder: (context, index) {
                                      final wordPair = _filteredWords[index];
                                      final turkceKelime =
                                          wordPair['turkce'] ?? '';
                                      final hedefKelime = wordPair[
                                              _getDictionaryKey(
                                                  _targetLanguage)] ??
                                          '';

                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: () {
                                            _searchController.text =
                                                turkceKelime;
                                            _translateWord(turkceKelime);
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey[200]!,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    turkceKelime,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: ColorConstants
                                                          .TEXT_COLOR,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Container(
                                                  height: 20,
                                                  width: 1,
                                                  color: Colors.grey[300],
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    hedefKelime,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: ColorConstants
                                                          .TEXT_COLOR,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
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
            ],
          ),
        ),
      ),
    );
  }
}
