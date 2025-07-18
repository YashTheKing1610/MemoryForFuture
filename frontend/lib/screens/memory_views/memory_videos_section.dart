import 'package:flutter/material.dart';
import '../memory_viewer_screen.dart';

class MemoryVideosSection extends StatelessWidget {
  final String profileId;
  final String username;
  final List<Map<String, dynamic>> memories;

  const MemoryVideosSection({
    super.key,
    required this.profileId,
    required this.username,
    required this.memories,
  });

  @override
  Widget build(BuildContext context) {
    final videoMemories = memories.where((m) => m['file_type'] == 'video').toList();

    if (videoMemories.isEmpty) {
      return const Center(
        child: Text("No video memories found", style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: videoMemories.length,
      itemBuilder: (context, index) {
        final memory = videoMemories[index];
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
                  fileType: 'video',
                ),
              ),
            );
          },
          child: Card(
            color: Colors.white12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.videocam, color: Colors.cyanAccent),
              title: Text(memory['title'] ?? 'Untitled', style: const TextStyle(color: Colors.white)),
              subtitle: Text(memory['description'] ?? '', style: const TextStyle(color: Colors.white54)),
              trailing: const Icon(Icons.play_circle_fill, color: Colors.cyanAccent),
            ),
          ),
        );
      },
    );
  }
}
