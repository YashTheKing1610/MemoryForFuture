import 'package:flutter/material.dart';
import '../memory_viewer_screen.dart';

class AllMemoriesView extends StatelessWidget {
  final String profileId;
  final String username;
  final List<Map<String, dynamic>> memories;

  const AllMemoriesView({
    super.key,
    required this.profileId,
    required this.username,
    required this.memories,
  });

  IconData _getIconForType(String fileType) {
    switch (fileType) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      case 'document':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) {
      return const Center(
        child: Text("No memories found", style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        final memory = memories[index];
        final fileType = memory['file_type'];
        final filePath = memory['file_path'];
        final fileUrl = "https://memoryforfuture.blob.core.windows.net/$filePath";

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemoryViewerScreen(
                  fileUrl: fileUrl,
                  title: memory['title'] ?? 'Untitled',
                  fileType: fileType,
                ),
              ),
            );
          },
          child: Card(
            color: Colors.white12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(_getIconForType(fileType), color: Colors.cyanAccent),
              title: Text(memory['title'] ?? 'Untitled', style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                memory['description'] ?? '',
                style: const TextStyle(color: Colors.white54),
              ),
              trailing: const Icon(Icons.open_in_new, color: Colors.cyanAccent),
            ),
          ),
        );
      },
    );
  }
}
