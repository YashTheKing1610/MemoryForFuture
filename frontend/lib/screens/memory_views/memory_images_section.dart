import 'package:flutter/material.dart';

class MemoryImagesSection extends StatelessWidget {
  final List<Map<String, dynamic>> memories;
  final String profileId;
  final String username;

  const MemoryImagesSection({
    super.key,
    required this.memories,
    required this.profileId,
    required this.username,
  });

  List<Map<String, dynamic>> get imageMemories =>
      memories.where((m) => m['file_type'] == 'image').toList();

  @override
  Widget build(BuildContext context) {
    if (imageMemories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.image_not_supported, size: 64, color: Colors.white54),
            SizedBox(height: 12),
            Text("No image memories found.", style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: imageMemories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final memory = imageMemories[index];

        return GestureDetector(
          onTap: () {
            // Future memory detail navigation
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    memory['file_url'],
                    height: 150,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 150,
                        color: Colors.white12,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.cyanAccent),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.white12,
                      child: const Icon(Icons.broken_image, color: Colors.white54),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    memory['title'] ?? 'Untitled',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
