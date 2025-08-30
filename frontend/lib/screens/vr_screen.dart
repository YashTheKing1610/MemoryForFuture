import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

import 'package:memory_for_future/models/memory.dart';

const String baseUrl = "http://127.0.0.1:8000";

class VRoomScreen extends StatefulWidget {
  final String profileId;
  final String username;

  const VRoomScreen({
    Key? key,
    required this.profileId,
    required this.username,
  }) : super(key: key);

  @override
  State<VRoomScreen> createState() => _VRoomScreenState();
}

class _VRoomScreenState extends State<VRoomScreen> {
  List<Memory> memories = [];
  Set<String> selectedMemoryIds = {};
  bool isLoading = false;
  String? resultMessage;

  // Added field to store activeRoomUrl returned from backend for launching VR app
  String? activeRoomUrl;

  @override
  void initState() {
    super.initState();
    fetchMemories();
  }

  Future<void> fetchMemories() async {
    setState(() {
      isLoading = true;
      resultMessage = null;
    });
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-memories/${widget.profileId}'),
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          memories = data.map((m) => Memory.fromJson(m)).toList();
        });
      } else {
        setState(() {
          resultMessage = "Failed to fetch memories: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        resultMessage = "Error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void toggleSelection(String memoryId) {
    setState(() {
      if (selectedMemoryIds.contains(memoryId)) {
        selectedMemoryIds.remove(memoryId);
      } else {
        selectedMemoryIds.add(memoryId);
      }
    });
  }

  Future<void> createVRRoom() async {
    if (selectedMemoryIds.isEmpty) {
      setState(() {
        resultMessage = "Please select at least one memory.";
      });
      return;
    }
    setState(() {
      isLoading = true;
      resultMessage = null;
      activeRoomUrl = null; // reset
    });

    // Convert selectedMemoryIds to a List explicitly to ensure proper serialization
    final List<String> memoryList = selectedMemoryIds.toList(growable: false);

    final requestBody = json.encode({
      "profile_id": widget.profileId,
      "selected_memory_ids": memoryList,
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vr/create-vr-room/'),
        headers: {"Content-Type": "application/json"},
        body: requestBody,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          resultMessage =
              "VR Room created: ${data['memories_count']} memories included.";
          activeRoomUrl = data['active_room_url']; // Store SAS URL from backend
        });
        // TODO: Launch Unity VR with returned active_room_url
        // For example, pass activeRoomUrl to VR launcher via deep link or intent
      } else {
        setState(() {
          resultMessage =
              "Failed to create VR room: ${response.statusCode} ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        resultMessage = "Error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // UI below is unchanged except optional place to show activeRoomUrl for debug
  Widget buildMemoryGridCard(Memory memory) {
    final isSelected = selectedMemoryIds.contains(memory.uniqueId);
    final glow = getCardGlow(memory.fileType);
    final iconData = getCardIcon(memory.fileType);

    return GestureDetector(
      onTap: () => toggleSelection(memory.uniqueId),
      child: Stack(
        children: [
          Container(
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
                  if (isImage(memory.fileType) && memory.contentUrl.isNotEmpty)
                    Image.network(
                      memory.contentUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.black26),
                      loadingBuilder: (_, child, progress) =>
                          progress == null
                              ? child
                              : Container(
                                  color: Colors.black12,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.cyanAccent),
                                  ),
                                ),
                    ),
                  if (!isImage(memory.fileType) || memory.contentUrl.isEmpty)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            glow.withOpacity(0.12),
                            Colors.black.withOpacity(.19)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                      child: Container(color: Colors.black.withOpacity(.15)),
                    ),
                  ),
                  if (!isImage(memory.fileType))
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          Positioned(
            top: 11,
            right: 12,
            child: Checkbox(
              value: isSelected,
              onChanged: (_) => toggleSelection(memory.uniqueId),
              checkColor: Colors.white,
              activeColor: Colors.cyanAccent,
              side: BorderSide(color: Colors.cyanAccent, width: 1.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0c111c),
      appBar: AppBar(
        title: Text('Create VR Room for ${widget.username}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF181e2a),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : Column(
              children: [
                Expanded(
                  child: memories.isEmpty
                      ? Center(
                          child: Text(
                          "No memories found.",
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ))
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 0),
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: getCrossAxisCount(context),
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 24,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: memories.length,
                            itemBuilder: (context, index) =>
                                buildMemoryGridCard(memories[index]),
                          ),
                        ),
                ),
                if (resultMessage != null)
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      resultMessage!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (activeRoomUrl != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: SelectableText(
                      "VR JSON URL:\n$activeRoomUrl",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.vrpano_rounded),
                    onPressed: isLoading ? null : createVRRoom,
                    label: Text('Create VR Room'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      minimumSize: Size(195, 48),
                      textStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// --- Utility functions remain unchanged ---
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
