import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Update the path to your pattern asset if you want one, or comment out/remove it.
const backgroundPatternAsset = 'assets/background_pattern.png';

class CreateProfileScreen extends StatefulWidget {
  @override
  _CreateProfileScreenState createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Profile fields
  String _name = '';
  String _relation = '';
  String? _profilePicPath;
  DateTime? _birthday;
  String? _gender;
  String _bio = '';
  String? _voiceSamplePath;
  int _step = 0;
  bool _loading = false;

  final List<String> _relationsList = [
    'Parent', 'Sibling', 'Spouse/Partner', 'Grandparent', 'Friend', 'Relative', 'Other'
  ];
  final List<String> _gendersList = [
    'Male', 'Female', 'Non-binary', 'Prefer not to say'
  ];

  Future<void> _submitProfile() async {
    setState(() => _loading = true);

    final Map<String, dynamic> body = {
      'name': _name,
      'relation': _relation,
      'bio': _bio,
      'birthday': _birthday != null ? _birthday!.toIso8601String() : null,
      'gender': _gender,
      // TODO: Handle profilePicPath and voiceSamplePath appropriately
    };

    try {
      final res = await http.post(
        Uri.parse('http://127.0.0.1:8000/create-profile/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (res.statusCode == 200) {
        if (mounted) Navigator.pop(context, true);
      } else {
        final error = json.decode(res.body)['detail'] ?? "Unknown error";
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _loading = false);
  }

  void _nextStep() => setState(() { if (_step < 6) _step++; });
  void _previousStep() => setState(() { if (_step > 0) _step--; });
  void _skipStep() => _nextStep();

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4046B0), Color(0xFF18B3B6), Color(0xFF373A45)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        if (backgroundPatternAsset != null)
          Opacity(
            opacity: 0.14,
            child: Align(
              alignment: Alignment.center,
              child: Image.asset(
                backgroundPatternAsset,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        Positioned(
          left: -90,
          top: -80,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purpleAccent.withOpacity(0.20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent,
                  blurRadius: 80,
                  spreadRadius: 40,
                )
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          right: -60,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.cyanAccent.withOpacity(0.13),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent,
                  blurRadius: 60,
                  spreadRadius: 30,
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(BuildContext context) {
    TextStyle? headlineSmall = Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white);
    TextStyle? headlineMedium = Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white);

    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step 1: Name', style: headlineSmall),
            SizedBox(height: 20),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Full Name *',
                filled: true,
                fillColor: Colors.white70,
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.person),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
              onChanged: (val) => _name = val,
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step 2: Relation', style: headlineSmall),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white70,
                border: OutlineInputBorder(),
                labelText: 'Relation *',
                suffixIcon: Icon(Icons.group),
              ),
              value: _relation.isEmpty ? null : _relation,
              items: _relationsList
                  .map((relation) => DropdownMenuItem(
                        child: Text(relation),
                        value: relation,
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _relation = val ?? ''),
              validator: (value) => value == null || value.isEmpty ? 'Relation is required' : null,
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step 3: Profile Picture', style: headlineSmall),
            SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () {
                  // TODO: Add image picker logic
                },
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white24,
                  backgroundImage: _profilePicPath != null ? AssetImage(_profilePicPath!) : null,
                  child: _profilePicPath == null
                    ? Icon(Icons.add_a_photo, size: 54, color: Colors.white70)
                    : null,
                ),
              ),
            ),
            SizedBox(height: 12),
            Text('Add a profile picture (optional).', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step 4: Birthday', style: headlineSmall),
            SizedBox(height: 20),
            Center(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(backgroundColor: Colors.white70),
                label: Text(
                  _birthday == null
                      ? 'Select Date of Birth (optional)'
                      : '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}',
                ),
                icon: Icon(Icons.calendar_today),
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _birthday = picked);
                },
              ),
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step 5: Gender or Pronouns', style: headlineSmall),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white70,
                border: OutlineInputBorder(),
                labelText: 'Gender or Pronouns (optional)',
                suffixIcon: Icon(Icons.wc),
              ),
              value: _gender,
              items: _gendersList
                  .map((g) => DropdownMenuItem(child: Text(g), value: g))
                  .toList(),
              onChanged: (val) => setState(() => _gender = val),
            ),
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step 6: Short Bio', style: headlineSmall),
            SizedBox(height: 20),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Describe them in a few words (optional)',
                filled: true,
                fillColor: Colors.white70,
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.info_outline),
              ),
              maxLines: 3,
              onChanged: (val) => _bio = val,
            ),
          ],
        );
      case 6:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step 7: Voice Sample', style: headlineSmall),
            SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(backgroundColor: Colors.white70),
              icon: Icon(Icons.mic),
              label: Text('Record Voice Sample (optional)'),
              onPressed: () {
                // TODO: Add voice recording/picking logic
              },
            ),
            SizedBox(height: 12),
            _voiceSamplePath != null
                ? Text('Voice sample recorded.', style: TextStyle(color: Colors.white70))
                : Text('Helps enable future features like voice cloning!', style: TextStyle(color: Colors.white70)),
          ],
        );
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.greenAccent[400], size: 64),
              SizedBox(height: 12),
              Text('Profile created!', style: headlineMedium),
              SizedBox(height: 8),
              Text('You can add more info or upload memories anytime from your dashboard.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              SizedBox(height: 30),
              ElevatedButton(
                child: Text('Go to Dashboard'),
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildProgressBar() {
    double percent = (_step.clamp(0, 6) + 1) / 7;
    return LinearProgressIndicator(
      value: percent,
      backgroundColor: Colors.white30,
      valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent[400]!),
      minHeight: 7,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 430,
                  maxHeight: 670,
                ),
                child: Card(
                  color: Colors.black.withOpacity(0.85),
                  elevation: 16,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(34),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildProgressBar(),
                          SizedBox(height: 28),
                          Expanded(
                            child: SingleChildScrollView(
                              child: _buildStepContent(context),
                            ),
                          ),
                          SizedBox(height: 24),
                          if (_step <= 6)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_step > 0 && _step <= 6)
                                  OutlinedButton(
                                    child: Text('Back'),
                                    onPressed: _previousStep,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white24,
                                      side: BorderSide(color: Colors.white54),
                                    ),
                                  ),
                                if (_step > 1 && _step <= 6)
                                  TextButton(
                                    child: Text('Skip'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                    ),
                                    onPressed: _skipStep,
                                  ),
                                Spacer(),
                                if (_step < 6)
                                  ElevatedButton(
                                    child: Text('Next'),
                                    onPressed: () {
                                      if (_step == 0) {
                                        if (_name.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Name is required!")),
                                          );
                                        } else {
                                          _nextStep();
                                        }
                                      } else if (_step == 1) {
                                        if (_relation.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Relation is required!")),
                                          );
                                        } else {
                                          _nextStep();
                                        }
                                      } else {
                                        _nextStep();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurpleAccent,
                                    ),
                                  ),
                                if (_step == 6)
                                  ElevatedButton(
                                    child: _loading
                                        ? SizedBox(
                                            width: 20, height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                          )
                                        : Text('Create Profile'),
                                    onPressed: _loading
                                        ? null
                                        : () async {
                                            await _submitProfile();
                                            setState(() => _step++);
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.greenAccent[400],
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
