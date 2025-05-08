import 'package:flutter/material.dart';
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

class _VideoDetailPageState extends State<VideoDetailPage> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.play();
  }

  @override
  void dispose() {
    widget.controller.pause();
    _noteController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ders ${widget.video.key}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: widget.controller.value.aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: VideoPlayer(widget.controller),
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Not Al',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Notunuzu buraya yazın...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Soru Sor',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Sorunuzu buraya yazın...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Add logic to save note or question to Firestore if needed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Not ve soru kaydedildi')),
                );
                _noteController.clear();
                _questionController.clear();
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
