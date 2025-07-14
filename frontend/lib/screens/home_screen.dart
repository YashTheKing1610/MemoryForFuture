import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'upload_memory_screen.dart';
import 'memory_list_screen.dart';

class Profile {
  final String id;
  final String name;
  final String relation;

  Profile({required this.id, required this.name, required this.relation});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Profile> profiles = [
    Profile(id: '1', name: 'Yash', relation: 'Myself'),
    Profile(id: '2', name: 'Usman', relation: 'Friend'),
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();

  void _showCreateProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text("Create Profile", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            TextField(
              controller: _relationController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Your Relation with Them',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                profiles.add(Profile(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _nameController.text.trim(),
                  relation: _relationController.text.trim(),
                ));
              });
              _nameController.clear();
              _relationController.clear();
              Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(Profile profile) {
    final TextEditingController renameController = TextEditingController(text: profile.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text("Rename Profile", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: renameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'New Name',
            labelStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final index = profiles.indexOf(profile);
                profiles[index] = Profile(
                  id: profile.id,
                  name: renameController.text.trim(),
                  relation: profile.relation,
                );
              });
              Navigator.pop(context);
            },
            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  void _removeProfile(Profile profile) {
    setState(() {
      profiles.remove(profile);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Icon(Icons.memory, color: Colors.pinkAccent),
            const SizedBox(width: 8),
            Text("MemoryForFuture",
                style: GoogleFonts.montserrat(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyanAccent))
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text(
            "Select a profile or create a new one",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: profiles.length + 1,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3 / 4.2,
              ),
              itemBuilder: (context, index) {
                if (index == profiles.length) {
                  return DottedBorder(
                    dashPattern: [6, 3],
                    color: Colors.grey,
                    strokeWidth: 1.5,
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(16),
                    child: InkWell(
                      onTap: _showCreateProfileDialog,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.purpleAccent, size: 48),
                            SizedBox(height: 8),
                            Text("Add Profile", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final profile = profiles[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MemoryListScreen(
                          profileId: profile.id,
                          username: profile.name,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF292B73), Color(0xFF191B4D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person, size: 48, color: Colors.purpleAccent),
                              const SizedBox(height: 12),
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                profile.relation,
                                style: const TextStyle(fontSize: 14, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'rename') {
                                _showRenameDialog(profile);
                              } else if (value == 'remove') {
                                _removeProfile(profile);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'rename', child: Text('Rename')),
                              const PopupMenuItem(value: 'remove', child: Text('Remove')),
                            ],
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}