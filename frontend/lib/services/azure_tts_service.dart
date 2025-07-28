import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AzureTTSService {
  final String _speechKey = dotenv.env['AZURE_SPEECH_KEY'] ?? '';
  final String _region = dotenv.env['AZURE_REGION'] ?? '';
  final AudioPlayer _player = AudioPlayer();

  Future<void> speak(String text) async {
    final ttsUrl = 'https://$_region.tts.speech.microsoft.com/cognitiveservices/v1';

    final headers = {
      'Ocp-Apim-Subscription-Key': _speechKey,
      'Content-Type': 'application/ssml+xml',
      'X-Microsoft-OutputFormat': 'audio-16khz-32kbitrate-mono-mp3',
      'User-Agent': 'MemoryForFutureApp',
    };

    final ssml = '''
    <speak version='1.0' xml:lang='en-US'>
      <voice xml:lang='en-US' name='en-US-JennyNeural'>$text</voice>
    </speak>
    ''';

    final response = await http.post(Uri.parse(ttsUrl), headers: headers, body: ssml);

    if (response.statusCode == 200) {
      Uint8List audioBytes = response.bodyBytes;

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(audioBytes);

      await _player.setFilePath(tempFile.path);
      await _player.play();
    } else {
      throw Exception('Azure TTS failed with status code ${response.statusCode}');
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
