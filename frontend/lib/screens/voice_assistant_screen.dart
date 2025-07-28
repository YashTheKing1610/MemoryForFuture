import 'package:flutter/material.dart';
import '../services/azure_stt_service.dart';
import '../services/ai_chat_service.dart';
import '../services/azure_tts_service.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({Key? key}) : super(key: key);

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final AzureSTTService _sttService = AzureSTTService();
  final AiChatService _aiService = AiChatService();
  final AzureTTSService _ttsService = AzureTTSService();

  String userText = '';
  String aiReply = '';
  bool isListening = false;
  bool isProcessing = false;

  void _toggleListening() async {
    if (isListening) {
      await _sttService.stopListening();
      setState(() => isListening = false);
    } else {
      setState(() {
        isListening = true;
        userText = '';
        aiReply = '';
        isProcessing = false;
      });
      await _sttService.startListening((text, {isFinal = false}) async {
        setState(() => userText = text);
        if (isFinal) {
          setState(() => isProcessing = true);
          final reply = await _aiService.getChatReply(text);
          setState(() {
            aiReply = reply;
            isProcessing = false;
          });
          await _ttsService.speak(reply);
        }
      });
    }
  }

  @override
  void dispose() {
    _sttService.stopListening();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('AI Voice Chat')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isListening ? "Listening..." : "Press the mic to start speaking.",
              style: const TextStyle(fontSize: 18, color: Colors.cyanAccent),
            ),
            const SizedBox(height: 18),
            Text(
              'You: $userText',
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            const Divider(height: 36, thickness: 1, color: Colors.grey),
            if (isProcessing)
              const CircularProgressIndicator(color: Colors.cyanAccent)
            else
              Text(
                'AI: $aiReply',
                style: const TextStyle(fontSize: 20, color: Colors.greenAccent),
              ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _toggleListening,
              icon: Icon(isListening ? Icons.mic_off : Icons.mic),
              label: Text(isListening ? 'Stop Listening' : 'Start Speaking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isListening ? Colors.redAccent : Colors.cyanAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(210, 48),
                textStyle: const TextStyle(fontSize: 17),
              ),
            )
          ],
        ),
      ),
    );
  }
}
