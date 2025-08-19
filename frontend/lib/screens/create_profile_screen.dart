import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Screens
import 'memory_list_screen.dart';
import 'home_screen.dart';

const String backgroundPatternAsset = 'assets/background_pattern.png';

class CreateProfileScreen extends StatefulWidget {
  @override
  _CreateProfileScreenState createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationOtherController = TextEditingController();
  final _bioController = TextEditingController();
  final _hobbyController = TextEditingController();
  final _favoriteColorController = TextEditingController();

  String _name = '';
  String _relation = '';
  String? _profilePicPath;
  DateTime? _birthday;
  String? _gender;
  String _bio = '';
  String? _favoriteColor;
  String? _hobby;
  String? _voiceSamplePath;
  int _step = 0;
  bool _loading = false;

  final List<String> _relationsList = [
    'Parent',
    'Sibling',
    'Spouse/Partner',
    'Grandparent',
    'Friend',
    'Relative',
    'Other'
  ];
  final List<String> _gendersList = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say'
  ];

  bool _backgroundExists = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await precacheImage(AssetImage(backgroundPatternAsset), context);
      } catch (e) {
        setState(() => _backgroundExists = false);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationOtherController.dispose();
    _bioController.dispose();
    _hobbyController.dispose();
    _favoriteColorController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    setState(() => _loading = true);
    final Map<String, dynamic> body = {
      'name': _name.trim(),
      'relation': _relation.trim(),
      'bio': _bio.trim(),
      'birthday': _birthday?.toIso8601String(),
      'gender': _gender,
      'favorite_color': _favoriteColor,
      'hobby': _hobby,
    };
    try {
      final res = await http.post(
        Uri.parse('http://127.0.0.1:8000/create-profile/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (res.statusCode == 200) {
        final parsed = json.decode(res.body);
        final String profileId = parsed["profile_id"];
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MemoryListScreen(
                profileId: profileId,
                username: _name.trim(),
              ),
            ),
          );
        }
      } else {
        final error = json.decode(res.body)['detail'] ?? "Unknown error occurred";
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _loading = false);
  }

  void _nextStep() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        if (_step < 8) _step++;
      });
    }
  }

  void _previousStep() => setState(() {
        if (_step > 0) _step--;
      });

  Widget _withEnterKey({required Widget child}) {
    return Focus(
      onKey: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
          if (_step < 8) _nextStep();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }

  Future<void> _pickProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 82);
    if (pickedFile != null) {
      setState(() => _profilePicPath = pickedFile.path);
    }
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF4046B0),
                Color(0xFF18B3B6),
                Color(0xFF373A45)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        if (_backgroundExists)
          Opacity(
            opacity: 0.12,
            child: Image.asset(
              backgroundPatternAsset,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => SizedBox(),
            ),
          ),
      ],
    );
  }

  // ---- STYLES ----
  // Main text is white for readability.
  TextStyle get _headline => TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 20,
        shadows: [
          Shadow(
            blurRadius: 2,
            color: Colors.black54,
            offset: Offset(1, 1),
          )
        ],
      );

  TextStyle get _formLabel => TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );

  TextStyle get _inputText => TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      );

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w400),
        filled: true,
        fillColor: Colors.black.withOpacity(0.65),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
        suffixIcon: Icon(icon, color: Colors.white70),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: Colors.white24),
        ),
      );

  // ---- STEPS BUILDERS ----

  Widget _buildNameStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 1: Name', style: _headline),
          SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            style: _inputText,
            decoration: _inputDecoration('Full Name *', Icons.person),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Name is required' : null,
            onChanged: (val) => _name = val,
            onFieldSubmitted: (_) => _nextStep(),
            autofocus: true,
          ),
        ],
      );

  Widget _buildRelationStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 2: Relation', style: _headline),
          SizedBox(height: 20),
          _withEnterKey(
            child: DropdownButtonFormField<String>(
              dropdownColor: Colors.grey[900],
              style: _inputText,
              iconEnabledColor: Colors.white70,
              decoration: _inputDecoration('Relation *', Icons.group),
              value: _relationsList.contains(_relation) ? _relation : null,
              items: _relationsList
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(
                          r,
                          style: _inputText,
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _relation = val ?? '';
                  if (_relation != "Other") _relationOtherController.clear();
                });
              },
              validator: (val) => val == null || val.isEmpty ? 'Relation is required' : null,
            ),
          ),
          if (_relation == 'Other')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextFormField(
                controller: _relationOtherController,
                decoration: _inputDecoration('Enter custom relation', Icons.edit),
                style: _inputText,
                onChanged: (val) => _relation = val,
                onFieldSubmitted: (_) => _nextStep(),
                autofocus: true,
              ),
            ),
        ],
      );

  Widget _buildPictureStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Step 3: Profile Picture', style: _headline),
          SizedBox(height: 16),
          GestureDetector(
            onTap: _pickProfilePicture,
            child: CircleAvatar(
              radius: 62,
              backgroundColor: Colors.white24,
              backgroundImage: _profilePicPath != null
                  ? FileImage(File(_profilePicPath!))
                  : null,
              child: _profilePicPath == null
                  ? Icon(Icons.add_a_photo, size: 54, color: Colors.white70)
                  : null,
            ),
          ),
          SizedBox(height: 10),
          Text('Tap to upload from gallery',
              style: TextStyle(color: Colors.white70, fontSize: 14))
        ],
      );

  Widget _buildBirthdayStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 4: Birthday', style: _headline),
          SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
            icon: Icon(Icons.calendar_today, color: Colors.black87),
            label: Text(
              _birthday == null
                  ? 'Select Date of Birth'
                  : '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _birthday = picked);
            },
          ),
        ],
      );

  Widget _buildGenderStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 5: Gender', style: _headline),
          SizedBox(height: 20),
          _withEnterKey(
            child: DropdownButtonFormField<String>(
              dropdownColor: Colors.grey[900],
              style: _inputText,
              iconEnabledColor: Colors.white70,
              decoration: _inputDecoration('Gender (optional)', Icons.wc),
              value: _gender,
              items: _gendersList
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(
                          g,
                          style: _inputText,
                        ),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _gender = val),
            ),
          ),
        ],
      );

  Widget _buildBioStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Step 6: Short Bio', style: _headline),
              SizedBox(width: 8),
              Tooltip(
                message: 'Write 1–2 sentences describing them, notable traits, or how you know them.',
                child: Icon(Icons.info_outline, color: Colors.white70, size: 23),
              ),
            ],
          ),
          SizedBox(height: 18),
          TextFormField(
            controller: _bioController,
            decoration: _inputDecoration('Describe them in a few words', Icons.info_outline),
            style: _inputText,
            maxLines: 3,
            onChanged: (val) => _bio = val,
            onFieldSubmitted: (_) => _nextStep(),
          ),
        ],
      );

  // FAVORITE COLOR - simple text input
  Widget _buildFavoriteColorStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 7: Favorite Color', style: _headline),
          SizedBox(height: 20),
          TextFormField(
            controller: _favoriteColorController,
            decoration: _inputDecoration('Favorite Color', Icons.color_lens),
            style: _inputText,
            onChanged: (val) => _favoriteColor = val,
            onFieldSubmitted: (_) => _nextStep(),
            autofocus: true,
          ),
        ],
      );

  Widget _buildHobbyStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 8: Hobby or Interest', style: _headline),
          SizedBox(height: 20),
          TextFormField(
            controller: _hobbyController,
            decoration: _inputDecoration('Hobby / Interest', Icons.sports_volleyball),
            style: _inputText,
            onChanged: (val) => _hobby = val,
            onFieldSubmitted: (_) => _nextStep(),
          ),
        ],
      );

  Widget _buildVoiceSampleStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 9: Voice Sample', style: _headline),
          SizedBox(height: 20),
          OutlinedButton.icon(
            icon: Icon(Icons.mic),
            label: Text('Record Voice Sample (optional)',
                style: _formLabel.copyWith(color: Colors.blueGrey)),
            onPressed: () {},
          ),
          if (_voiceSamplePath != null)
            Text('Voice sample recorded.', style: TextStyle(color: Colors.white70)),
        ],
      );

  Widget _buildSuccessScreen() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.greenAccent[400], size: 70),
            SizedBox(height: 14),
            Text('Profile created!',
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                          blurRadius: 2,
                          color: Colors.black54,
                          offset: Offset(1, 1))
                    ])),
            SizedBox(height: 8),
            Text('Now you can start chatting!',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      );

  Widget _buildProgressBar() {
    double percent = (_step.clamp(0, 8) + 1) / 9;
    return LinearProgressIndicator(
      value: percent,
      backgroundColor: Colors.white30,
      valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent[400]!),
      minHeight: 8,
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (_step) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildRelationStep();
      case 2:
        return _buildPictureStep();
      case 3:
        return _buildBirthdayStep();
      case 4:
        return _buildGenderStep();
      case 5:
        return _buildBioStep();
      case 6:
        return _buildFavoriteColorStep();
      case 7:
        return _buildHobbyStep();
      case 8:
        return _buildVoiceSampleStep();
      default:
        return _buildSuccessScreen();
    }
  }

  Widget _buildBackButton() {
    return ElevatedButton.icon(
      icon: Icon(Icons.arrow_left, color: Colors.white),
      label: Text('Back', style: _formLabel.copyWith(color: Colors.white)),
      onPressed: _previousStep,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        padding: EdgeInsets.symmetric(horizontal: 27, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => HomeScreen()));
            },
            tooltip: 'Back to Home',
          ),
        ),
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 440, maxHeight: 690),
                  child: Card(
                    color: Colors.black.withOpacity(0.88),
                    elevation: 18,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(36)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 38),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildProgressBar(),
                            SizedBox(height: 28),
                            Expanded(
                              child: SingleChildScrollView(
                                  child: _buildStepContent(context)),
                            ),
                            SizedBox(height: 20),
                            Row(
                              children: [
                                if (_step > 0 && _step <= 8) _buildBackButton(),
                                Spacer(),
                                if (_step < 8)
                                  ElevatedButton(
                                    child: Text('Next',
                                        style: _formLabel.copyWith(
                                            color: Colors.white)),
                                    onPressed: _nextStep,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepPurpleAccent,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 27, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14))),
                                  ),
                                if (_step == 8)
                                  ElevatedButton(
                                    child: _loading
                                        ? SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white)))
                                        : Text('Create Profile',
                                            style: _formLabel.copyWith(
                                                color: Colors.black)),
                                    onPressed: _loading
                                        ? null
                                        : () async {
                                            if (_name.isEmpty ||
                                                _relation.isEmpty) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          "Name and Relation are required!")));
                                              return;
                                            }
                                            await _submitProfile();
                                          },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.greenAccent[400],
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 29, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                  ),
                              ],
                            )
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
