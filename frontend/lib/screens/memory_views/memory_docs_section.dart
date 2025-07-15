import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MemoryDocsSection extends StatelessWidget {
  final List<Map<String, dynamic>> memories;
  final String profileId;
  final String username; // ✅ Added

  const MemoryDocsSection({
    super.key,
    required this.memories,
    required this.profileId,
    required this.username, // ✅ Added
  });

  List<Map<String, dynamic>> get docMemories =>
      memories.where((m) => m['file_type'] == 'doc').toList();

  @override
  Widget build(BuildContext context) {
    if (docMemories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.insert_drive_file, size: 64, color: Colors.white54),
            SizedBox(height: 12),
            Text(
              "No document memories found.",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: docMemories.length,
      itemBuilder: (context, index) {
        final memory = docMemories[index];
        return _DocMemoryCard(memory: memory);
      },
    );
  }
}

class _DocMemoryCard extends StatelessWidget {
  final Map<String, dynamic> memory;

  const _DocMemoryCard({super.key, required this.memory});

  Future<void> _launchDoc(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('❌ Could not launch $url');
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text("Could not open document."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file, color: Colors.white),
        title: Text(
          memory['title'] ?? 'Untitled Document',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
        onTap: () => _launchDoc(memory['file_url']),
      ),
    );
  }
}

// Global navigator key to use SnackBar from stateless widget
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
