import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'upload_memory_screen.dart';
import 'ai_chat_screen.dart'; // ✅ Make sure this import exists
import 'media_viewer_screen.dart';
import 'package:memory_for_future/models/memory.dart';


const String baseUrl = "http://127.0.0.1:8000"; // Update if deployed

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

  // 🔍 Debug each memory's fileType
  for (var m in memories) {
    print("DEBUG: ${m.fileType}");
  }
});

    } else {
      setState(() => isLoading = false);
      print("Failed to load memories");
    }
    print("Fetched memories: $memories");
  }

  List<Memory> filterByType(String type) {
  return memories.where((m) => m.fileType.toLowerCase().contains(type.toLowerCase())).toList();
  }


// ✅ Add this function here (around line 75)

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
        return GestureDetector(
          onTap: () => openMemory(memory),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.cyanAccent),
              borderRadius: BorderRadius.circular(12),
              image: memory.fileType == 'image'
                  ? DecorationImage(image: NetworkImage(memory.contentUrl), fit: BoxFit.cover)
                  : null,
              color: memory.fileType != 'image' ? Colors.black54 : null,
            ),
            alignment: Alignment.center,
            child: memory.fileType != 'image'
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        memory.fileType == 'video'
                            ? Icons.play_circle_fill
                            : memory.fileType == 'audio'
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
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
          IconButton( // ✅ AI Chat button added
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
                buildMemoryGrid(memories),
                buildMemoryGrid(filterByType('image')),
                buildMemoryGrid(filterByType('video')),
                buildMemoryGrid(filterByType('audio')),
                buildMemoryGrid(filterByType('document')),
              ],
            ),
    );
  }
}
