import 'package:flutter/material.dart';

class MemoryCard extends StatelessWidget {
  final Map<String, dynamic> memory;
  final VoidCallback onTap;

  const MemoryCard({super.key, required this.memory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fileType = memory['file_type'];
    final fileUrl = memory['file_url'];

    Widget previewWidget;

    if (fileType == 'image') {
      previewWidget = ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Image.network(
          fileUrl,
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 50, color: Colors.grey),
        ),
      );
    } else {
      IconData icon = Icons.insert_drive_file;
      if (fileType == 'video') icon = Icons.videocam;
      if (fileType == 'audio') icon = Icons.audiotrack;
      if (fileType == 'doc') icon = Icons.description;

      previewWidget = Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          color: Colors.grey[900],
        ),
        child: Center(child: Icon(icon, size: 40, color: Colors.white70)),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            previewWidget,
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                memory['title'] ?? "Untitled",
                style: const TextStyle(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
      ),
    );
  }
}
