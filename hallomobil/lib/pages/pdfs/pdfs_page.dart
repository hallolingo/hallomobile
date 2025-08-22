import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:hallomobil/app_router.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/data/models/pdf_model.dart';
import 'package:country_flags/country_flags.dart';
import 'package:hallomobil/pages/pdfs/pdfs_detail_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class PdfsPage extends StatefulWidget {
  const PdfsPage({super.key});

  @override
  State<PdfsPage> createState() => _PdfsPageState();
}

class _PdfsPageState extends State<PdfsPage> with TickerProviderStateMixin {
  List<Map<String, String?>> _languages = [];
  Timer? _debounceTimer;
  late ScrollController _scrollController;
  String? _selectedLanguage;
  Map<String, File?> _pdfFiles = {};
  Map<String, String?> _pdfErrors = {};
  bool _isDisposed = false;
  bool? _isPremium;
  bool _isLoadingPremiumStatus = true;
  bool _premiumCheckCompleted = false;
  bool _isLoadingPdfs = false;
  int _currentPage = 0;
  final int _pdfsPerPage = 10;
  bool _hasMorePdfs = true;
  bool _isLoadingMore = false;
  List<Pdf> _loadedPdfs = [];
  DocumentSnapshot? _lastDocument;
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

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

  void _scrollListener() {
    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMorePdfs) {
        _loadMorePdfs();
      }
    });
  }

  Future<bool> _isPdfUrlValid(String url) async {
    try {
      final response =
          await http.head(Uri.parse(url)).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print('PDF URL doğrulama hatası: $e');
      return false;
    }
  }

  Future<File?> _downloadPdf(String url, String pdfId) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$pdfId.pdf');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
      return null;
    } catch (e) {
      print('PDF indirme hatası: $e');
      return null;
    }
  }

  Future<void> _loadMorePdfs() async {
    if (_isDisposed ||
        !mounted ||
        !_hasMorePdfs ||
        _isLoadingMore ||
        _lastDocument == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('pdfs')
          .where('language', isEqualTo: _selectedLanguage)
          .limit(_pdfsPerPage)
          .startAfterDocument(_lastDocument!);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMorePdfs = false;
          _isLoadingMore = false;
        });
        return;
      }

      final newPdfs = snapshot.docs
          .map((doc) => Pdf.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      for (final pdf in newPdfs) {
        final pdfId = pdf.id ??
            '${pdf.language}_${DateTime.now().millisecondsSinceEpoch}';
        if (!_pdfFiles.containsKey(pdfId)) {
          await _initializePdfFile(pdfId, pdf);
        }
      }

      if (!_isDisposed && mounted) {
        setState(() {
          _loadedPdfs.addAll(newPdfs);
          _lastDocument = snapshot.docs.last;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Daha fazla PDF yüklenirken hata: $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _animationController.dispose();
    _cardAnimationController.dispose();
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
            _premiumCheckCompleted = true;
          });
          if (_isPremium!) {
            _fetchLanguages();
          }
        }
      } else {
        if (!_isDisposed && mounted) {
          setState(() {
            _isPremium = false;
            _isLoadingPremiumStatus = false;
            _premiumCheckCompleted = true;
          });
        }
      }
    } catch (e) {
      print('Premium durumu kontrol edilirken hata oluştu: $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _isPremium = false;
          _isLoadingPremiumStatus = false;
          _premiumCheckCompleted = true;
        });
      }
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.router,
        (route) => false,
        arguments: {'initialIndex': 0},
      );
    }
  }

  Widget _buildNonPremiumMessage() {
    return WillPopScope(
      onWillPop: () async {
        _navigateToHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  'Premium Özellik',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.TEXT_COLOR,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'PDF dersleri premium üyelere özel bir özelliktir. Premium üyelik satın alarak tüm PDF derslerine erişebilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _navigateToHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: ColorConstants.TEXT_COLOR,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Ana Sayfaya Dön',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRouter.premium);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.MAINCOLOR,
                          foregroundColor: ColorConstants.WHITE,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Premium Al',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchLanguages() async {
    if (_isDisposed || !mounted) return;

    setState(() {
      _isLoadingPdfs = true;
    });

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
            _loadPdfsForSelectedLanguage();
          } else {
            _isLoadingPdfs = false;
          }
        });
      }
    } catch (e) {
      print('Diller çekilirken hata oluştu: $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoadingPdfs = false;
        });
      }
    }
  }

  Future<void> _loadPdfsForSelectedLanguage() async {
    if (_selectedLanguage == null || _isDisposed || !mounted) return;

    setState(() {
      _isLoadingPdfs = true;
      _loadedPdfs.clear();
      _lastDocument = null;
      _currentPage = 0;
      _hasMorePdfs = true;
      _pdfFiles.clear();
      _pdfErrors.clear();
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('pdfs')
          .where('language', isEqualTo: _selectedLanguage)
          .limit(_pdfsPerPage);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _isLoadingPdfs = false;
          _hasMorePdfs = false;
        });
        return;
      }

      final pdfs = snapshot.docs
          .map((doc) => Pdf.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      if (pdfs.length < _pdfsPerPage) {
        _hasMorePdfs = false;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      for (final pdf in pdfs) {
        final pdfId = pdf.id ??
            '${pdf.language}_${DateTime.now().millisecondsSinceEpoch}';
        if (!_pdfFiles.containsKey(pdfId)) {
          await _initializePdfFile(pdfId, pdf);
        }
      }

      if (!_isDisposed && mounted) {
        setState(() {
          _loadedPdfs = pdfs;
          _isLoadingPdfs = false;
        });
      }
    } catch (e) {
      print('PDFler yüklenirken hata oluştu: $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoadingPdfs = false;
          _hasMorePdfs = false;
        });
      }
    }
  }

  Future<void> _initializePdfFile(String pdfId, Pdf pdf) async {
    if (_isDisposed || !mounted) return;

    try {
      if (!(await _isPdfUrlValid(pdf.pdfUrl))) {
        if (!_isDisposed && mounted) {
          setState(() {
            _pdfErrors[pdfId] = 'PDF URL geçersiz veya erişilemez';
          });
        }
        return;
      }

      final file = await _downloadPdf(pdf.pdfUrl, pdfId);
      if (file != null && !_isDisposed && mounted) {
        setState(() {
          _pdfFiles[pdfId] = file;
          _pdfErrors.remove(pdfId);
        });
      } else {
        setState(() {
          _pdfErrors[pdfId] = 'PDF dosyası indirilemedi';
        });
      }
    } catch (e) {
      print('PDF yüklenirken hata (ID: $pdfId): $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _pdfErrors[pdfId] = 'PDF yüklenemedi: ${e.toString()}';
        });
      }
    }
  }

  Widget _buildGermanLearningLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(
                        ColorConstants.MAINCOLOR.withOpacity(0.3)),
                  ),
                ),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor:
                        AlwaysStoppedAnimation(ColorConstants.MAINCOLOR),
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: ColorConstants.WHITE,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ColorConstants.MAINCOLOR.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: ColorConstants.MAINCOLOR,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'PDFler Yükleniyor...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorConstants.TEXT_COLOR,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Deutsch lernen macht Spaß! 🇩🇪',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      _getRandomGermanWord(),
                      key: ValueKey(_getRandomGermanWord()),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.MAINCOLOR,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRandomGermanWordTranslation(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 600 + (index * 200)),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ColorConstants.MAINCOLOR.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _getRandomGermanWord() {
    final words = [
      'Hallo',
      'Danke',
      'Bitte',
      'Guten Tag',
      'Auf Wiedersehen',
      'Ja',
      'Nein',
      'Entschuldigung',
      'Ich liebe Deutsch',
      'Wunderbar',
    ];
    return words[
        (DateTime.now().millisecondsSinceEpoch / 2000).floor() % words.length];
  }

  String _getRandomGermanWordTranslation() {
    final translations = [
      'Merhaba',
      'Teşekkürler',
      'Lütfen',
      'İyi günler',
      'Hoşça kal',
      'Evet',
      'Hayır',
      'Özür dilerim',
      'Almancayı seviyorum',
      'Mükemmel',
    ];
    return translations[(DateTime.now().millisecondsSinceEpoch / 2000).floor() %
        translations.length];
  }

  void _navigateToPdfDetail(Pdf pdf, File pdfFile) {
    if (!_isDisposed && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfDetailPage(
            pdf: pdf,
            pdfFile: pdfFile,
          ),
        ),
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
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
                          _isLoadingPdfs = true;
                          _pdfFiles.clear();
                          _pdfErrors.clear();
                        });
                        Navigator.pop(context);
                        _loadPdfsForSelectedLanguage();
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

    if (_premiumCheckCompleted && _isPremium == false) {
      return _buildNonPremiumMessage();
    }

    if (_isLoadingPdfs) {
      return _buildGermanLearningLoading();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(controller: _scrollController, slivers: [
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: false,
              backgroundColor: ColorConstants.MAINCOLOR,
              foregroundColor: ColorConstants.WHITE,
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
                            tag: 'pdfs_icon',
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
                                Icons.picture_as_pdf,
                                size: 30,
                                color: ColorConstants.MAINCOLOR,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Ders PDFleri',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ColorConstants.WHITE,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dil öğrenme PDFlerini keşfedin',
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
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                            child: CountryFlag.fromCountryCode(
                                              _languages
                                                  .firstWhere(
                                                    (lang) =>
                                                        lang['name'] ==
                                                        _selectedLanguage,
                                                    orElse: () =>
                                                        {'flagCode': 'TR'},
                                                  )['flagCode']!
                                                  .toUpperCase(),
                                              width: 28,
                                              height: 20,
                                              shape: const RoundedRectangle(4),
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
                                                  color:
                                                      _selectedLanguage != null
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
                                          ColorConstants.ACCENT_COLOR,
                                          ColorConstants.MAINCOLOR,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.picture_as_pdf,
                                      color: ColorConstants.WHITE,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'PDF Dersleri',
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
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Lütfen bir dil seçin',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : _loadedPdfs.isEmpty
                                      ? Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'Bu dilde PDF bulunamadı',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: _loadedPdfs.length +
                                              (_isLoadingMore ? 1 : 0),
                                          itemBuilder: (context, index) {
                                            if (index == _loadedPdfs.length &&
                                                _isLoadingMore) {
                                              return const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(4),
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            }

                                            final pdf = _loadedPdfs[index];
                                            final pdfId = pdf.id ??
                                                '${pdf.language}_${DateTime.now().millisecondsSinceEpoch}';
                                            final pdfFile = _pdfFiles[pdfId];
                                            final errorMessage =
                                                _pdfErrors[pdfId];

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 20),
                                              child: Container(
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: pdfFile != null
                                                        ? () =>
                                                            _navigateToPdfDetail(
                                                                pdf, pdfFile)
                                                        : null,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    pdf.name.isNotEmpty
                                                                        ? pdf
                                                                            .name
                                                                        : pdf
                                                                            .language,
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          18,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: ColorConstants
                                                                          .TEXT_COLOR,
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                  Text(
                                                                    pdf.language,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color: ColorConstants
                                                                          .TEXT_COLOR
                                                                          .withOpacity(
                                                                              0.6),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            if (pdfFile != null)
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 6,
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: ColorConstants
                                                                      .MAINCOLOR,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              20),
                                                                ),
                                                                child:
                                                                    const Text(
                                                                  'Detay',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 12),
                                                        if (errorMessage !=
                                                            null)
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(16),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .red[50],
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              border:
                                                                  Border.all(
                                                                color: Colors
                                                                    .red[200]!,
                                                              ),
                                                            ),
                                                            child: Column(
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .error_outline,
                                                                  color: Colors
                                                                      .red,
                                                                  size: 32,
                                                                ),
                                                                const SizedBox(
                                                                    height: 8),
                                                                Text(
                                                                  errorMessage,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    color: Colors
                                                                        .red,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                                const SizedBox(
                                                                    height: 12),
                                                                ElevatedButton
                                                                    .icon(
                                                                  onPressed:
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      _pdfErrors
                                                                          .remove(
                                                                              pdfId);
                                                                    });
                                                                    _initializePdfFile(
                                                                        pdfId,
                                                                        pdf);
                                                                  },
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .refresh,
                                                                      size: 16),
                                                                  label: const Text(
                                                                      'Yeniden Dene'),
                                                                  style: ElevatedButton
                                                                      .styleFrom(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .red,
                                                                    foregroundColor:
                                                                        Colors
                                                                            .white,
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .symmetric(
                                                                      horizontal:
                                                                          16,
                                                                      vertical:
                                                                          8,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          )
                                                        else if (pdfFile !=
                                                            null)
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                          0.1),
                                                                  blurRadius: 8,
                                                                  offset:
                                                                      const Offset(
                                                                          0, 4),
                                                                ),
                                                              ],
                                                            ),
                                                            child: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              child: SizedBox(
                                                                height: 200,
                                                                child: PDFView(
                                                                  filePath:
                                                                      pdfFile
                                                                          .path,
                                                                  autoSpacing:
                                                                      true,
                                                                  enableSwipe:
                                                                      false,
                                                                  swipeHorizontal:
                                                                      true,
                                                                  pageFling:
                                                                      false,
                                                                  onError:
                                                                      (error) {
                                                                    setState(
                                                                        () {
                                                                      _pdfErrors[
                                                                              pdfId] =
                                                                          'PDF görüntülenemedi: $error';
                                                                    });
                                                                  },
                                                                  onRender:
                                                                      (_pages) {
                                                                    // PDF rendered
                                                                  },
                                                                ),
                                                              ),
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
                                                            child: const Center(
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
                                                                    'PDF yükleniyor...',
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
                                        ),
                              if (!_hasMorePdfs && _loadedPdfs.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: ColorConstants.MAINCOLOR,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Tüm PDFler yüklendi',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
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
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
