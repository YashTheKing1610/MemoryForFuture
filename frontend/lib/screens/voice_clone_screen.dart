import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceCloneScreen extends StatefulWidget {
  final String profileId;
  final String username;

  const VoiceCloneScreen({
    Key? key,
    required this.profileId,
    required this.username,
  }) : super(key: key);

  @override
  _VoiceCloneScreenState createState() => _VoiceCloneScreenState();
}

class _VoiceCloneScreenState extends State<VoiceCloneScreen> {
  bool isRecording = false;
  bool isUploading = false;
  String status = "Tap to start recording";
  String recordingPath = "";
  Timer? _timer;
  int _elapsedSeconds = 0;
  final Record _recorder = Record();

  Future<String> getTempFilePath(String name) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/$name.wav';
  }

  void _startTimer() {
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatTime(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) {
      setState(() => status = "Microphone permission denied");
      return;
    }

    final path = await getTempFilePath("sample_${widget.profileId}");
    await _recorder.start(
      path: path,
      encoder: AudioEncoder.wav,
      bitRate: 128000,
      samplingRate: 44100,
    );

    setState(() {
      isRecording = true;
      recordingPath = path;
      status = "Recording...";
    });

    _startTimer();
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
    _stopTimer();

    setState(() {
      isRecording = false;
      status = "Recording complete. Ready to upload.";
    });
  }

  Future<void> uploadRecording() async {
    if (recordingPath.isEmpty) return;

    try {
      setState(() {
        isUploading = true;
        status = "Uploading...";
      });

      final uri = Uri.parse("http://127.0.0.1:8000/upload-voice");
      final file = File(recordingPath);
      final request = http.MultipartRequest('POST', uri)
        ..fields['user_id'] = widget.profileId
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        setState(() => status = "✅ Voice uploaded successfully");
      } else {
        setState(() => status = "❌ Upload failed: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => status = "❌ Error: $e");
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeDisplay = _formatTime(_elapsedSeconds);

    return Scaffold(
      appBar: AppBar(
        title: Text("Voice Cloning for ${widget.username}"),
        backgroundColor: Colors.black87,
      ),
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              status,
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (isRecording)
              Text(
                "Recording: $timeDisplay",
                style: const TextStyle(color: Colors.redAccent, fontSize: 18),
              ),
            const SizedBox(height: 30),
            if (!isRecording)
              ElevatedButton.icon(
                onPressed: isUploading ? null : startRecording,
                icon: const Icon(Icons.mic),
                label: const Text("Start Recording"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            if (isRecording)
              ElevatedButton.icon(
                onPressed: stopRecording,
                icon: const Icon(Icons.stop),
                label: const Text("Stop Recording"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: (!isRecording && recordingPath.isNotEmpty && !isUploading)
                  ? uploadRecording
                  : null,
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload Voice Sample"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
