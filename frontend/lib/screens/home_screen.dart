import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Adjust these imports according to your actual project structure:
import 'memory_list_screen.dart';
import 'upload_memory_screen.dart';
import 'ai_chat_screen.dart';

class Profile {
  final String id;
  final String name;
  final String relation;
  final String initial;
  final Color glowColor;

  Profile({
    required this.id,
    required this.name,
    required this.relation,
    required this.initial,
    required this.glowColor,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final name = json['name'] ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final glowColor = _colorForInitial(initial);
    return Profile(
      id: json['id'] ?? '',
      name: name,
      relation: json['relation'] ?? '',
      initial: initial,
      glowColor: glowColor,
    );
  }

  static Color _colorForInitial(String initial) {
    switch (initial) {
      case 'U':
        return Colors.cyanAccent;
      case 'Y':
        return Colors.pinkAccent;
      case 'M':
        return Colors.purpleAccent;
      default:
        return Colors.cyanAccent;
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final String baseUrl = 'http://127.0.0.1:8000';

  List<Profile> profiles = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _floatingAnimation;

  final math.Random _rand = math.Random();

  bool _darkMode = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get-profiles"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['profiles'] ?? [];
        setState(() {
          profiles = list.map((e) => Profile.fromJson(e)).toList();
        });
      }
    } catch (_) {
      // Silent error handler
    }
  }

  Future<void> _createProfile(String name, String relation) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/create-profile"),
        body: {"name": name, "relation": relation},
      );
      if (response.statusCode == 200) {
        await _loadProfiles();
        _showSnack("Profile created successfully");
      } else {
        final error = jsonDecode(response.body)['detail'] ?? 'Unknown error';
        _showSnack(error, isError: true);
      }
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _deleteProfile(String id) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/delete-profile/$id"));
      if (response.statusCode == 200) {
        await _loadProfiles();
        _showSnack("Profile deleted successfully");
      } else {
        final error = jsonDecode(response.body)['detail'] ?? 'Unknown error';
        _showSnack(error, isError: true);
      }
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

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
                labelText: 'Relation',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _nameController.text.trim();
              final relation = _relationController.text.trim();
              if (name.isEmpty || relation.isEmpty) {
                _showSnack('Please fill all fields.', isError: true);
                return;
              }
              _createProfile(name, relation);
              _nameController.clear();
              _relationController.clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
            ),
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showDeleteProfileDialog(Profile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text("Delete Profile", style: TextStyle(color: Colors.redAccent)),
        content: Text(
          "Are you sure you want to delete '${profile.name}' and all related data?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteProfile(profile.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // Neon glowing avatar for profiles
  Widget _buildGlowingAvatar(String initial, Color glowColor) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.65),
            blurRadius: 35,
            spreadRadius: 7,
          )
        ],
        gradient: RadialGradient(
          colors: [glowColor.withOpacity(0.7), Colors.black87],
          stops: const [0.5, 1.0],
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
          border: Border.all(color: glowColor, width: 3),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = LinearGradient(
                colors: [Colors.white, glowColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(const Rect.fromLTWH(0, 0, 52, 52)),
          ),
        ),
      ),
    );
  }

  // Build individual or add profile card
  Widget _buildProfileCard({
    required Profile profile,
    bool isAddCard = false,
    VoidCallback? onAddTap,
  }) {
    if (isAddCard) {
      return GestureDetector(
        onTap: onAddTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          width: 140,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: Colors.cyanAccent, width: 3),
            gradient: LinearGradient(
              colors: [Colors.cyanAccent.withOpacity(0.45), Colors.black.withOpacity(0.93)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.5),
                blurRadius: 35,
                spreadRadius: 5,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.cyanAccent.withOpacity(0.62),
                      Colors.cyanAccent.withOpacity(0.15),
                      Colors.transparent,
                    ],
                    stops: const [0.52, 0.77, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.6),
                      blurRadius: 35,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.add, size: 52, color: Colors.cyanAccent),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Add Profile",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                  shadows: [
                    Shadow(
                      color: Colors.cyanAccent.withOpacity(0.8),
                      blurRadius: 15,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Normal profile card
      return GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemoryListScreen(
                    profileId: profile.id, username: profile.name),
              ));
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          width: 140,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: profile.glowColor, width: 3),
            gradient: LinearGradient(
              colors: [
                profile.glowColor.withOpacity(0.45),
                Colors.black.withOpacity(0.93)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: profile.glowColor.withOpacity(0.6),
                blurRadius: 38,
                spreadRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  _buildGlowingAvatar(profile.initial, profile.glowColor),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: PopupMenuButton<String>(
                      color: Colors.black87,
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      icon: Icon(Icons.more_vert,
                          color: profile.glowColor.withOpacity(0.8)),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteProfileDialog(profile);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                profile.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: profile.glowColor,
                  shadows: [
                    Shadow(
                      color: profile.glowColor.withOpacity(0.77),
                      blurRadius: 18,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Sidebar with toggle and floating icons
  Widget _buildSidebar() {
    return Positioned(
      left: 0,
      top: 120,
      bottom: 120,
      width: 54,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () => setState(() => _darkMode = !_darkMode),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _darkMode ? Colors.cyanAccent : Colors.grey.shade700,
                boxShadow: [
                  if (_darkMode)
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.5),
                      blurRadius: 18,
                      spreadRadius: 6,
                    ),
                ],
              ),
              width: 44,
              height: 44,
              child: Center(
                child: Icon(
                  _darkMode ? Icons.nights_stay : Icons.wb_sunny,
                  color: _darkMode ? Colors.black : Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sidebarIcon(Icons.public, Colors.cyanAccent),
          const SizedBox(height: 18),
          _sidebarIcon(Icons.settings, Colors.pinkAccent),
          const SizedBox(height: 18),
          _sidebarIcon(Icons.history, Colors.purpleAccent),
        ],
      ),
    );
  }

  Widget _sidebarIcon(IconData iconData, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.6), color.withOpacity(0.15)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 20,
            spreadRadius: 9,
          ),
        ],
      ),
      child: Icon(iconData, color: Colors.white, size: 22),
    );
  }

  // Subtle glowing (random) background particles for cosmic effect
  List<Widget> _buildBackgroundParticles() {
    final List<Widget> particles = [];
    for (int i = 0; i < 22; i++) {
      final double size = 10 + _rand.nextDouble() * 22;
      final left =
          20 + _rand.nextDouble() * (MediaQuery.of(context).size.width - size - 40);
      final top =
          20 + _rand.nextDouble() * (MediaQuery.of(context).size.height - size - 40);
      final List<Color> baseColors = [
        Colors.cyanAccent,
        Colors.pinkAccent,
        Colors.purpleAccent,
      ];
      final Color color =
          baseColors[_rand.nextInt(baseColors.length)].withOpacity(0.25 + _rand.nextDouble() * 0.15);

      particles.add(Positioned(
        left: left,
        top: top,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withOpacity(0),
              ],
              stops: const [0.5, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: color,
                blurRadius: size * 2,
                spreadRadius: size * 0.6,
              ),
            ],
          ),
        ),
      ));
    }

    // Large glowing orbs at fixed positions - subtle cosmic feel
    particles.add(Positioned(
      left: 10,
      top: 100,
      child: _largeGlowingOrb(120, Colors.cyanAccent.withOpacity(0.55)),
    ));
    particles.add(Positioned(
      right: 10,
      top: 300,
      child: _largeGlowingOrb(150, Colors.purpleAccent.withOpacity(0.47)),
    ));

    return particles;
  }

  Widget _largeGlowingOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 70, spreadRadius: 18),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF050618), Color(0xFF0A0F25)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Background glowing particles
          ..._buildBackgroundParticles(),

          // Sidebar on left
          _buildSidebar(),

          // Main UI content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Title with gradient neon glow
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Colors.cyanAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    "MemoryFor\nFuture",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(
                      fontWeight: FontWeight.w900,
                      fontSize: 48,
                      height: 1.05,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Subtitle text
                Text(
                  "Sync memories across space and time",
                  style: GoogleFonts.rajdhani(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.6,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 48),

                // Profiles horizontal scroll row
                SizedBox(
                  height: 220,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    children: [
                      for (var profile in profiles)
                        _buildProfileCard(profile: profile),
                      _buildProfileCard(
                          profile: Profile(
                            id: 'add',
                            name: '',
                            relation: '',
                            initial: '+',
                            glowColor: Colors.pinkAccent,
                          ),
                          isAddCard: true,
                          onAddTap: _showCreateProfileDialog),
                    ],
                  ),
                ),

                const Spacer(),

                // Big glowing floating "+" button bottom center
                Center(
                  child: GestureDetector(
                    onTap: _showCreateProfileDialog,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.cyanAccent.withOpacity(0.85),
                            Colors.cyanAccent.withOpacity(0.15),
                            Colors.transparent,
                          ],
                          stops: const [0.5, 0.75, 1],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.6),
                            blurRadius: 50,
                            spreadRadius: 15,
                          )
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
