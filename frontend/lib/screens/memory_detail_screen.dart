import 'package:flutter/material.dart';

class MemoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> memory;

  const MemoryDetailScreen({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(memory['title'] ?? 'Memory Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              memory['title'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Description: ${memory['description'] ?? ''}"),
            const SizedBox(height: 10),
            Text("Tags: ${memory['tags'] ?? ''}"),
            const SizedBox(height: 10),
            Text("Emotion: ${memory['emotion'] ?? ''}"),
            const SizedBox(height: 10),
            Text("Collection: ${memory['collection'] ?? ''}"),
            const SizedBox(height: 20),
            if (memory['file_url'] != null && memory['file_type'] == 'image')
              Image.network(memory['file_url']),
            if (memory['file_type'] == 'video')
              const Text("Video playback not supported yet"),
            if (memory['file_type'] == 'audio')
              const Text("Audio playback not supported yet"),
          ],
        ),
      ),
    );
  }
}
