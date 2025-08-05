import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

// --- Helper class for suggestion chips
class SuggestionChip extends StatelessWidget {
  final String label;
  const SuggestionChip(this.label, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 6),
      child: Chip(
        backgroundColor: Colors.cyan[50],
        label: Text(label, style: const TextStyle(color: Colors.black87)),
      ),
    );
  }
}

// --- STEP-BY-STEP SLIDESHOW/UPLOAD SCREEN ---
class UploadMemoryScreen extends StatefulWidget {
  final String profileId;
  final String username;

  const UploadMemoryScreen({
    Key? key,
    required this.profileId,
    required this.username,
  }) : super(key: key);

  @override
  State<UploadMemoryScreen> createState() => _UploadMemoryScreenState();
}

class _UploadMemoryScreenState extends State<UploadMemoryScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  String _selectedType = "image";
  File? _selectedFile;

  // Upload form fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _emotionsController = TextEditingController();

  final Map<String, List<String>> chipSuggestions = {
    "image": [
      "sitting", "talking", "family events", "favorite place",
      "achievement", "celebration", "togetherness", "proud moment", "outdoors", "laughing", "reading", "serious"
    ],
    "video": [
      "speech", "dancing", "singing", "advice", "milestone", "candid", "birthday", "medal", "emotion", "friends"
    ],
    "audio": [
      "story", "lullaby", "greeting", "laughter", "advice", "song", "bedtime", "moment", "comfort", "catchphrase"
    ],
    "document": [
      "certificate", "report card", "letter", "poem", "recipe", "diploma", "artwork", "sketch", "grades", "handwritten"
    ]
  };

  void _nextPage() {
    if (_pageIndex < 5) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _backPage() {
    if (_pageIndex > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Memory uploaded!"),
        content: const Text(
            "You've added a piece to your future legacy.\n\nAdd another or return home."),
        actions: [
          TextButton(
            child: const Text("Upload Another"),
            onPressed: () {
              Navigator.pop(ctx);
              _titleController.clear();
              _descController.clear();
              _tagsController.clear();
              _emotionsController.clear();
              setState(() => _selectedFile = null);
            },
          ),
          TextButton(
            child: const Text("Home"),
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          ),
        ],
      ),
    );
  }

  Widget get _purposeSlide => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TODO: Add your real asset here
              Image.asset('assets/images/family_collage.png',
                  height: 140, fit: BoxFit.cover),
              const SizedBox(height: 22),
              const Text("Welcome to Memory For Future",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                  textAlign: TextAlign.center),
              const SizedBox(height: 18),
              const Text(
                "Preserve family, friendship, achievement, and love: every photo, voice, document, or video helps tell a unique story for future generations.\n\nYour uploads can celebrate moments of joy, resilience, learning, and growth—every memory matters.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              const Text("Swipe to discover what to upload and how to make your stories shine.",
                  style: TextStyle(
                      color: Colors.white38,
                      fontStyle: FontStyle.italic,
                      fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _describeImagesSlide(BuildContext context) => _GuidedSlide(
        type: "Images",
        imageAsset: 'assets/images/image_examples.png',
        icon: Icons.image,
        description:
            "Great photos help revive the story:\n\n"
            "- Birthdays, weddings, graduations\n"
            "- Sitting/standing portraits (smiling, laughing, serious)\n"
            "- Awards, proud moments, family gatherings\n"
            "- Both milestones and 'everyday' life scenes\n",
        suggestionChips: chipSuggestions['image']!,
        titleHint: "E.g. Dad's Graduation Day",
        descHint: "Describe who's in the photo, where, and what made it special.",
        tagsHint: "e.g. graduation, family, success",
        emotionsHint: "e.g. pride, nostalgia, happiness, inspiration"
      );

  Widget _describeVideosSlide(BuildContext context) => _GuidedSlide(
        type: "Videos",
        imageAsset: 'assets/images/video_examples.png',
        icon: Icons.videocam,
        description:
            "Capture life's motion and voice:\n\n"
            "- Talking, giving advice, sharing stories\n"
            "- Dancing, celebrating, receiving awards\n"
            "- Capturing real emotions—happiness and challenge\n"
            "- Moments of togetherness, traditions, or spontaneity",
        suggestionChips: chipSuggestions['video']!,
        titleHint: "E.g. Mom's 50th Toast",
        descHint: "Who's on video? What happens? What do you feel watching it?",
        tagsHint: "e.g. toast, celebration, family",
        emotionsHint: "e.g. excitement, gratitude, nostalgia"
      );

  Widget _describeAudiosSlide(BuildContext context) => _GuidedSlide(
        type: "Audios",
        imageAsset: 'assets/images/audio_examples.png',
        icon: Icons.audiotrack,
        description:
            "Voices connect us across generations:\n\n"
            "- Birthday wishes, advice, bedtime stories\n"
            "- Laughter, favorite sayings, or songs\n"
            "- Expressions of love, courage, or comfort\n\n"
            "Listen for what matters! Laughter, storytelling, even vulnerability.",
        suggestionChips: chipSuggestions['audio']!,
        titleHint: "E.g. Dad’s Story from 1992",
        descHint: "Who’s speaking? What story or feeling is captured?",
        tagsHint: "e.g. advice, bedtime, story",
        emotionsHint: "e.g. love, comfort, hope"
      );

  Widget _describeDocumentsSlide(BuildContext context) => _GuidedSlide(
        type: "Documents",
        imageAsset: 'assets/images/document_examples.png',
        icon: Icons.description,
        description:
            "Keep creative, official, and handwritten moments alive:\n\n"
            "- Letters, hand-written notes, recipes\n"
            "- Certificates, report cards, awards\n"
            "- Poems, sketches, family tree, creative writing\n"
            "- Artifacts of history, tradition, and achievement",
        suggestionChips: chipSuggestions['document']!,
        titleHint: "E.g. Grandma’s Recipe",
        descHint: "What is it? Is it handwritten? What does it mean to you or your family?",
        tagsHint: "e.g. recipe, letter, school",
        emotionsHint: "e.g. pride, tradition, gratitude"
      );

  @override
  Widget build(BuildContext context) {
    final slides = [
      _purposeSlide,
      _describeImagesSlide(context),
      _describeVideosSlide(context),
      _describeAudiosSlide(context),
      _describeDocumentsSlide(context),
      UploadFormSlide(
        profileId: widget.profileId,
        username: widget.username,
        selectedType: _selectedType,
        onTypeChanged: (val) => setState(() => _selectedType = val),
        fileResultSetter: (result) {
          if (result != null && result.files.single.path != null) {
            setState(() {
              _selectedFile = File(result.files.single.path!);
            });
          }
        },
        selectedFile: _selectedFile,
        titleController: _titleController,
        descController: _descController,
        tagsController: _tagsController,
        emotionsController: _emotionsController,
        suggestionChips: chipSuggestions[_selectedType]!,
        onUploadSuccess: _showSuccess,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Upload a Memory", style: TextStyle(color: Colors.cyanAccent)),
        leading: _pageIndex > 0
            ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent), onPressed: _backPage)
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _pageIndex = i),
                children: slides,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: _pageIndex < 5
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _nextPage,
                        child: const Text("Next"),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Guided Slide Widget (copy this exactly) ----
class _GuidedSlide extends StatelessWidget {
  final String type;
  final String imageAsset;
  final IconData icon;
  final String description;
  final List<String> suggestionChips;
  final String titleHint;
  final String descHint;
  final String tagsHint;
  final String emotionsHint;
  const _GuidedSlide({
    required this.type,
    required this.imageAsset,
    required this.icon,
    required this.description,
    required this.suggestionChips,
    required this.titleHint,
    required this.descHint,
    required this.tagsHint,
    required this.emotionsHint,
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(imageAsset, height: 110, fit: BoxFit.cover),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.cyanAccent, size: 36),
              const SizedBox(width: 10),
              Text(
                type,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            children: suggestionChips.map((c) => SuggestionChip(c)).toList(),
          ),
          const Divider(color: Colors.white24, height: 36),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [const Text("• ", style: TextStyle(color: Colors.cyanAccent)), Text("Title:", style: TextStyle(color: Colors.cyanAccent)), const SizedBox(width: 8), Text(titleHint, style: TextStyle(color: Colors.white))]),
                const SizedBox(height: 4),
                Row(children: [const Text("• ", style: TextStyle(color: Colors.cyanAccent)), Text("Description:", style: TextStyle(color: Colors.cyanAccent)), const SizedBox(width: 8), Text(descHint, style: TextStyle(color: Colors.white))]),
                const SizedBox(height: 4),
                Row(children: [const Text("• ", style: TextStyle(color: Colors.cyanAccent)), Text("Tags:", style: TextStyle(color: Colors.cyanAccent)), const SizedBox(width: 8), Text(tagsHint, style: TextStyle(color: Colors.white))]),
                const SizedBox(height: 4),
                Row(children: [const Text("• ", style: TextStyle(color: Colors.cyanAccent)), Text("Emotions:", style: TextStyle(color: Colors.cyanAccent)), const SizedBox(width: 8), Text(emotionsHint, style: TextStyle(color: Colors.white))]),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ---- Upload Form Slide with integrated backend upload ----
class UploadFormSlide extends StatefulWidget {
  final String profileId;
  final String username;
  final String selectedType;
  final void Function(String) onTypeChanged;
  final void Function(FilePickerResult?) fileResultSetter;
  final File? selectedFile;
  final TextEditingController titleController;
  final TextEditingController descController;
  final TextEditingController tagsController;
  final TextEditingController emotionsController;
  final List<String> suggestionChips;
  final VoidCallback onUploadSuccess;

  const UploadFormSlide({
    required this.profileId,
    required this.username,
    required this.selectedType,
    required this.onTypeChanged,
    required this.fileResultSetter,
    required this.selectedFile,
    required this.titleController,
    required this.descController,
    required this.tagsController,
    required this.emotionsController,
    required this.suggestionChips,
    required this.onUploadSuccess,
    Key? key,
  }) : super(key: key);

  @override
  State<UploadFormSlide> createState() => _UploadFormSlideState();
}

class _UploadFormSlideState extends State<UploadFormSlide> {
  String _currentType = "image";
  String? _filename;
  FilePickerResult? _fileResult;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _currentType = widget.selectedType;
    _filename = widget.selectedFile != null
        ? widget.selectedFile!.path.split(Platform.pathSeparator).last
        : null;
  }

  Future<void> _pickFile() async {
    FileType dialogType;
    switch (_currentType) {
      case "video":
        dialogType = FileType.video;
        break;
      case "audio":
        dialogType = FileType.audio;
        break;
      case "document":
        dialogType = FileType.custom;
        break;
      default:
        dialogType = FileType.image;
    }
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: dialogType, allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _filename = result.files.single.name;
        _fileResult = result;
      });
      widget.fileResultSetter(result);
    }
  }

  void _addChip(String val) {
    final existing = widget.tagsController.text;
    if (!existing.contains(val)) {
      widget.tagsController.text = existing.isEmpty ? val : "$existing, $val";
      setState(() {});
    }
  }

  Future<void> _upload() async {
    if (widget.selectedFile == null ||
        widget.titleController.text.trim().isEmpty ||
        widget.descController.text.trim().isEmpty ||
        widget.tagsController.text.trim().isEmpty ||
        widget.emotionsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select a file', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final uri = Uri.parse("http://127.0.0.1:8000/upload-memory/");
      final request = http.MultipartRequest("POST", uri);

      request.fields['title'] = widget.titleController.text.trim();
      request.fields['profile_id'] = widget.profileId;
      request.fields['description'] = widget.descController.text.trim();
      request.fields['tags'] = widget.tagsController.text.trim();
      request.fields['emotion'] = widget.emotionsController.text.trim();
      request.fields['is_favorite'] = 'false';

      if (widget.selectedFile != null) {
        request.files.add(await http.MultipartFile.fromPath('file', widget.selectedFile!.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        widget.onUploadSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${response.statusCode}', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red,),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red,),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String tip = "";
    switch (_currentType) {
      case "image":
        tip = "Images: birthday, family, milestones, friendship, or 'just because'.";
        break;
      case "video":
        tip = "Videos: speech, movement, fun, celebration, achievement.";
        break;
      case "audio":
        tip = "Audios: greetings, laughter, story, song, or a special voice moment.";
        break;
      case "document":
        tip = "Documents: letters, awards, creative writing, school or family records.";
        break;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.category, color: Colors.cyanAccent),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _currentType,
              dropdownColor: Colors.black87,
              items: [
                DropdownMenuItem(value: "image", child: Row(children: [Icon(Icons.image, color: Colors.cyanAccent), SizedBox(width:4), Text("Image")])),
                DropdownMenuItem(value: "video", child: Row(children: [Icon(Icons.videocam, color: Colors.cyanAccent), SizedBox(width:4), Text("Video")])),
                DropdownMenuItem(value: "audio", child: Row(children: [Icon(Icons.audiotrack, color: Colors.cyanAccent), SizedBox(width:4), Text("Audio")])),
                DropdownMenuItem(value: "document", child: Row(children: [Icon(Icons.description, color: Colors.cyanAccent), SizedBox(width:4), Text("Document")])),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _currentType = v);
                widget.onTypeChanged(_currentType);
              },
            ),
          ]),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.cyan[900]?.withOpacity(0.11),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.cyanAccent, size: 22),
                const SizedBox(width: 8),
                Expanded(child: Text(tip, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w500),)),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.attach_file),
            label: Text("Select ${_currentType[0].toUpperCase()}${_currentType.substring(1)}"),
            onPressed: _pickFile,
          ),
          if (_filename != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text("Selected file: $_filename", style: const TextStyle(color: Colors.white70)),
            ),
          const SizedBox(height: 12),

          TextField(
            controller: widget.titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
                labelText: "Title",
                labelStyle: const TextStyle(color: Colors.cyanAccent),
                hintText: _currentType == "image"
                    ? "E.g. Dad's Graduation Day"
                    : _currentType == "video"
                        ? "E.g. Mom's 50th Toast"
                        : _currentType == "audio"
                            ? "E.g. Dad’s Story from 1992"
                            : "E.g. Grandma’s Recipe",
                hintStyle: const TextStyle(color: Colors.white24),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.descController,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: "Description",
              labelStyle: const TextStyle(color: Colors.cyanAccent),
              hintText: _currentType == "image"
                  ? "Who's in the photo? Where? What's the story?"
                  : _currentType == "video"
                      ? "What's happening? What feeling/memory does it bring?"
                      : _currentType == "audio"
                          ? "Who’s speaking or singing? What does this recording mean?"
                          : "What is this document? What's its importance?",
              hintStyle: const TextStyle(color: Colors.white24),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.tagsController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Tags (comma separated)",
              labelStyle: const TextStyle(color: Colors.cyanAccent),
              hintText: widget.suggestionChips.take(4).join(', '),
              hintStyle: const TextStyle(color: Colors.white24),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.start,
            children: widget.suggestionChips.map((c) =>
                GestureDetector(
                  onTap: () => _addChip(c),
                  child: Chip(
                    backgroundColor: Colors.cyan[100],
                    label: Text(c, style: const TextStyle(color: Colors.black87)),
                  ),
                )
            ).toList(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.emotionsController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Emotions (comma separated)",
              labelStyle: const TextStyle(color: Colors.cyanAccent),
              hintText: "e.g. joy, nostalgia, gratitude",
              hintStyle: const TextStyle(color: Colors.white24),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 18),
          _isUploading
              ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
              : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text("Upload Memory"),
                  onPressed: (widget.selectedFile == null) ? null : _upload,
                ),
        ],
      ),
    );
  }
}
