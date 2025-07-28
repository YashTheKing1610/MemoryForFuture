import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'upload_memory_screen.dart';
import 'ai_chat_screen.dart';
import 'media_viewer_screen.dart';
import 'package:memory_for_future/models/memory.dart';

const String baseUrl = "http://127.0.0.1:8000";

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

class _MemoryListScreenState extends State<MemoryListScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  List<Memory> memories = [];
  bool isLoading = true;

  final List<String> tabs = ['ALL', 'IMAGES', 'VIDEOS', 'AUDIOS', 'DOCUMENTS'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    fetchMemories();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _tabController = null;
    super.dispose();
  }

  Future<void> fetchMemories() async {
    setState(() => isLoading = true);
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/get-memories/${widget.profileId}'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          memories = data.map((m) => Memory.fromJson(m)).toList();
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to load memories'),
            backgroundColor: Colors.redAccent,
          ));
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to load memories'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  bool isImage(String fileType) => fileType.toLowerCase().contains('image');
  bool isVideo(String fileType) => fileType.toLowerCase().contains('video');
  bool isAudio(String fileType) => fileType.toLowerCase().contains('audio');
  bool isDocument(String fileType) {
    final type = fileType.toLowerCase();
    return type.contains('pdf') ||
        type.contains('doc') ||
        type.contains('text') ||
        type.contains('plain');
  }

  List<Memory> filterByType(String type) {
    switch (type) {
      case 'images':
        return memories.where((m) => isImage(m.fileType)).toList();
      case 'videos':
        return memories.where((m) => isVideo(m.fileType)).toList();
      case 'audios':
        return memories.where((m) => isAudio(m.fileType)).toList();
      case 'documents':
        return memories.where((m) => isDocument(m.fileType)).toList();
      case 'all':
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
    if (memoryList.isEmpty) {
      return Center(
        child: Text(
          "No memories found",
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 26,
        crossAxisSpacing: 20,
        childAspectRatio: 0.95,
      ),
      itemCount: memoryList.length,
      itemBuilder: (context, index) {
        final memory = memoryList[index];
        final String fileType = memory.fileType.toLowerCase();

        IconData iconData = Icons.insert_drive_file;
        Color glow = Colors.cyanAccent;
        if (isVideo(fileType)) {
          iconData = Icons.play_circle_fill_rounded;
          glow = Colors.pinkAccent;
        } else if (isAudio(fileType)) {
          iconData = Icons.audiotrack_rounded;
          glow = Colors.purpleAccent;
        } else if (isImage(fileType)) {
          glow = Colors.cyanAccent;
        } else if (isDocument(fileType)) {
          glow = Colors.amberAccent;
        }

        return GestureDetector(
          onTap: () => openMemory(memory),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: glow.withOpacity(0.24),
                  blurRadius: 24,
                  spreadRadius: 6,
                ),
                BoxShadow(
                  color: glow.withOpacity(0.13),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(.10),
                  glow.withOpacity(0.09),
                  Colors.black.withOpacity(.19),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isImage(fileType))
                    Positioned.fill(
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.black54,
                          BlendMode.darken,
                        ),
                        child: Image.network(
                          memory.contentUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.black12,
                            child: Center(
                              child: Icon(Icons.broken_image, color: glow),
                            ),
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Colors.black12,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 11, sigmaY: 11),
                      child: Container(
                        color: Colors.black.withOpacity(isImage(fileType) ? 0.23 : 0.27),
                      ),
                    ),
                  ),
                  Center(
                    child: isImage(fileType)
                        ? Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: glow.withOpacity(0.41),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                memory.title,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      glow.withOpacity(0.55),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.7, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: glow.withOpacity(0.3),
                                      blurRadius: 14,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  iconData,
                                  size: 38,
                                  color: glow,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.56),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: glow.withOpacity(0.3), width: 1),
                                ),
                                child: Text(
                                  memory.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.96),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      // This case is unlikely now but safe fallback
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0c111c),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 75,
        titleSpacing: 10,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.cyanAccent, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.3),
                    blurRadius: 13,
                    spreadRadius: 6,
                  )
                ],
              ),
              child: Center(
                child: Text(
                  widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '',
                  style: GoogleFonts.russoOne(
                    color: Colors.white,
                    fontSize: 22,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                'Memories of\n${widget.username}',
                style: GoogleFonts.orbitron(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: 0.35,
                  height: 1.15,
                ),
                maxLines: 2,
              ),
            ),
          ],
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
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.cyanAccent, size: 28),
            tooltip: 'Add Memory',
          ),
          IconButton(
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
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.purpleAccent, size: 27),
            tooltip: 'Chat with AI',
          ),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: TabBar(
              controller: _tabController!,
              indicator: ShapeDecoration(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                gradient: const LinearGradient(
                  colors: [Colors.cyanAccent, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shadows: const [BoxShadow(color: Colors.white24, blurRadius: 5)],
              ),
              labelStyle: GoogleFonts.orbitron(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: 1.3,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              isScrollable: true,
              tabs: tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : TabBarView(
              controller: _tabController!,
              children: tabs.map((tab) => buildMemoryGrid(filterByType(tab.toLowerCase()))).toList(),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: FloatingActionButton(
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
          elevation: 8,
          backgroundColor: Colors.cyanAccent,
          child: const Icon(Icons.add, color: Colors.black, size: 32),
          shape: const CircleBorder(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
