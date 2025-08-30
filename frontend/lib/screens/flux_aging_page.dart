import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class FluxAgingPage extends StatefulWidget {
  @override
  _FluxAgingPageState createState() => _FluxAgingPageState();
}

class _FluxAgingPageState extends State<FluxAgingPage> {
  File? _imageFile;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _loading = false;
  String? _errorMsg;
  String? _resultImageUrl;
  String? _base64Result;

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _imageFile = File(result.files.single.path!);
        _resultImageUrl = null;
        _base64Result = null;
      });
    }
  }

  Future<void> _generateImage() async {
    if (_imageFile == null ||
        _ageController.text.isEmpty ||
        int.tryParse(_ageController.text.replaceAll(RegExp(r'[^0-9]'), '')) == null) {
      setState(() {
        _errorMsg = 'Please select an image and enter a valid age.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = null;
      _resultImageUrl = null;
      _base64Result = null;
    });
    try {
      var uri = Uri.parse('http://localhost:8000/flux/age-transform/');
      var request = http.MultipartRequest('POST', uri)
        ..fields['prompt'] = _descController.text
        ..fields['age'] = _ageController.text
        ..files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));
      var streamedResponse = await request.send();
      var respStr = await streamedResponse.stream.bytesToString();
      var jsonResp = jsonDecode(respStr);

      if (jsonResp['status'] == 'completed' && jsonResp['image_url'] != null) {
        setState(() {
          _resultImageUrl = jsonResp['image_url'];
          _base64Result = null;
        });
      } else if (jsonResp['saved_path'] != null &&
          jsonResp['image_base64'] != null) {
        setState(() {
          _resultImageUrl = null;
          _base64Result = jsonResp['image_base64'];
        });
      } else {
        setState(() {
          _errorMsg = 'Generation failed: ${jsonResp['error'] ?? 'Unknown error.'}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _uploadSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Upload Face Image", style: GoogleFonts.orbitron(
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                    fontSize: 22
                )),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: _pickImage,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.cyanAccent, width: 1.5),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                          : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_file_rounded, color: Colors.cyanAccent, size: 38),
                              SizedBox(height: 12),
                              Text('Click or drag here', style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 14)),
                              Text('Supported: JPG, PNG', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                    ),
                  ),
                ),
                SizedBox(height: 18),
                TextField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    labelText: 'Age or Age Range',
                    hintText: 'e.g. 15, 25, 70, etc.',
                    border: OutlineInputBorder(),
                    fillColor: Colors.black45,
                    filled: true,
                    labelStyle: TextStyle(color: Colors.cyanAccent),
                  ),
                  style: GoogleFonts.poppins(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 14),
                TextField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: 'Other Description (optional)',
                    hintText: 'e.g. child, happy, senior years',
                    border: OutlineInputBorder(),
                    fillColor: Colors.black45,
                    filled: true,
                    labelStyle: TextStyle(color: Colors.amberAccent),
                  ),
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _rightPanel() {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 26, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Age Transformer", style: GoogleFonts.orbitron(
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
              fontSize: 24,
            )),
            SizedBox(height: 28),
            Text(
              "Transform faces to any age instantly. See yourself, family, or friends as kids, adults, or seniors—powered by AI.\n\nThis feature is part of MemoryForFuture, helping you create and reflect on lifelike memories for every era.",
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  padding: EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _loading ? null : _generateImage,
                child: _loading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Generate Age Transformation",
                        style: GoogleFonts.orbitron(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 17
                        )),
              ),
            ),
            if (_errorMsg != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(_errorMsg!,
                  style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            if (_imageFile != null && (_resultImageUrl != null || _base64Result != null))
              Column(
                children: [
                  SizedBox(height: 38),
                  Text("Result", style: GoogleFonts.orbitron(
                    fontSize: 20,
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  )),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text("Before", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                            AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          children: [
                            Text("After", style: GoogleFonts.poppins(color: Colors.amberAccent, fontSize: 14)),
                            AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: _resultImageUrl != null
                                  ? Image.network(_resultImageUrl!, fit: BoxFit.cover)
                                  : _base64Result != null
                                    ? Image.memory(base64Decode(_base64Result!), fit: BoxFit.cover)
                                    : SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF101623),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.cyanAccent),
          tooltip: 'Back to Memories',
          onPressed: () {
            // This will pop to the previous screen in the stack, which is the correct MemoryListScreen with real profile data
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SizedBox.expand(
        child: Center(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1100, maxHeight: double.infinity),
              child: Card(
                color: Colors.black.withOpacity(0.15),
                elevation: 14,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LEFT PANEL: Upload
                    Expanded(
                      flex: 7,
                      child: _uploadSection(),
                    ),
                    Container(
                      width: 2,
                      color: Colors.cyanAccent.withOpacity(.38),
                      margin: EdgeInsets.symmetric(vertical: 48)
                    ),
                    // RIGHT PANEL: Generate & Result
                    Expanded(
                      flex: 6,
                      child: _rightPanel(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
