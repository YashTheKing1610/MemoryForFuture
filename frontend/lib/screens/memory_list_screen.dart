import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'upload_memory_screen.dart';
import 'ai_chat_screen.dart';
import 'media_viewer_screen.dart';
import 'package:memory_for_future/models/memory.dart';

const String baseUrl = "http://127.0.0.1:8000"; // Update if needed

class MemoryListScreen extends StatefulWidget {
  final String profileId;
  final String username;

  const MemoryListScreen({
    super.key,
    required this.profileId,
    required this.username,
  });

  @override
  State<MemoryListScreen> createState() => _MemoryListScreenState();
}

class _MemoryListScreenState extends State<MemoryListScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Memory> memories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    fetchMemories();
  }

  Future<void> fetchMemories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/get-memories/${widget.profileId}'),
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        memories = data.map((m) => Memory.fromJson(m)).toList();
        isLoading = false;
        // Debug file types:
        for (var m in memories) {
          print("DEBUG: Memory title=${m.title}, fileType=${m.fileType}");
        }
      });
    } else {
      setState(() => isLoading = false);
      print("Failed to load memories");
    }
  }

  // Helper methods to detect media types robustly
  bool isImage(String fileType) => fileType.toLowerCase().contains('image');
  bool isVideo(String fileType) => fileType.toLowerCase().contains('video');
  bool isAudio(String fileType) => fileType.toLowerCase().contains('audio');
  bool isDocument(String fileType) {
    final type = fileType.toLowerCase();
    return type.contains('pdf') || type.contains('doc') || type.contains('text') || type.contains('plain');
  }

  List<Memory> filterByType(String type) {
    if (type.toLowerCase() == 'all') return memories;
    switch (type.toLowerCase()) {
      case 'image':
        return memories.where((m) => isImage(m.fileType)).toList();
      case 'video':
        return memories.where((m) => isVideo(m.fileType)).toList();
      case 'audio':
        return memories.where((m) => isAudio(m.fileType)).toList();
      case 'document':
        return memories.where((m) => isDocument(m.fileType)).toList();
      default:
        return memories;
    }
  }

  void openMemory(Memory memory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaViewerScreen(memory: memory),
      ),
    );
  }

  Widget buildMemoryGrid(List<Memory> memoryList) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10,
      ),
      itemCount: memoryList.length,
      itemBuilder: (context, index) {
        final memory = memoryList[index];
        final fileType = memory.fileType.toLowerCase();
        return GestureDetector(
          onTap: () => openMemory(memory),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.cyanAccent),
              borderRadius: BorderRadius.circular(12),
              image: isImage(fileType)
                  ? DecorationImage(image: NetworkImage(memory.contentUrl), fit: BoxFit.cover)
                  : null,
              color: !isImage(fileType) ? Colors.black54 : null,
            ),
            alignment: Alignment.center,
            child: !isImage(fileType)
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isVideo(fileType)
                            ? Icons.play_circle_fill
                            : isAudio(fileType)
                                ? Icons.audiotrack
                                : Icons.insert_drive_file,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        memory.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Memories of ${widget.username}",
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.cyanAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UploadMemoryScreen(
                    profileId: widget.profileId,
                    username: widget.username,
                  ),
                ),
              ).then((_) => fetchMemories());
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.cyanAccent),
            tooltip: 'Chat with AI',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AiChatScreen(
                    profileId: widget.profileId,
                    username: widget.username,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Images"),
            Tab(text: "Videos"),
            Tab(text: "Audios"),
            Tab(text: "Documents"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : TabBarView(
              controller: _tabController,
              children: [
                buildMemoryGrid(filterByType('all')),
                buildMemoryGrid(filterByType('image')),
                buildMemoryGrid(filterByType('video')),
                buildMemoryGrid(filterByType('audio')),
                buildMemoryGrid(filterByType('document')),
              ],
            ),
    );
  }
}
