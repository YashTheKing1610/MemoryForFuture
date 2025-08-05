import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:memory_for_future/screens/voice_clone_screen.dart';

class PersoVoiceChatScreen extends StatelessWidget {
  final String profileId;
  final String username;

  const PersoVoiceChatScreen({
    Key? key,
    required this.profileId,
    required this.username,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Voice-to-Voice with ${username}'s AI"),
        backgroundColor: Colors.black87,
      ),
      body: Center(
        child: Text(
          "Coming soon: Voice-to-voice chat using Azure Speech Services & PersoAI!",
          style: TextStyle(fontSize: 16, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ),
      backgroundColor: const Color(0xFF121212),
    );
  }
}

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
  final String apiBase = "http://127.0.0.1:8000";

  @override
  void dispose() {
    _controller.dispose();
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
      } else {
        setState(() {
          messages.add({"sender": "ai", "text": "⚠️ Error: ${response.statusCode}"});
        });
      }
    } catch (e) {
      setState(() {
        messages.add({"sender": "ai", "text": "⚠️ Exception: $e"});
      });
    }
  }

  void _gotoVoiceChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceCloneScreen(
          profileId: widget.profileId,
          username: widget.username,
        ),
      ),
    );
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
            tooltip: "Try Voice-to-Voice AI (PersoAI)",
            icon: const Icon(Icons.record_voice_over, color: Colors.lightGreenAccent),
            onPressed: _gotoVoiceChat,
          ),
        ],
      ),
      body: Column(
        children: [
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
                      color: isUser
                          ? Colors.lightBlueAccent.shade100
                          : const Color(0xFF2D2F41),
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
                      hintText: 'Ask something...',
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
                const SizedBox(width: 5),
              ],
            ),
          )
        ],
      ),
    );
  }
}
