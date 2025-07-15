import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MemoryVideosSection extends StatelessWidget {
  final List<Map<String, dynamic>> memories;
  final String profileId;
  final String username;

  const MemoryVideosSection({
    super.key,
    required this.memories,
    required this.profileId,
    required this.username,
  });

  List<Map<String, dynamic>> get videoMemories =>
      memories.where((m) => m['file_type'] == 'video').toList();

  @override
  Widget build(BuildContext context) {
    if (videoMemories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.white54),
            SizedBox(height: 12),
            Text("No video memories found.", style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: videoMemories.length,
      itemBuilder: (context, index) {
        final memory = videoMemories[index];
        return _VideoMemoryTile(memory: memory);
      },
    );
  }
}

class _VideoMemoryTile extends StatefulWidget {
  final Map<String, dynamic> memory;

  const _VideoMemoryTile({super.key, required this.memory});

  @override
  State<_VideoMemoryTile> createState() => _VideoMemoryTileState();
}

class _VideoMemoryTileState extends State<_VideoMemoryTile> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.memory['file_url'])
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          _initialized
              ? ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                )
              : Container(
                  height: 200,
                  color: Colors.white12,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  ),
                ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              widget.memory['title'] ?? 'Untitled Video',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
