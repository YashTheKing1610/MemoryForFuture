import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:memory_for_future/models/memory.dart';

class MediaViewerScreen extends StatelessWidget {
  final Memory memory;

  const MediaViewerScreen({Key? key, required this.memory}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fileType = memory.fileType.toLowerCase();
    print('DEBUG: fileType = $fileType');

    if (fileType.contains('image')) {
      return Scaffold(
        appBar: AppBar(title: Text(memory.title)),
        backgroundColor: Colors.black,
        body: Center(
          child: Image.network(memory.contentUrl, fit: BoxFit.contain),
        ),
      );
    } else if (fileType.contains('video')) {
      return VideoPlayerScreen(url: memory.contentUrl, title: memory.title);
    } else if (fileType.contains('audio')) {
      return AudioPlayerScreen(url: memory.contentUrl, title: memory.title);
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text("Unsupported")),
        body: const Center(child: Text("Unsupported file type")),
      );
    }
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const VideoPlayerScreen({required this.url, required this.title});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _controller.play();
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}

class AudioPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const AudioPlayerScreen({required this.url, required this.title});

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setSourceUrl(widget.url);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void togglePlay() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
    setState(() => isPlaying = !isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 64),
          onPressed: togglePlay,
        ),
      ),
    );
  }
}
