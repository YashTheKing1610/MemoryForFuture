import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';

class AllMemoriesView extends StatelessWidget {
  final List<Map<String, dynamic>> memories;
  final String profileId;
  final String username;

  const AllMemoriesView({
    super.key,
    required this.memories,
    required this.profileId,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.memory, size: 64, color: Colors.white54),
            SizedBox(height: 12),
            Text("No memories found.", style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: memories.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Text(
              "All Memories of $username",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          );
        }

        final memory = memories[index - 1];
        final fileType = memory['file_type'];

        switch (fileType) {
          case 'image':
            return _buildImageTile(memory);
          case 'video':
            return _buildVideoTile(context, memory);
          case 'audio':
            return _buildAudioTile(memory);
          case 'doc':
            return _buildDocTile(memory);
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildImageTile(Map<String, dynamic> memory) {
    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            memory['file_url'],
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, color: Colors.white54),
          ),
        ),
        title: Text(
          memory['title'] ?? 'Untitled Image',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: const Text('📷 Image Memory', style: TextStyle(color: Colors.white54)),
      ),
    );
  }

  Widget _buildVideoTile(BuildContext context, Map<String, dynamic> memory) {
    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.videocam, color: Colors.white),
        title: Text(
          memory['title'] ?? 'Untitled Video',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: const Text('🎥 Video Memory', style: TextStyle(color: Colors.white54)),
        onTap: () => _launchUrl(memory['file_url']),
      ),
    );
  }

  Widget _buildAudioTile(Map<String, dynamic> memory) {
    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.audiotrack, color: Colors.white),
        title: Text(
          memory['title'] ?? 'Untitled Audio',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: const Text('🎵 Audio Memory', style: TextStyle(color: Colors.white54)),
        onTap: () => _playAudio(memory['file_url']),
      ),
    );
  }

  Widget _buildDocTile(Map<String, dynamic> memory) {
    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file, color: Colors.white),
        title: Text(
          memory['title'] ?? 'Untitled Document',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: const Text('📄 Document Memory', style: TextStyle(color: Colors.white54)),
        onTap: () => _launchUrl(memory['file_url']),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _playAudio(String url) async {
    final player = AudioPlayer();
    await player.play(UrlSource(url));
  }
}
