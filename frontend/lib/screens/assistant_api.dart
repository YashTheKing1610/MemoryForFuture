// frontend/lib/screens/assistant_api.dart

import 'package:http/http.dart' as http;


class AssistantApi {
final String baseUrl; // e.g. "http://192.168.31.83:8000"


AssistantApi(this.baseUrl);


Future<http.Response> startAssistant() {
 final uri = Uri.parse('$baseUrl/start-assistant');
 return http.post(uri);
  }


Future<http.Response> stopAssistant() {
 final uri = Uri.parse('$baseUrl/stop-assistant');
 return http.post(uri);
}
}