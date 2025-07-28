import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiChatService {
  final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final String _endpoint = 'https://api.openai.com/v1/chat/completions';

  Future<String> getChatReply(String userInput) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-4",
        "messages": [
          {"role": "user", "content": userInput}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['choices'][0]['message']['content'] ?? 'No response available.';
    } else {
      return 'Sorry, I could not get a response at this time.';
    }
  }
}
