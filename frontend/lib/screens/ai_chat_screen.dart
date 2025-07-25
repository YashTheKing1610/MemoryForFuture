import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:media_kit/media_kit.dart';

late final Player _player; // Global (can be moved into state)

class AiChatScreen extends StatefulWidget {
  final String profileId;
  final String username;

  const AiChatScreen({
    Key? key,
    required this.profileId,
    required this.username,
  }) : super(key: key);

  @override
  _AiChatScreenState createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  bool _isCloning = false;
  bool _isSynthesizing = false;
  String? _voiceId;

  Player? _audioPlayer;

  final String apiBase = "http://127.0.0.1:8000"; // Replace with your backend address

  @override
  void initState() {
    super.initState();
    // Initialize media_kit player here if needed, or on demand before playback
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> sendMessage(String message) async {
    setState(() {
      messages.add({"sender": "user", "text": message});
    });

    try {
      final url = Uri.parse("$apiBase/ai/ask");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "question": message,
          "profile_id": widget.profileId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data["response"];

        setState(() {
          messages.add({"sender": "ai", "text": reply});
        });

        // If voiceId is available, synthesize and play voice reply!
        if (_voiceId != null) {
          await _speakWithClone(reply, _voiceId!);
        }
      } else {
        setState(() {
          messages.add({
            "sender": "ai",
            "text": "⚠️ Error: ${response.statusCode}"
          });
        });
      }
    } catch (e) {
      setState(() {
        messages.add({"sender": "ai", "text": "⚠️ Exception: $e"});
      });
    }
  }

  Future<void> _pickAndCloneVoice() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      final File voiceFile = File(result.files.single.path!);
      await _cloneVoice(voiceFile);
    }
  }

  Future<void> _cloneVoice(File audioFile) async {
    setState(() => _isCloning = true);
    try {
      var req = http.MultipartRequest("POST", Uri.parse('$apiBase/clone-voice/'));
      req.files.add(await http.MultipartFile.fromPath("audio", audioFile.path));
      req.fields['language'] = "en";
      var respStream = await req.send();
      var resp = await http.Response.fromStream(respStream);
      if (resp.statusCode == 200) {
        var result = jsonDecode(resp.body);
        setState(() {
          _voiceId = result["voice_id"] ?? result["id"];
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Voice cloned! Ready for voice replies.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Voice cloning failed: ${resp.reasonPhrase}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Voice cloning failed: $e")));
    } finally {
      setState(() => _isCloning = false);
    }
  }

  Future<void> _speakWithClone(String text, String voiceId) async {
    setState(() => _isSynthesizing = true);
    try {
      var req = http.MultipartRequest("POST", Uri.parse('$apiBase/speak-with-clone/'));
      req.fields['voice_id'] = voiceId;
      req.fields['text'] = text;
      req.fields['language'] = "en";

      var respStream = await req.send();

      final contentType = respStream.headers['content-type'] ?? '';
      if (contentType.contains("application/json")) {
        final body = await respStream.stream.transform(utf8.decoder).join();
        final decoded = jsonDecode(body);
        String? url = decoded['url'];
        if (url != null) {
          await _playAudioUrl(url);
        }
      } else {
        // Play audio bytes
        final data = await respStream.stream.toBytes();
        await _playAudioBytes(data);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("AI voice synth failed: $e")));
    } finally {
      setState(() => _isSynthesizing = false);
    }
  }

  Future<void> _playAudioBytes(List<int> data) async {
    await _audioPlayer?.dispose();
    _audioPlayer = Player();
    // Create a temp file to play - media_kit does not support playing bytes directly
    // So you MUST write bytes to a temp file and play from file path
    // We implement that below:

    final tempDir = Directory.systemTemp;
    final tempFile = await File('${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.wav').create();
    await tempFile.writeAsBytes(data);

    await _audioPlayer!.open(Media(tempFile.path));
    await _audioPlayer!.play();
  }

  Future<void> _playAudioUrl(String url) async {
    await _audioPlayer?.dispose();
    _audioPlayer = Player();
    await _audioPlayer!.open(Media(url));
    await _audioPlayer!.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Row(
          children: [
            const Icon(Icons.smart_toy, color: Colors.cyanAccent),
            const SizedBox(width: 8),
            Text(
              "Chat with ${widget.username}'s AI 🤖",
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Voice Chat",
            icon: Icon(Icons.mic, color: _voiceId != null ? Colors.purple : Colors.white70),
            onPressed: _isCloning ? null : _pickAndCloneVoice,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isCloning)
            const LinearProgressIndicator(
              color: Colors.purple,
              backgroundColor: Colors.black,
              minHeight: 4,
            ),
          if (_isSynthesizing)
            const LinearProgressIndicator(
              color: Colors.cyanAccent,
              backgroundColor: Colors.black,
              minHeight: 4,
            ),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.lightBlueAccent.shade100 : const Color(0xFF2D2F41),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                      ),
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: TextStyle(
                        color: isUser ? Colors.black87 : Colors.cyanAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        sendMessage(value.trim());
                        _controller.clear();
                      }
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _voiceId != null
                          ? 'Type or send to hear AI in your voice...'
                          : 'Ask something...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.cyanAccent),
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      sendMessage(text);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
