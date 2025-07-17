import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'memory_views/memory_images_section.dart';
import 'memory_views/memory_videos_section.dart';
import 'memory_views/memory_audios_section.dart';
import 'memory_views/memory_docs_section.dart';
import 'memory_views/all_memories_view.dart';
import 'upload_memory_screen.dart';

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
  List<Map<String, dynamic>> memories = [];
  List<String> collections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    fetchMemories();
  }

  Future<void> fetchMemories() async {
    print("Fetching memories for profileId: ${widget.profileId}");

    final response = await http.get(
      Uri.parse('http://10.196.188.7:8000/get-memories/${widget.profileId}'),
   );


    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        memories = List<Map<String, dynamic>>.from(data);
        extractCollections();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print("Failed to load memories");
    }
  }

  void extractCollections() {
    final Set<String> collectionSet = {};
    for (var memory in memories) {
      final collection = memory['collection'];
      if (collection != null && collection.trim().isNotEmpty) {
        collectionSet.add(collection.trim());
      }
    }
    collections = collectionSet.toList();
  }

  void _createNewCollection() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _collectionName = TextEditingController();
        List<bool> selected = List.filled(memories.length, false);

        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text("Create New Collection", style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _collectionName,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Collection Name",
                      labelStyle: TextStyle(color: Colors.white60),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: memories.length,
                    itemBuilder: (context, index) {
                      final memory = memories[index];
                      return CheckboxListTile(
                        value: selected[index],
                        onChanged: (val) => setModalState(() => selected[index] = val!),
                        title: Text(
                          memory['title'] ?? 'Untitled',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        checkColor: Colors.black,
                        activeColor: Colors.cyanAccent,
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cancel", style: TextStyle(color: Colors.redAccent)),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text("Create"),
                onPressed: () {
                  final name = _collectionName.text.trim();
                  if (name.isEmpty || !selected.contains(true)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Please enter collection name & select memories"),
                      backgroundColor: Colors.redAccent,
                    ));
                    return;
                  }

                  setState(() {
                    for (int i = 0; i < selected.length; i++) {
                      if (selected[i]) {
                        memories[i]['collection'] = name;
                      }
                    }
                    collections.add(name);
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Collection created successfully 🎉"),
                    backgroundColor: Colors.green,
                  ));
                },
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildCollectionsRow() {
    if (collections.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: collections.length,
        itemBuilder: (context, index) {
          final collection = collections[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white12,
              border: Border.all(color: Colors.cyanAccent, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.folder, color: Colors.cyanAccent, size: 30),
                const SizedBox(height: 8),
                Text(
                  collection,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Memories of ${widget.username}',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
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
            icon: const Icon(Icons.add, color: Colors.cyanAccent),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Images"),
            Tab(text: "Videos"),
            Tab(text: "Audios"),
            Tab(text: "Documents"),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Your Collections", style: TextStyle(color: Colors.white70, fontSize: 16)),
                ElevatedButton.icon(
                  onPressed: _createNewCollection,
                  icon: const Icon(Icons.create_new_folder),
                  label: const Text("New Collection"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          _buildCollectionsRow(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        AllMemoriesView(profileId: widget.profileId, username: widget.username, memories: memories),
                        MemoryImagesSection(profileId: widget.profileId, username: widget.username, memories: memories),
                        MemoryVideosSection(profileId: widget.profileId, username: widget.username, memories: memories),
                        MemoryAudiosSection(profileId: widget.profileId, username: widget.username, memories: memories),
                        MemoryDocsSection(profileId: widget.profileId, username: widget.username, memories: memories),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
