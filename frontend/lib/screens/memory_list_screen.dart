import 'package:flutter/material.dart';
import 'upload_memory_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MemoryListScreen extends StatefulWidget {
  final String profileId;
  final String username;

  const MemoryListScreen({
    Key? key,
    required this.profileId,
    required this.username,
  }) : super(key: key);

  @override
  State<MemoryListScreen> createState() => _MemoryListScreenState();
}

class _MemoryListScreenState extends State<MemoryListScreen> {
  String selectedTab = "All";
  List<Map<String, dynamic>> collections = [];
  List<Map<String, dynamic>> memories = [];
  bool isLoading = true;
  String? selectedCollection;

  final List<String> tabs = ["All", "Images", "Videos", "Audios"];

  @override
  void initState() {
    super.initState();
    fetchMemories();
  }

  Future<void> fetchMemories() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse("http://192.168.31.46:8000/get-memories/${widget.profileId}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("Fetched Memories: $data");

        setState(() {
          memories = data.map((e) => e as Map<String, dynamic>).toList();

          final collectionNames = memories
              .where((m) => m['collection'] != null && m['collection'].toString().isNotEmpty)
              .map((m) => m['collection'].toString())
              .toSet()
              .toList();

          collections = [
            {"name": "All Collections", "id": null},
            ...collectionNames.map((name) => {"name": name, "id": name}).toList()
          ];
        });
      } else {
        print("Failed to fetch memories: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching memories: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> getFilteredMemories() {
    List<Map<String, dynamic>> filtered = [...memories];

    if (selectedCollection != null) {
      filtered = filtered.where((m) => m['collection'] == selectedCollection).toList();
    }

    if (selectedTab == "Images") {
      filtered = filtered.where((m) {
        final file = (m['file_path'] ?? '').toString().toLowerCase();
        return file.endsWith('.jpg') || file.endsWith('.jpeg') || file.endsWith('.png') || file.endsWith('.gif');
      }).toList();
    } else if (selectedTab == "Videos") {
      filtered = filtered.where((m) {
        final file = (m['file_path'] ?? '').toString().toLowerCase();
        return file.endsWith('.mp4') || file.endsWith('.mov') || file.endsWith('.avi');
      }).toList();
    } else if (selectedTab == "Audios") {
      filtered = filtered.where((m) {
        final file = (m['file_path'] ?? '').toString().toLowerCase();
        return file.endsWith('.mp3') || file.endsWith('.wav') || file.endsWith('.m4a');
      }).toList();
    }

    return filtered;
  }

  void _createNewCollection() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Collection"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter collection name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UploadMemoryScreen(profileId: widget.profileId),
                  ),
                ).then((_) => fetchMemories());
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionCard(String name, String? id, {bool isNew = false}) {
    bool isSelected = selectedCollection == id;
    return GestureDetector(
      onTap: isNew
          ? _createNewCollection
          : () => setState(() {
                selectedCollection = isSelected ? null : id;
                if (selectedCollection == null) {
                  selectedTab = "All";
                }
              }),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white70,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isNew ? "+" : (collections.indexWhere((c) => c['id'] == id) + 1).toString().padLeft(2, '0'),
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isNew && id != null)
              Text(
                "${memories.where((m) => m['collection'] == id).length} items",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryCard(Map<String, dynamic> memory) {
    final String fileUrl = "https://<your_blob_url>/${memory['file_path']}";
    final isImage = fileUrl.toLowerCase().endsWith(".png") || fileUrl.toLowerCase().endsWith(".jpg");

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white10,
        image: isImage
            ? DecorationImage(
                image: NetworkImage(fileUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
              )
            : null,
      ),
      child: Stack(
        children: [
          if (!isImage)
            Center(
              child: Icon(Icons.insert_drive_file, color: Colors.white70, size: 40),
            ),
          Positioned(
            bottom: 8,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory['title'] ?? 'Untitled',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  memory['description'] ?? 'No description',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6E44FF), Color(0xFFE56B70)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Memory for Future",
                    style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UploadMemoryScreen(profileId: widget.profileId),
                        ),
                      ).then((_) => fetchMemories());
                    },
                    icon: const Icon(Icons.add, color: Colors.white, size: 30),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Welcome ${widget.username}, add a new memory!",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: tabs.map((tab) {
                    bool isSelected = tab == selectedTab;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () => setState(() => selectedTab = tab),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white70),
                          ),
                          child: Text(
                            tab,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),
              const Text("Collections", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...collections.map((col) => _buildCollectionCard(col['name'], col['id'])),
                    _buildCollectionCard("New Collection", null, isNew: true),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Memories", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("${getFilteredMemories().length} items", style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 10),

              isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : getFilteredMemories().isEmpty
                      ? const Center(child: Text("No memories found", style: TextStyle(color: Colors.white70)))
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: getFilteredMemories().length,
                          itemBuilder: (context, index) {
                            final memory = getFilteredMemories()[index];
                            return _buildMemoryCard(memory);
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }
}