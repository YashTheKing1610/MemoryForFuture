// E:\MemoryForFuture\frontend\lib\screens\memory_list_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


import 'upload_memory_screen.dart';
import 'ai_chat_screen.dart';
import 'media_viewer_screen.dart';
import 'package:memory_for_future/models/memory.dart';
import 'image_to_3d_page.dart';
import 'voice_controls.dart'; // Import VoiceControls screen for navigation


bool isImage(String fileType) {
  final t = fileType.toLowerCase();
  return t.contains('image') ||
      ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic'].any(t.contains);
}


bool isVideo(String fileType) {
  final t = fileType.toLowerCase();
  return t.contains('video') ||
      ['mp4', 'mov', 'mkv', 'avi', 'webm', 'm4v', 'mpeg'].any(t.contains);
}


bool isAudio(String fileType) {
  final t = fileType.toLowerCase();
  return t.contains('audio') ||
      ['mp3', 'wav', 'aac', 'm4a', 'ogg', 'oga', 'flac', 'opus', 'm4b'].any(t.contains);
}


bool isDocument(String fileType) {
  final t = fileType.toLowerCase();
  return t.contains('pdf') ||
      t.contains('doc') ||
      t.contains('docx') ||
      t.contains('txt') ||
      t.contains('text') ||
      t.contains('plain') ||
      t.contains('rtf') ||
      t.contains('ppt') ||
      t.contains('pptx') ||
      t.contains('xls') ||
      t.contains('xlsx') ||
      t.contains('csv');
}


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


class _MemoryListScreenState extends State<MemoryListScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Memory> memories = [];
  bool isLoading = true;


  final List<String> tabs = ['ALL', 'IMAGES', 'VIDEOS', 'AUDIOS', 'DOCUMENTS'];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    fetchMemories();
  }


  Future<void> fetchMemories() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/get-memories/${widget.profileId}'));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to load memories'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to load memories'),
        backgroundColor: Colors.redAccent,
      ));
    }
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
    final currentType = tabs[_tabController.index].toLowerCase();
    final currentList = filterByType(currentType);
    final currentIndex = currentList.indexOf(memory);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaViewerScreen(
          memories: currentList,
          initialIndex: currentIndex,
        ),
      ),
    );
  }


  Color getCardGlow(String fileType) {
    if (isVideo(fileType)) return Colors.pinkAccent;
    if (isAudio(fileType)) return Colors.purpleAccent;
    if (isDocument(fileType)) return Colors.amberAccent;
    return Colors.cyanAccent;
  }


  IconData getCardIcon(String fileType) {
    if (isVideo(fileType)) return Icons.play_circle_fill_rounded;
    if (isAudio(fileType)) return Icons.music_note_rounded;
    if (isDocument(fileType)) return Icons.description_rounded;
    return Icons.image_rounded;
  }


  Widget buildMemoryCard(Memory memory) {
    final fileType = memory.fileType.toLowerCase();
    final glow = getCardGlow(fileType);
    final iconData = getCardIcon(fileType);


    return GestureDetector(
      onTap: () => openMemory(memory),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: glow.withOpacity(0.15),
              blurRadius: 22,
              spreadRadius: 2,
            ),
          ],
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(.06),
              glow.withOpacity(.04),
              Colors.black.withOpacity(.13),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isImage(fileType) && memory.contentUrl.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    memory.contentUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.black26),
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
              if (!isImage(fileType) || memory.contentUrl.isEmpty)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          glow.withOpacity(0.12),
                          Colors.black.withOpacity(.19),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                  child: Container(
                    color: Colors.black.withOpacity(.15),
                  ),
                ),
              ),
              if (!isImage(fileType))
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: glow.withOpacity(.14),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Icon(
                      iconData,
                      size: 35,
                      color: glow,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.73),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    memory.title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  int getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1100) return 5;
    if (width > 900) return 4;
    if (width > 650) return 3;
    return 2;
  }


  Widget buildCustomTabBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 2),
      child: LayoutBuilder(builder: (context, constraints) {
        double tabWidth = constraints.maxWidth / tabs.length;
        return Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutExpo,
              left: _tabController.animation!.value * tabWidth,
              top: 0,
              child: Container(
                width: tabWidth,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF39F3FF), Color(0xFFB58EFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(.11),
                      blurRadius: 7,
                    )
                  ],
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              indicator: const BoxDecoration(),
              indicatorColor: Colors.transparent,
              isScrollable: false,
              onTap: (i) => setState(() {}),
              labelPadding: EdgeInsets.zero,
              tabs: tabs.map((tab) {
                final tabIndex = tabs.indexOf(tab);
                final isSelected = _tabController.index == tabIndex;
                final tabCount = {
                  'ALL': memories.length,
                  'IMAGES': memories.where((m) => isImage(m.fileType)).length,
                  'VIDEOS': memories.where((m) => isVideo(m.fileType)).length,
                  'AUDIOS': memories.where((m) => isAudio(m.fileType)).length,
                  'DOCUMENTS': memories.where((m) => isDocument(m.fileType)).length,
                }[tab] ?? 0;


                return Tab(
                  child: Container(
                    width: tabWidth,
                    height: 40,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tab.toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: isSelected ? Colors.black : Colors.white.withOpacity(.86),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 15.4,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.black.withOpacity(0.07)
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "$tabCount",
                            style: GoogleFonts.poppins(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0c111c),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(106),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF181e2a),
                Color(0xFF211438),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 18, 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(left: 4, right: 14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.cyanAccent, Colors.purpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purpleAccent.withOpacity(0.17),
                          blurRadius: 13,
                          spreadRadius: 3,
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Memories of',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.username,
                        style: GoogleFonts.poppins(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),


                  // Navigation button to VoiceControls screen (mic icon)
                  IconButton(
  icon: const Icon(Icons.mic_rounded, color: Colors.cyanAccent),
  tooltip: 'Voice Assistant',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VoiceControls(),
      ),
    );
  },
),



                  IconButton(
                    icon: const Icon(Icons.flash_on_outlined, color: Colors.cyanAccent),
                    tooltip: 'Image to 3D',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ImageTo3DPage()),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.purpleAccent),
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
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 14, 17, 4),
            child: buildCustomTabBar(),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: tabs.map((tab) {
                        final memList = filterByType(tab.toLowerCase());
                        if (memList.isEmpty) {
                          return Center(
                            child: Text(
                              "No memories found in this category",
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          );
                        }
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = getCrossAxisCount(context);
                            return GridView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 24,
                                childAspectRatio: 1,
                              ),
                              itemCount: memList.length,
                              itemBuilder: (context, index) => buildMemoryCard(memList[index]),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 17),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UploadMemoryScreen(
                  profileId: widget.profileId,
                  username: widget.username,
                ),
              ),
            );
            fetchMemories();
          },
          elevation: 8,
          shape: const CircleBorder(),
          backgroundColor: const Color(0xFF3AE9F7),
          child: const Icon(Icons.add, color: Colors.white, size: 33),
        ),
      ),
    );
  }
}