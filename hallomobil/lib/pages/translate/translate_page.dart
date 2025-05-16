import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TranslationPage extends StatefulWidget {
  const TranslationPage({Key? key}) : super(key: key);

  @override
  _TranslationPageState createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  final TextEditingController _textController = TextEditingController();
  String _translatedText = '';
  bool _isLoading = false;

  bool _showSourceLanguageOptions = false;
  bool _showTargetLanguageOptions = false;
  final GlobalKey _sourceLanguageSelectorKey = GlobalKey();
  final GlobalKey _targetLanguageSelectorKey = GlobalKey();

  // Supported languages
  final List<String> _languages = [
    'Türkçe',
    'Almanca',
    'İngilizce',
    'Fransızca'
  ];
  String _sourceLanguage = 'Türkçe';
  String _targetLanguage = 'Almanca';

  // Language codes mapping
  final Map<String, String> _languageCodes = {
    'Türkçe': 'tr',
    'Almanca': 'de',
    'İngilizce': 'en',
    'Fransızca': 'fr',
  };

  Future<void> _translate() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _translatedText = '';
    });

    try {
      final response = await http.post(
        Uri.parse('https://apertium.org/apy/translate'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'q': _textController.text,
          'langpair':
              '${_languageCodes[_sourceLanguage]}|${_languageCodes[_targetLanguage]}',
          'markUnknown': 'no'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _translatedText =
              data['responseData']['translatedText'] ?? 'Çeviri bulunamadı';
        });
      } else {
        setState(() {
          _translatedText = 'Hata: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _translatedText = 'Bağlantı hatası: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;
      _translatedText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.WHITE,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Çeviri Uygulaması'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Source Language Selector (Bottom)
            GestureDetector(
              key: _sourceLanguageSelectorKey,
              onTap: () {
                setState(() {
                  _showSourceLanguageOptions = !_showSourceLanguageOptions;
                  _showTargetLanguageOptions = false;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.MAINCOLOR,
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
                        'Kaynak Dil: $_sourceLanguage',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.MAINCOLOR),
                      ),
                    ),
                    Icon(
                      _showSourceLanguageOptions
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ],
                ),
              ),
            ),

            if (_showSourceLanguageOptions)
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
                        color: ColorConstants.MAINCOLOR,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: _languages
                        .where((lang) => lang != _targetLanguage)
                        .map((language) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _sourceLanguage = language;
                            _showSourceLanguageOptions = false;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: _sourceLanguage == language
                                ? ColorConstants.MAINCOLOR
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            language,
                            style: TextStyle(
                              color: _sourceLanguage == language
                                  ? ColorConstants.MAINCOLOR
                                  : Colors.grey[800],
                              fontWeight: _sourceLanguage == language
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

            // Swap Languages Button
            IconButton(
              icon: const Icon(
                Icons.swap_vert,
                size: 32,
                color: ColorConstants.MAINCOLOR,
              ),
              onPressed: _swapLanguages,
            ),
            // Target Language Selector (Top)
            GestureDetector(
              key: _targetLanguageSelectorKey,
              onTap: () {
                setState(() {
                  _showTargetLanguageOptions = !_showTargetLanguageOptions;
                  _showSourceLanguageOptions = false;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.MAINCOLOR,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.MAINCOLOR,
                        ),
                      ),
                    ),
                    Icon(
                      _showTargetLanguageOptions
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ],
                ),
              ),
            ),
            if (_showTargetLanguageOptions)
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
                        color: Colors.black,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: _languages
                        .where((lang) => lang != _sourceLanguage)
                        .map((language) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _targetLanguage = language;
                            _showTargetLanguageOptions = false;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: _targetLanguage == language
                                ? ColorConstants.MAINCOLOR
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

            const SizedBox(height: 16),

            // Text Input Field
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Çevrilecek metni girin...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _textController.clear(),
                  ),
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 16),

            // Translate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _translate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.MAINCOLOR,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'ÇEVİR',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.WHITE,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Translation Result
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: ColorConstants.MAINCOLOR,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(minHeight: 100),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Text(
                      _translatedText.isNotEmpty
                          ? _translatedText
                          : 'Çeviri sonucu burada görünecek',
                      style: TextStyle(
                        fontSize: 16,
                        color: _translatedText.isEmpty
                            ? Colors.grey
                            : ColorConstants.MAINCOLOR,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
