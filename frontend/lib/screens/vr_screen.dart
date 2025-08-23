import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:memory_for_future/models/memory.dart';

const String baseUrl = "http://127.0.0.1:8000"; // Change to backend IP if needed

class VrScreen extends StatefulWidget {
  final String profileId;
  final String username;
  const VrScreen({Key? key, required this.profileId, required this.username}) : super(key: key);

  @override
  State<VrScreen> createState() => _VrScreenState();
}

class _VrScreenState extends State<VrScreen> {
  List<Memory> memories = [];
  Set<String> selectedMemoryPaths = {};
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchMemories();
  }

  Future<void> fetchMemories() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/get-memories/${widget.profileId}'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          memories = data.map((m) => Memory.fromJson(m)).toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load memories'), backgroundColor: Colors.redAccent));
      }
    } catch (_) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load memories'), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> submitSelectedMemories() async {
    if (selectedMemoryPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one memory to create VR Room'), backgroundColor: Colors.amber));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final body = jsonEncode({'memory_paths': selectedMemoryPaths.toList()});
      final response = await http.post(
        Uri.parse('$baseUrl/vr/room/active/${widget.profileId}'),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      setState(() => isSubmitting = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('VR Room created! Open your VR app to see.'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create VR Room (${response.reasonPhrase})'), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error while creating VR Room'), backgroundColor: Colors.redAccent));
    }
  }

  Widget buildMemorySelectionGrid() {
    if (memories.isEmpty) {
      return Center(child: Text("No memories found", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16)));
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 26, crossAxisSpacing: 20, childAspectRatio: 0.95),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        final memory = memories[index];
        final String path = memory.filePath ?? ''; // full blob relative path expected here
        final bool isSelected = selectedMemoryPaths.contains(path);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) selectedMemoryPaths.remove(path);
              else selectedMemoryPaths.add(path);
            });
          },
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(color: isSelected ? Colors.cyanAccent.withOpacity(0.23) : Colors.white12, blurRadius: 30, spreadRadius: 7),
                  ],
                  border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.transparent, width: 2.3),
                  gradient: LinearGradient(colors: [Colors.black.withOpacity(0.12), Colors.cyanAccent.withOpacity(0.08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (memory.contentUrl != null && memory.contentUrl!.isNotEmpty)
                        Image.network(
                          memory.contentUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.black12, child: Center(child: Icon(Icons.broken_image, color: Colors.cyanAccent))),
                          loadingBuilder: (context, child, progress) => progress == null ? child : Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))),
                        ),
                      Positioned(left: 8, top: 8, child: CircleAvatar(radius: 16, backgroundColor: isSelected ? Colors.cyanAccent.withOpacity(0.89) : Colors.white30, child: isSelected ? const Icon(Icons.check, color: Colors.black, size: 19) : const Icon(Icons.check_box_outline_blank, color: Colors.white70, size: 19))),
                      Positioned(
                        bottom: 14,
                        left: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.56), borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          child: Text(memory.title, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0c111c),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 77,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.purpleAccent], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.3), blurRadius: 13, spreadRadius: 6)]),
              child: Center(child: Text(widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '', style: GoogleFonts.russoOne(color: Colors.white, fontSize: 22, letterSpacing: 2.5, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text('Select memories for\nVR Room', style: GoogleFonts.orbitron(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 21, letterSpacing: 0.35, height: 1.15), maxLines: 2),
            ),
          ],
        ),
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)) : buildMemorySelectionGrid(),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 26),
        child: FloatingActionButton.extended(
          onPressed: isSubmitting ? null : submitSelectedMemories,
          backgroundColor: Colors.cyanAccent,
          icon: const Icon(Icons.vrpano, color: Colors.black),
          label: isSubmitting
              ? const SizedBox(height: 21, width: 21, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black))
              : Text("Create VR Room", style: GoogleFonts.orbitron(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}