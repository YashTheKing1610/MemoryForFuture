import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class UploadMemoryScreen extends StatefulWidget {
  final String profileId;

  const UploadMemoryScreen({super.key, required this.profileId});

  @override
  State<UploadMemoryScreen> createState() => _UploadMemoryScreenState();
}

class _UploadMemoryScreenState extends State<UploadMemoryScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _emotionController = TextEditingController();
  final TextEditingController _collectionController = TextEditingController();

  File? _selectedFile;
  bool _isFavorite = false;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadMemory() async {
    if (_selectedFile == null || !_formKey.currentState!.validate()) {
      _showSnackbar('Please fill all fields and select a file', isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final uri = Uri.parse("http://127.0.0.1:8000/upload-memory/");
      final request = http.MultipartRequest("POST", uri);

      request.fields['title'] = _titleController.text.trim();
      request.fields['profile_id'] = widget.profileId;
      request.fields['description'] = _descriptionController.text.trim();
      request.fields['tags'] = _tagsController.text.trim();
      request.fields['emotion'] = _emotionController.text.trim();
      request.fields['collection'] = _collectionController.text.trim();
      request.fields['is_favorite'] = _isFavorite ? 'true' : 'false';

      request.files.add(await http.MultipartFile.fromPath('file', _selectedFile!.path));

      final streamedResponse = request.send();
      final response = await streamedResponse.timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        _showSnackbar('Memory uploaded successfully ✅');
        _resetForm();
      } else {
        _showSnackbar('Upload failed: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _showSnackbar('Upload failed: $e', isError: true);
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _tagsController.clear();
    _emotionController.clear();
    _collectionController.clear();
    setState(() {
      _selectedFile = null;
      _isFavorite = false;
    });
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Upload Memory'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Title', _titleController),
              _buildTextField('Description', _descriptionController, maxLines: 2),
              _buildTextField('Tags (comma-separated)', _tagsController),
              _buildTextField('Emotion', _emotionController),
              _buildTextField('Collection', _collectionController),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Mark as Favorite', style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  Switch(
                    value: _isFavorite,
                    onChanged: (val) => setState(() => _isFavorite = val),
                    activeColor: Colors.purple,
                  )
                ],
              ),
              const SizedBox(height: 16),
              _selectedFile != null
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _selectedFile!.path.split(Platform.pathSeparator).last,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const SizedBox.shrink(),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.file_upload),
                label: const Text('Choose File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 20),
              _isUploading
                  ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
                  : ElevatedButton(
                      onPressed: _uploadMemory,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.purpleAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Upload Memory', style: TextStyle(fontSize: 16)),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
