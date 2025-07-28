import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit/video.dart';
import 'package:media_kit/video_player.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit/video_player.dart';
import 'package:media_kit/video_player.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit/video_player.dart';

import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:memory_for_future/models.dart'; // adjust import to your actual model path

// Helper to fetch text content from URL for displaying .txt files inline
Future<String> fetchTextFile(String url) async {
  final resp = await http.get(Uri.parse(url));
  if (resp.statusCode == 200) {
    return resp.body;
  }
  throw Exception('Failed to load text file');
}

class MediaViewerScreen extends StatelessWidget {
  final Memory memory;

  const MediaViewerScreen({Key? key, required this.memory}) : super(key: key);

  bool isDocument(String fileType) {
    final type = fileType.toLowerCase();
    return type.contains('pdf') ||
        type.contains('doc') ||
        type.contains('docx') ||
        type.contains('txt') ||
        type.contains('text') ||
        type.contains('rtf') ||
        type.contains('plain');
  }

  @override
  Widget build(BuildContext context) {
    final fileType = memory.fileType.toLowerCase();

    if (fileType.contains('image')) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: Text(memory.title)),
        body: Center(child: Image.network(memory.contentUrl, fit: BoxFit.contain)),
      );
    }

    if (fileType.contains('video')) {
      return VideoPlayerScreen(url: memory.contentUrl, title: memory.title);
    }

    if (fileType.contains('audio') ||
        fileType.contains('mpeg') ||
        fileType.contains('mp3') ||
        fileType.contains('wav') ||
        fileType.contains('aac')) {
      return AudioPlayerScreen(url: memory.contentUrl, title: memory.title);
    }

    if (fileType.contains('pdf')) {
      return Scaffold(
        appBar: AppBar(title: Text(memory.title)),
        body: SfPdfViewer.network(memory.contentUrl),
      );
    }

    if (fileType.contains('txt') || fileType.contains('text') || fileType.contains('plain')) {
      return Scaffold(
        appBar: AppBar(title: Text(memory.title)),
        body: FutureBuilder<String>(
          future: fetchTextFile(memory.contentUrl),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text("Failed to load text content."));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(snapshot.data ?? ''),
            );
          },
        ),
      );
    }

    if (isDocument(fileType)) {
      return Scaffold(
        appBar: AppBar(title: Text(memory.title)),
        body: Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text("Open Document"),
            onPressed: () async {
              final result = await OpenFile.open(memory.contentUrl);
              if (result.type != ResultType.done) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Could not open document"),
                ));
              }
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Unsupported")),
      body: const Center(child: Text("Unsupported file type")),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const VideoPlayerScreen({Key? key, required this.url, required this.title}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized(); // **Important!**

    _player = Player();
    _controller = VideoController(_player);
    _player.open(Media(widget.url));
    _player.stream.playing.listen((playing) {
      setState(() {
        _isPlaying = playing;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Video(controller: _controller),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_isPlaying) {
            await _player.pause();
          } else {
            await _player.play();
          }
        },
        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}

class AudioPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const AudioPlayerScreen({Key? key, required this.url, required this.title}) : super(key: key);

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late final Player _player;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized(); // **Important!**

    _player = Player();
    _player.open(Media(widget.url));
    _player.stream.playing.listen((playing) {
      setState(() {
        _isPlaying = playing;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: IconButton(
          icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle,
              size: 80, color: Colors.cyanAccent),
          onPressed: togglePlay,
        ),
      ),
    );
  }
}
