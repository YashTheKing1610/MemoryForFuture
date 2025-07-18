import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';

class MemoryViewerScreen extends StatefulWidget {
  final String title;
  final String fileType;
  final String fileUrl;

  const MemoryViewerScreen({
    super.key,
    required this.title,
    required this.fileType,
    required this.fileUrl,
  });

  @override
  State<MemoryViewerScreen> createState() => _MemoryViewerScreenState();
}

class _MemoryViewerScreenState extends State<MemoryViewerScreen> {
  late VideoPlayerController _videoController;
  late AudioPlayer _audioPlayer;
  String? localPdfPath;
  bool isLoading = true;
  String errorMsg = "";

  @override
  void initState() {
    super.initState();
    loadMedia();
  }

  Future<void> loadMedia() async {
    try {
      if (widget.fileType == "video") {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.fileUrl));
        await _videoController.initialize();
        _videoController.setLooping(true);
        _videoController.play();
      } else if (widget.fileType == "audio") {
        _audioPlayer = AudioPlayer();
        await _audioPlayer.setUrl(widget.fileUrl);
        _audioPlayer.play();
      } else if (widget.fileType == "document") {
        final response = await http.get(Uri.parse(widget.fileUrl));
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File("${dir.path}/temp.pdf");
        await file.writeAsBytes(bytes, flush: true);
        localPdfPath = file.path;
      }
    } catch (e) {
      errorMsg = "Failed to load ${widget.fileType}: $e";
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    if (widget.fileType == "video") {
      _videoController.dispose();
    } else if (widget.fileType == "audio") {
      _audioPlayer.dispose();
    }
    super.dispose();
  }

  Widget getMediaView() {
    if (widget.fileType == "image") {
      return Image.network(widget.fileUrl, fit: BoxFit.contain);
    } else if (widget.fileType == "video") {
      return _videoController.value.isInitialized
          ? AspectRatio(
              aspectRatio: _videoController.value.aspectRatio,
              child: VideoPlayer(_videoController),
            )
          : const Center(child: CircularProgressIndicator());
    } else if (widget.fileType == "audio") {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.audiotrack, size: 100, color: Colors.cyanAccent),
          SizedBox(height: 20),
          Text("Playing audio...", style: TextStyle(color: Colors.white70, fontSize: 18)),
        ],
      );
    } else if (widget.fileType == "document") {
      if (localPdfPath == null) {
        return const Center(child: Text("Failed to load PDF", style: TextStyle(color: Colors.redAccent)));
      }
      return PDFView(
        filePath: localPdfPath!,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: true,
        pageFling: true,
        onError: (e) => setState(() => errorMsg = "PDF Error: $e"),
      );
    } else {
      return const Center(child: Text("Unsupported file type", style: TextStyle(color: Colors.redAccent)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : errorMsg.isNotEmpty
              ? Center(child: Text(errorMsg, style: const TextStyle(color: Colors.redAccent)))
              : Center(child: getMediaView()),
    );
  }
}
