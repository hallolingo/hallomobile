import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hallomobil/app_router.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/data/models/video_model.dart';
import 'package:video_player/video_player.dart'; // video_player paketini kullan
import 'package:country_flags/country_flags.dart';

class VideosPage extends StatefulWidget {
  const VideosPage({super.key});

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  List<Map<String, String?>> _languages = [];
  String? _selectedLanguage;
  Map<String, VideoPlayerController?> _controllers =
      {}; // VideoPlayerController kullan
  Map<String, String?> _videoErrors = {};
  Map<String, bool> _videoCacheStatus = {}; // Cache durumunu takip et

  @override
  void initState() {
    super.initState();
    _fetchLanguages();
  }

  Future<void> _fetchLanguages() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('languages').get();
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
    } catch (e) {
      print('Diller çekilirken hata oluştu: $e');
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) {
      controller?.dispose();
    });
    super.dispose();
  }

  Future<void> _initializeVideoController(
      String videoId, String videoUrl) async {
    try {
      // VideoPlayerController ile network'ten video yükle
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: {
          'Cache-Control': 'max-age=86400', // 24 saat cache
          'User-Agent': 'Flutter App',
        },
      );

      _controllers[videoId] = controller;

      // Video yüklenme durumunu takip et
      controller.addListener(() {
        if (controller.value.isInitialized &&
            !_videoCacheStatus.containsKey(videoId)) {
          setState(() {
            _videoCacheStatus[videoId] = true; // Cache edildi olarak işaretle
          });
        }
      });

      await controller.initialize();
      _videoErrors.remove(videoId);
      setState(() {});
    } catch (e) {
      print('Video yüklenirken hata oluştu (ID: $videoId): $e');
      _videoErrors[videoId] = 'Video yüklenemedi: $e';
      _controllers[videoId] = null;
      setState(() {});
    }
  }

  void _navigateToVideoDetail(Video video, VideoPlayerController controller) {
    Navigator.pushNamed(
      context,
      AppRouter.videoDetail,
      arguments: {
        'video': video,
        'controller': controller,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.WHITE,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ColorConstants.WHITE,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Ders Videoları'),
      ),
      body: Column(
        children: [
          if (_languages.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ColorConstants.MAINCOLOR.withOpacity(0.1),
                      ColorConstants.WHITE,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ColorConstants.MAINCOLOR.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.language,
                              color: ColorConstants.MAINCOLOR.withOpacity(0.7),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Öğrenmek istediğiniz dili seçin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 5,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedLanguage,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: InputBorder.none,
                            hintText: 'Dil seçiniz...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                          dropdownColor: Colors.white,
                          icon: Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey.shade600,
                              size: 24,
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          items: _languages.map((language) {
                            return DropdownMenuItem<String>(
                              value: language['name'],
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (language['flagCode'] != null)
                                    Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
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
                                  Flexible(
                                    child: Text(
                                      language['name'] ?? 'Bilinmeyen Dil',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedLanguage = newValue;
                              // Eski controller'ları temizle
                              _controllers.forEach((key, controller) {
                                controller?.dispose();
                              });
                              _controllers.clear();
                              _videoErrors.clear();
                              _videoCacheStatus.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          Expanded(
            child: _selectedLanguage == null
                ? const Center(child: Text('Lütfen bir dil seçin'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('videos')
                        .where('language', isEqualTo: _selectedLanguage)
                        .orderBy('key')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Hata: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final videos = snapshot.data!.docs.map((doc) {
                        return Video.fromJson(
                            doc.data() as Map<String, dynamic>)
                          ..id = doc.id;
                      }).toList();

                      if (videos.isEmpty) {
                        return const Center(
                            child: Text('Bu dilde video bulunamadı'));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          final video = videos[index];
                          final videoId =
                              video.id ?? 'default_${index.toString()}';

                          if (!_controllers.containsKey(videoId) &&
                              !_videoErrors.containsKey(videoId)) {
                            _initializeVideoController(videoId, video.videoUrl);
                          }

                          final controller = _controllers[videoId];
                          final errorMessage = _videoErrors[videoId];
                          final isCached = _videoCacheStatus[videoId] ?? false;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  children: [
                                    Text(
                                      'Ders ${video.key}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                color: ColorConstants.WHITE,
                                elevation: 0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (errorMessage != null)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          errorMessage,
                                          style: const TextStyle(
                                              color: Colors.red),
                                        ),
                                      )
                                    else if (controller != null &&
                                        controller.value.isInitialized)
                                      SizedBox(
                                        height: 200,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            AspectRatio(
                                              aspectRatio:
                                                  controller.value.aspectRatio,
                                              child: GestureDetector(
                                                onTap: () =>
                                                    _navigateToVideoDetail(
                                                        video, controller),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: VideoPlayer(
                                                      controller), // VideoPlayer kullan
                                                ),
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.5),
                                                shape: BoxShape.circle,
                                              ),
                                              child: IconButton(
                                                icon: Icon(
                                                  controller.value.isPlaying
                                                      ? Icons.pause
                                                      : Icons.play_arrow,
                                                  size: 50,
                                                  color: Colors.white,
                                                ),
                                                onPressed: () {
                                                  _navigateToVideoDetail(
                                                      video, controller);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        height: 150,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              CircularProgressIndicator(),
                                              SizedBox(height: 8),
                                              Text(
                                                'Video yükleniyor...',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
