import 'package:flutter/material.dart';
import '../memory_viewer_screen.dart';

class MemoryImagesSection extends StatelessWidget {
  final String profileId;
  final String username;
  final List<Map<String, dynamic>> memories;

  const MemoryImagesSection({
    super.key,
    required this.profileId,
    required this.username,
    required this.memories,
  });

  @override
  Widget build(BuildContext context) {
    final imageMemories = memories.where((m) => m['file_type'] == 'image').toList();

    if (imageMemories.isEmpty) {
      return const Center(child: Text("No image memories found", style: TextStyle(color: Colors.white70)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: imageMemories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final memory = imageMemories[index];
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
                  fileType: 'image',
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(fileUrl),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
          ),
        );
      },
    );
  }
}
