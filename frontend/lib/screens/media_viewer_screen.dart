import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:memory_for_future/models/memory.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;

// Helper for inline TXT rendering
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
    // Checks for "pdf", "doc", "docx", "txt", "rtf", "text", "plain"
    final type = fileType.toLowerCase();
    return type.contains('pdf') ||
        type.contains('doc') ||
        type.contains('docx') ||
        type.contains('text') ||
        type.contains('plain') ||
        type.contains('txt') ||
        type.contains('rtf');
  }

  @override
  Widget build(BuildContext context) {
    final fileType = memory.fileType.toLowerCase();

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
    } else if (fileType.contains('audio') ||
        fileType.contains('mpeg') ||
        fileType.contains('mp3') ||
        fileType.contains('wav') ||
        fileType.contains('aac')) {
      return AudioPlayerScreen(url: memory.contentUrl, title: memory.title);
    } else if (fileType.contains('pdf')) {
      // Inline PDF viewer
      return Scaffold(
        appBar: AppBar(title: Text(memory.title)),
        backgroundColor: Colors.black,
        body: SfPdfViewer.network(memory.contentUrl),
      );
    } else if (fileType.contains('txt') || fileType.contains('plain') || fileType.contains('text')) {
      // Inline text viewer
      return Scaffold(
        appBar: AppBar(title: Text(memory.title)),
        body: FutureBuilder<String>(
          future: fetchTextFile(memory.contentUrl),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading file'));
            } else {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(18.0),
                child: SelectableText(
                  snapshot.data ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }
          },
        ),
      );
    } else if (fileType.contains('doc') || fileType.contains('docx') || fileType.contains('rtf')) {
      // Open via OpenFile
      return Scaffold(
        appBar: AppBar(title: Text(memory.title)),
        body: Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Document'),
            onPressed: () async {
              final result = await OpenFile.open(memory.contentUrl);
              if (result.type != ResultType.done) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open document')),
                );
              }
            },
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text("Unsupported")),
        body: const Center(child: Text("Unsupported file type")),
      );
    }
  }
}

// --- Video and Audio Player Screens (Unchanged from your code) ---

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const VideoPlayerScreen({required this.url, required this.title});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _player.open(Media(widget.url));
    _player.stream.playing.listen((playing) => setState(() => _isPlaying = playing));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      backgroundColor: Colors.black,
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

  const AudioPlayerScreen({required this.url, required this.title});

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late final Player _player;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _player.open(Media(widget.url));
    _player.stream.playing.listen((playing) => setState(() => _isPlaying = playing));
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
      appBar: AppBar(title: Text(widget.title)),
      backgroundColor: Colors.black,
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
