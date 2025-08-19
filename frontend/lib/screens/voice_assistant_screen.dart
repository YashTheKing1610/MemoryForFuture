import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';

class VoiceAssistantScreen extends StatefulWidget {
  @override
  _VoiceAssistantScreenState createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final Record _recorder = Record();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  String _status = "Tap mic to talk";

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/input.wav';
      await _recorder.start(path: path);
      setState(() {
        _isRecording = true;
        _status = "Listening...";
      });
    }
  }

  Future<void> _stopAndSend() async {
    final inputPath = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _status = "Processing...";
    });

    if (inputPath != null) {
      final uri = Uri.parse('http://127.0.0.1:8000/voice-chat-once/');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', inputPath));

      final response = await request.send();
      final bytes = await response.stream.toBytes();

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final outputPath = '${dir.path}/reply.wav';
        File(outputPath).writeAsBytesSync(bytes);
        setState(() {
          _status = "Replying...";
        });
        await _player.setFilePath(outputPath);
        await _player.play();
        setState(() {
          _status = "Tap mic to talk";
        });
      } else {
        setState(() {
          _status = "Error: ${response.statusCode}";
        });
      }
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                if (_isRecording) {
                  _stopAndSend();
                } else {
                  _startRecording();
                }
              },
              child: CircleAvatar(
                radius: 44,
                backgroundColor: _isRecording ? Colors.red : Colors.cyan,
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
