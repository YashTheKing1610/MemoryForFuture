import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'upload_memory_screen.dart';
import 'memory_list_screen.dart';
import 'create_profile_screen.dart';

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
    } catch (e) {}
  }

  Future<void> deleteProfile(String profileId) async {
    try {
      final res = await http.delete(Uri.parse("$baseUrl/delete-profile/$profileId"));
      if (res.statusCode == 200) {
        fetchProfiles();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile deleted permanently ✅")),
        );
      } else {
        final error = json.decode(res.body)['detail'] ?? "Unknown error";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error"), backgroundColor: Colors.red),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  int getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 950) return 3;
    if (width > 650) return 2;
    return 1;
  }

  Widget buildProfileCard(Profile profile) {
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF95997),          // memory_for_future pink
                const Color(0xFFB195FC),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF95997).withOpacity(.13),
                blurRadius: 32,
                spreadRadius: 5,
              ),
            ],
          ),
          child: InkWell(
            splashColor: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(36),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(37),
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(.11),
                              const Color(0xFFF95997).withOpacity(0.21),
                              Colors.transparent,
                            ],
                            stops: const [0.35, 0.73, 1],
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _showDeleteConfirmation(profile);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete Profile',
                                  style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                          color: Colors.grey[900],
                          icon: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.44),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(.13),
                                    blurRadius: 2)
                              ],
                            ),
                            child: const Icon(Icons.more_vert, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    profile.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 22,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    profile.relation,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(.89),
                      fontSize: 16,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAddProfileCard() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        margin: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF232137),
              Color(0xFF35376C),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(.10),
              blurRadius: 16,
              spreadRadius: 3,
            ),
          ],
          border: Border.all(
            color: Colors.white12,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateProfileScreen(),
              ),
            );
            if (result == true) fetchProfiles();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF95997), Color(0xFFB195FC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 34),
                ),
                const SizedBox(height: 22),
                Text(
                  "Add Profile",
                  style: GoogleFonts.montserrat(
                    fontSize: 19,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Create a new memory',
                  style: GoogleFonts.montserrat(
                      color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    int crossAxisCount = getCrossAxisCount(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              decoration: const BoxDecoration(
                  color: Color(0xFFFD62B0), shape: BoxShape.circle),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.favorite, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              "MemoryForFuture",
              style: GoogleFonts.montserrat(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFD62B0),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        centerTitle: false,
        toolbarHeight: 65,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF95997).withOpacity(0.21),
                    Colors.transparent
                  ],
                  radius: 0.8,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 330,
              height: 190,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF43264A).withOpacity(0.09),
                    Colors.transparent
                  ],
                  radius: 0.9,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFB195FC).withOpacity(0.17),
                    Colors.transparent
                  ],
                  radius: 0.9,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: width > 1250 ? 1100 : (width > 950 ? 900 : 650)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 36),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.montserrat(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      children: [
                        const TextSpan(text: 'Who are you '),
                        TextSpan(
                            text: 'remembering ',
                            style: GoogleFonts.montserrat(
                              color: Color(0xFFF95997), // main pink theme highlight
                              fontWeight: FontWeight.w900,
                            )),
                        const TextSpan(text: 'today?'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Preserve precious memories and honor the special people in your life.\nCreate lasting tributes that celebrate their impact on your journey.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: profiles.length + 1,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 32,
                          mainAxisSpacing: 36,
                          childAspectRatio: 1.13),
                      itemBuilder: (context, index) {
                        if (index == profiles.length) {
                          return buildAddProfileCard();
                        }
                        return buildProfileCard(profiles[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
