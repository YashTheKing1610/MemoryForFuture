import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'upload_memory_screen.dart';
import 'memory_list_screen.dart';
import 'create_profile_screen.dart'; // Import your new stepper screen

class Profile {
  final String id;
  final String name;
  final String relation;

  Profile({required this.id, required this.name, required this.relation});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      name: json['name'],
      relation: json['relation'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Profile> profiles = [];

  final String baseUrl = 'http://127.0.0.1:8000';

  @override
  void initState() {
    super.initState();
    fetchProfiles();
  }

  Future<void> fetchProfiles() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/get-profiles/"));
      if (res.statusCode == 200) {
        final List data = json.decode(res.body)['profiles'];
        setState(() {
          profiles = data.map((p) => Profile.fromJson(p)).toList();
        });
      }
    } catch (e) {
      // Handle fetch error (optional)
    }
  }

  Future<void> deleteProfile(String profileId) async {
    try {
      final res = await http.delete(Uri.parse("$baseUrl/delete-profile/$profileId"));
      if (res.statusCode == 200) {
        fetchProfiles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile deleted permanently ✅")),
        );
      } else {
        final error = json.decode(res.body)['detail'] ?? "Unknown error";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error"), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteConfirmation(Profile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text("Delete Profile", style: TextStyle(color: Colors.redAccent)),
        content: Text(
          "Are you sure you want to delete '${profile.name}' and all its data permanently?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              deleteProfile(profile.id);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Text(
                "Who are you remembering today?",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: profiles.length + 1,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 30,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    if (index == profiles.length) {
                      // Add Profile Button
                      return InkWell(
                        onTap: () async {
                          // Route to stepper create profile screen
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateProfileScreen(),
                            ),
                          );
                          // If profile created, refresh list!
                          if (result == true) fetchProfiles();
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: Colors.grey[700]!,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 40,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Add Profile",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blueAccent.withOpacity(0.8),
                                      Colors.purpleAccent.withOpacity(0.8),
                                    ],
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
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      _showDeleteConfirmation(profile);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete Profile'),
                                    ),
                                  ],
                                  icon: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.more_vert,
                                      size: 18,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            profile.name,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.relation,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
