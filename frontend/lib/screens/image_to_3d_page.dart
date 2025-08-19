import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ImageTo3DPage extends StatefulWidget {
  @override
  _ImageTo3DPageState createState() => _ImageTo3DPageState();
}

class _ImageTo3DPageState extends State<ImageTo3DPage> with TickerProviderStateMixin {
  File? _imageFile;
  bool _isLoading = false;
  String? _previewUrl;
  String? _modelUrl;
  String? _error;
  bool _pollingCancelled = false;

  late AnimationController _loadingController;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(vsync: this, duration: Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _previewUrl = null;
        _modelUrl = null;
        _error = null;
        _pollingCancelled = false;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      _showErrorDialog("Please select an image first.");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _pollingCancelled = false;
      _previewUrl = null;
      _modelUrl = null;
    });

    final startUri = Uri.parse("http://127.0.0.1:8000/meshy/generate-3d/");

    try {
      var request = http.MultipartRequest('POST', startUri);
      request.files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['task_id'] != null) {
          String taskId = jsonResponse['task_id'];
          _startPolling(taskId);
        } else {
          _showErrorDialog("No task_id returned from server.");
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        _showErrorDialog("Server error: ${response.statusCode}");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorDialog("Failed to upload image: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startPolling(String taskId) async {
    final statusUri = Uri.parse("http://127.0.0.1:8000/meshy/generate-3d/status/$taskId");
    int retryCount = 0;
    int maxRetries = 60; // max 5 minutes polling

    while (!_pollingCancelled && retryCount < maxRetries) {
      await Future.delayed(Duration(seconds: 5));
      if (_pollingCancelled) break;

      try {
        var response = await http.get(statusUri);

        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          String status = data['status'] ?? '';

          if (status == 'completed') {
            setState(() {
              _previewUrl = data['preview'];
              _modelUrl = data['model_url'];
              _isLoading = false;
            });
            return;
          } else if (status == 'failed') {
            _showErrorDialog("3D model generation failed.");
            setState(() {
              _isLoading = false;
            });
            return;
          } else {
            setState(() {});
          }
        } else {
          _showErrorDialog("Failed to fetch status: ${response.statusCode}");
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        _showErrorDialog("Error while polling status: $e");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      retryCount++;
    }

    if (retryCount >= maxRetries) {
      _showErrorDialog("Timed out waiting for 3D model generation.");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _cancelPolling() {
    setState(() {
      _pollingCancelled = true;
      _isLoading = false;
    });
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          ElevatedButton(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_isLoading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _loadingController,
            child: Icon(Icons.autorenew, size: 48, color: Colors.cyanAccent),
          ),
          SizedBox(height: 14),
          Text("Generating 3D model, please wait...", style: TextStyle(fontSize: 16)),
          SizedBox(height: 10),
          ElevatedButton.icon(
            icon: Icon(Icons.cancel),
            label: Text("Cancel"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: _cancelPolling,
          ),
        ],
      );
    } else if (_previewUrl != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InteractiveViewer(
            maxScale: 4.0,
            child: Image.network(
              _previewUrl!,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 100, color: Colors.grey),
            ),
          ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            icon: Icon(Icons.threed_rotation),
            label: Text("View 3D Model"),
            onPressed: () async {
              if (_modelUrl != null && await canLaunch(_modelUrl!)) {
                await launch(_modelUrl!);
              }
            },
          ),
        ],
      );
    } else if (_error != null) {
      return Text(
        _error!,
        style: TextStyle(color: Colors.red, fontSize: 16),
      );
    } else {
      return Text(
        "Select an image and upload to generate 3D model",
        style: TextStyle(fontSize: 16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Image to 3D Model"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 250),
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _imageFile == null ? Colors.grey[300] : Colors.transparent,
                  boxShadow: _imageFile == null
                      ? [BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2)]
                      : [],
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 80, color: Colors.grey[700]),
                          SizedBox(height: 8),
                          Text("Tap to select image", style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                        ],
                      )
                    : Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: 220,
                          ),
                        ),
                      ),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.upload_file),
                label: Text(_isLoading ? "Uploading..." : "Upload & Generate 3D"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.grey : Colors.cyanAccent,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isLoading ? null : _uploadImage,
              ),
            ),
            SizedBox(height: 32),
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: _buildPreview(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
