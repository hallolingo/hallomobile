import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/data/models/video_model.dart';
import 'package:hallomobil/pages/videos/video_detail_page.dart';
import 'package:video_player/video_player.dart';
import 'package:country_flags/country_flags.dart';

class VideosPage extends StatefulWidget {
  const VideosPage({super.key});

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  List<Map<String, String?>> _languages = [];
  String? _selectedLanguage;
  Map<String, VideoPlayerController?> _controllers = {};
  Map<String, String?> _videoErrors = {};

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
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );
      _controllers[videoId] = controller;
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VideoDetailPage(video: video, controller: controller),
      ),
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
              child: DropdownButtonFormField<String>(
                value: _selectedLanguage,
                decoration: const InputDecoration(
                  labelText: 'Dil Seçin',
                  border: OutlineInputBorder(),
                ),
                items: _languages.map((language) {
                  return DropdownMenuItem<String>(
                    value: language['name'],
                    child: Row(
                      children: [
                        if (language['flagCode'] != null)
                          Container(
                            margin: const EdgeInsets.only(right: 10),
                            child: CountryFlag.fromCountryCode(
                              language['flagCode']!.toUpperCase(),
                              width: 24,
                              height: 18,
                              shape: const Rectangle(),
                            ),
                          ),
                        Text(language['name'] ?? 'Bilinmeyen Dil'),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLanguage = newValue;
                    _controllers.forEach((key, controller) {
                      controller?.dispose();
                    });
                    _controllers.clear();
                    _videoErrors.clear();
                  });
                },
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

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  'Ders ${video.key}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
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
                                        height:
                                            150, // Reduced height for smaller video
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
                                                  child:
                                                      VideoPlayer(controller),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                controller.value.isPlaying
                                                    ? Icons.pause
                                                    : Icons.play_arrow,
                                                size: 50,
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  if (controller
                                                      .value.isPlaying) {
                                                    controller.pause();
                                                  } else {
                                                    controller.play();
                                                  }
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      const SizedBox(
                                        height: 150,
                                        child: Center(
                                            child: CircularProgressIndicator()),
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
