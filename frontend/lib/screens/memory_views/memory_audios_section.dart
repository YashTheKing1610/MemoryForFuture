import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MemoryAudiosSection extends StatelessWidget {
  final List<Map<String, dynamic>> memories;
  final String profileId;
  final String username;

  const MemoryAudiosSection({
    super.key,
    required this.memories,
    required this.profileId,
    required this.username,
  });

  List<Map<String, dynamic>> get audioMemories =>
      memories.where((m) => m['file_type'] == 'audio').toList();

  @override
  Widget build(BuildContext context) {
    if (audioMemories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.audiotrack, size: 64, color: Colors.white54),
            SizedBox(height: 12),
            Text(
              "No audio memories found.",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: audioMemories.length,
      itemBuilder: (context, index) {
        final memory = audioMemories[index];
        return _AudioMemoryTile(memory: memory);
      },
    );
  }
}

class _AudioMemoryTile extends StatefulWidget {
  final Map<String, dynamic> memory;

  const _AudioMemoryTile({super.key, required this.memory});

  @override
  State<_AudioMemoryTile> createState() => _AudioMemoryTileState();
}

class _AudioMemoryTileState extends State<_AudioMemoryTile> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      await _audioPlayer.setUrl(widget.memory['file_url']);
    } catch (_) {
      // You could log or show error if needed
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    _isPlaying ? _audioPlayer.pause() : _audioPlayer.play();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.music_note, color: Colors.white),
        title: Text(
          widget.memory['title'] ?? 'Untitled Audio',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        trailing: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: _togglePlayPause,
              ),
      ),
    );
  }
}
