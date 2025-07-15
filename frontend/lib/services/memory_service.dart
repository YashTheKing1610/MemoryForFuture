import 'dart:convert';
import 'package:http/http.dart' as http;

class MemoryService {
  static Future<List<Map<String, dynamic>>> fetchMemories(String profileId) async {
    final url = Uri.parse("http://your-api-url/get-memories/$profileId");

    try {
      final response = await http.get(url, headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map<Map<String, dynamic>>((memory) {
          return {
            'id': memory['id'],
            'title': memory['title'],
            'description': memory['description'],
            'file_type': _determineFileType(memory['file_path']),
            'file_url': _getFileUrl(memory['file_path']),
            'created_at': memory['created_at'],
            'collection': memory['collection'],
            'tags': memory['tags'] is String
                ? memory['tags'].split(',')
                : memory['tags'],
            'emotion': memory['emotion'],
            'is_favorite': memory['is_favorite'] ?? false,
          };
        }).toList();
      } else {
        throw Exception("Failed to load memories");
      }
    } catch (e) {
      throw Exception("Error fetching memories: $e");
    }
  }

  static String _getFileUrl(String filePath) {
    return 'https://yourstorageaccount.blob.core.windows.net/memories/$filePath';
  }

  static String _determineFileType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return 'image';
    if (['mp4', 'mov', 'avi'].contains(ext)) return 'video';
    if (['mp3', 'wav', 'm4a'].contains(ext)) return 'audio';
    if (['pdf', 'doc', 'docx', 'ppt', 'txt'].contains(ext)) return 'doc';
    return 'unknown';
  }
}
