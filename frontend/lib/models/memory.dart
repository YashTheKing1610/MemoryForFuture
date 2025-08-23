//E:\MemoryForFuture\frontend\lib\models\memory.dart

class Memory {
  final String title;
  final String filePath;
  final String fileType;
  final String contentUrl;

  Memory({
    required this.title,
    required this.filePath,
    required this.fileType,
    required this.contentUrl,
  });

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      title: json['title'] ?? '',
      filePath: json['file_path'] ?? '',
      fileType: json['file_type'] ?? '',
      contentUrl: json['content_url'] ?? '',
    );
  }
}
