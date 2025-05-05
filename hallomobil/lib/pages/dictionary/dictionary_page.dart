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

class _DictionaryPageState extends State<DictionaryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _translatedText = '';
  bool _isLoading = false;
  String _searchQuery = '';

  bool _showLanguageOptions = false;
  final GlobalKey _languageSelectorKey = GlobalKey();

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

  // Filtrelenmiş kelime listesi
  List<Map<String, String>> get _filteredWords {
    if (_searchQuery.isEmpty) {
      return _wordList;
    } else {
      return _wordList.where((word) {
        final turkceKelime = word['turkce']?.toLowerCase() ?? '';
        final hedefKelime =
            word[_getDictionaryKey(_targetLanguage)]?.toLowerCase() ?? '';
        return turkceKelime.contains(_searchQuery.toLowerCase()) ||
            hedefKelime.contains(_searchQuery.toLowerCase());
      }).toList();
    }
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
    } catch (e) {
      setState(() {
        _translatedText = 'Hata: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.WHITE,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Türkçe Sözlük'),
        backgroundColor: ColorConstants.WHITE,
        foregroundColor: ColorConstants.MAINCOLOR,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: ColorConstants.MAINCOLOR,
          statusBarIconBrightness: Brightness.dark,
        ),
        centerTitle: true,
      ),
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Hedef dil seçim alanı
              GestureDetector(
                key: _languageSelectorKey,
                onTap: () {
                  setState(() {
                    _showLanguageOptions = !_showLanguageOptions;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Hedef Dil: $_targetLanguage',
                          style: TextStyle(
                            fontSize: 16,
                            color: ColorConstants.MAINCOLOR,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        _showLanguageOptions
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: ColorConstants.MAINCOLOR,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showLanguageOptions)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: _targetLanguages.map((language) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _targetLanguage = language;
                              _showLanguageOptions = false;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: _targetLanguage == language
                                  ? ColorConstants.MAINCOLOR.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              language,
                              style: TextStyle(
                                color: _targetLanguage == language
                                    ? ColorConstants.MAINCOLOR
                                    : Colors.grey[800],
                                fontWeight: _targetLanguage == language
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Arama alanı
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Kelime ara',
                  labelStyle: TextStyle(
                    color: ColorConstants.MAINCOLOR,
                  ),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorConstants.MAINCOLOR,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {
                        if (_searchController.text.isNotEmpty) {
                          _translateWord(_searchController.text);
                        }
                      },
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ColorConstants.MAINCOLOR.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 20),

              // Sonuç alanı
              if (_isLoading)
                const CircularProgressIndicator(
                  color: ColorConstants.MAINCOLOR,
                )
              else if (_translatedText.isNotEmpty)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _searchController.text,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.MAINCOLOR,
                          ),
                        ),
                        const Divider(),
                        Text(
                          _translatedText,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Kelime listesi başlığı
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Türkçe',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.MAINCOLOR,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _targetLanguage,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.MAINCOLOR,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Alfabetik kelime listesi
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredWords.length,
                  itemBuilder: (context, index) {
                    final wordPair = _filteredWords[index];
                    final turkceKelime = wordPair['turkce'] ?? '';
                    final hedefKelime =
                        wordPair[_getDictionaryKey(_targetLanguage)] ?? '';

                    return Card(
                      child: ListTile(
                        onTap: () {
                          _searchController.text = turkceKelime;
                          _translateWord(turkceKelime);
                        },
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                turkceKelime,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
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
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
