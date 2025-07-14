import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  String _response = "";
  bool _isLoading = false;

  Future<void> sendQuery(String query) async {
    setState(() {
      _isLoading = true;
      _response = "";
    });
    
   // const apiUrl = "http://192.168.31.46:8000/voice-chat"; // ← your actual IP address
    const apiUrl = "http://127.0.0.1:8000/voice-chat"; // your backend endpoint
    final profileId = "testuser001"; // use the correct profile_id

    final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.fields['profile_id'] = profileId;
    request.fields['question'] = query;

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _response = data['response_text'];
        });
      } else {
        setState(() {
          _response = "Error: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _response = "Failed to connect: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Voice Assistant")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Ask me anything...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: sendQuery,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => sendQuery(_controller.text),
              child: const Text("Send"),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Text(
                _response,
                style: const TextStyle(fontSize: 18),
              ),
          ],
        ),
      ),
    );
  }
}
