// E:\MemoryForFuture\frontend\lib\screens\media_viewer_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for arrow key detection
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import '../models/memory.dart';

/// Fetch text content for .txt files
Future<String> fetchTextFile(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return response.body;
  }
  throw Exception('Failed to load text file');
}

/// Helper: Robust file type detection (EXTENDED: audio)
bool isImage(String fileType) {
  final t = fileType.toLowerCase();
  return t.contains('image') ||
      ['jpg','jpeg','png','gif','bmp','webp','heic'].any(t.contains);
}
bool isVideo(String fileType) {
  final t = fileType.toLowerCase();
  return t.contains('video') ||
      ['mp4','mov','mkv','avi','webm','m4v','mpeg'].any(t.contains);
}
bool isAudio(String fileType) {
  final t = fileType.toLowerCase();
  return t.contains('audio') ||
      ['mp3','wav','aac','m4a','ogg','oga','flac','opus','m4b'].any(t.contains);
}
bool isPdf(String fileType) {
  final t = fileType.toLowerCase();
  return t.contains('pdf');
}
bool isText(String fileType) {
  final t = fileType.toLowerCase();
  return t.contains('txt') ||
      t.contains('text') ||
      t.contains('plain');
}
bool isDocument(String fileType) {
  final t = fileType.toLowerCase();
  return isPdf(t) ||
      t.contains('doc') ||
      t.contains('docx') ||
      isText(t) ||
      t.contains('rtf') ||
      t.contains('ppt') ||
      t.contains('pptx') ||
      t.contains('xls') ||
      t.contains('xlsx') ||
      t.contains('csv');
}

class MediaViewerScreen extends StatefulWidget {
  final List<Memory> memories;
  final int initialIndex;
  const MediaViewerScreen({
    Key? key,
    required this.memories,
    required this.initialIndex,
  }) : super(key: key);
  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late int currentIndex;
  late FocusNode _focusNode;
  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _showNext() {
    setState(() {
      currentIndex = (currentIndex + 1) % widget.memories.length;
    });
  }

  void _showPrevious() {
    setState(() {
      currentIndex = (currentIndex - 1 + widget.memories.length) % widget.memories.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memories[currentIndex];
    final fileType = memory.fileType.toLowerCase();
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _showNext();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _showPrevious();
          }
        }
      },
      child: _buildMedia(context, memory, fileType),
    );
  }

  Widget _buildMedia(BuildContext context, Memory memory, String fileType) {
    if (isImage(fileType)) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: Text(memory.title)),
        body: Center(
          child: Image.network(
            memory.contentUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.broken_image)),
          ),
        ),
      );
    }
    if (isVideo(fileType)) {
      return VideoPlayerScreen(url: memory.contentUrl, title: memory.title);
    }
    if (isAudio(fileType)) {
      return AudioPlayerScreen(url: memory.contentUrl, title: memory.title);
    }
    if (isPdf(fileType)) {
      return Scaffold(
        appBar: AppBar(title: Text(memory.title)),
        body: SfPdfViewer.network(memory.contentUrl),
      );
    }
    if (isText(fileType)) {
      return Scaffold(
        appBar: AppBar(title: Text(memory.title)),
        body: FutureBuilder<String>(
          future: fetchTextFile(memory.contentUrl),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Failed to load text content.'));
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
            label: const Text('Open Document'),
            onPressed: () async {
              final result = await OpenFile.open(memory.contentUrl);
              if (result.type != ResultType.done) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Could not open document.'),
                ));
              }
            },
          ),
        ),
      );
    }
    // Unsupported type
    return Scaffold(
      appBar: AppBar(title: const Text('Unsupported')),
      body: const Center(child: Text('Unsupported file type')),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  const VideoPlayerScreen({Key? key, required this.url, required this.title})
      : super(key: key);
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
    MediaKit.ensureInitialized();
    _player = Player();
    _controller = VideoController(_player);
    _player.open(Media(widget.url));
    _player.stream.playing.listen((playing) {
      setState(() => _isPlaying = playing);
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
  const AudioPlayerScreen({Key? key, required this.url, required this.title})
      : super(key: key);
  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late final Player _player;
  bool _isPlaying = false;
  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized();
    _player = Player();
    _player.open(Media(widget.url));
    _player.stream.playing.listen((playing) {
      setState(() => _isPlaying = playing);
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
          icon: Icon(
            _isPlaying ? Icons.pause_circle : Icons.play_circle,
            size: 80,
            color: Colors.cyanAccent,
          ),
          onPressed: togglePlay,
        ),
      ),
    );
  }
}
