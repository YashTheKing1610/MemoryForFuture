import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:mic_stream/mic_stream.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

typedef OnTranscription = void Function(String text, {bool isFinal});

class AzureSTTService {
  Stream<Uint8List>? _micStream;
  StreamSubscription<Uint8List>? _micSubscription;
  WebSocketChannel? _channel;
  bool _listening = false;

  Future<void> _initMicStream() async {
    _micStream = await MicStream.microphone(
      audioSource: AudioSource.DEFAULT,
      sampleRate: 16000,
      channelConfig: ChannelConfig.CHANNEL_IN_MONO,
      audioFormat: AudioFormat.ENCODING_PCM_16BIT,
    );
  }

  // TODO: Implement proper Azure Speech token acquisition here!
  Future<String> getAzureSpeechToken() async {
    // For now, empty string (not recommended for production).
    return "";
  }

  Future<void> startListening(OnTranscription onText) async {
    if (_listening) return;
    _listening = true;

    final azureRegion = dotenv.env['AZURE_REGION'] ?? '';
    final token = await getAzureSpeechToken();

    final wsUrl =
        'wss://$azureRegion.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=en-US&format=detailed' +
            (token.isNotEmpty ? '&authorization=bearer $token' : '');

    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    final configMsg = jsonEncode({
      'context': {
        'system': {'version': '1.0.00000'}
      }
    });
    _channel!.sink.add(configMsg);

    _channel!.stream.listen((dynamic data) {
      try {
        final decoded = jsonDecode(data);
        if (decoded['DisplayText'] != null) {
          onText(decoded['DisplayText'], isFinal: true);
        } else if (decoded['Text'] != null) {
          onText(decoded['Text'], isFinal: false);
        }
      } catch (_) {
        // ignore non-JSON messages
      }
    }, onDone: stopListening, onError: (e) => stopListening());

    await _initMicStream();
    _micSubscription = _micStream!.listen((audio) {
      if (_listening && _channel != null) {
        _channel!.sink.add(audio);
      }
    });
  }

  Future<void> stopListening() async {
    if (!_listening) return;
    await _micSubscription?.cancel();
    await _channel?.sink.close();
    _listening = false;
  }
}
