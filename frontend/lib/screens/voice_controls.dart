// E:\MemoryForFuture\frontend\lib\screens\voice_controls.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'assistant_api.dart';

class VoiceControls extends StatefulWidget {
  const VoiceControls({super.key});
  @override
  State<VoiceControls> createState() => _VoiceControlsState();
}

class _VoiceControlsState extends State<VoiceControls>
    with SingleTickerProviderStateMixin {
final AssistantApi api = AssistantApi('http://10.166.234.69:8000');
  String _statusMessage = '';
  bool _isLoading = false;
  bool _assistantRunning = false;

  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.45, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleStart() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });
    try {
      final resp = await api.startAssistant();
      if (resp.statusCode == 200) {
        setState(() {
          _statusMessage = "Assistant started successfully.";
          _assistantRunning = true;
        });
      } else {
        setState(() {
          _statusMessage = "Failed to start assistant: ${resp.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error starting assistant: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleStop() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });
    try {
      final resp = await api.stopAssistant();
      if (resp.statusCode == 200) {
        setState(() {
          _statusMessage = "Assistant stopped successfully.";
          _assistantRunning = false;
        });
      } else {
        setState(() {
          _statusMessage = "Failed to stop assistant: ${resp.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error stopping assistant: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget memoryCard({
    required String title,
    required String subtitle,
    required String tag,
    required String time,
    required List<Color> gradient,
  }) {
    return Container(
      constraints: BoxConstraints(maxWidth: 350, minWidth: 260, minHeight: 160),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(0.32),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 15, color: Colors.white70, height: 1.25)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      color: Colors.white24,
                    ),
                    child: Text(tag,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  Text(time,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.white70)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Colors.black;
    final size = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            Positioned.fill(child: Container(color: backgroundColor)),
            // Soft blurred gradient background
            Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.deepPurpleAccent.withOpacity(0.12),
                          Colors.blueAccent.withOpacity(0.07),
                          Colors.transparent
                        ],
                        center: Alignment.topCenter,
                        radius: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title and tagline
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: [Color(0xFFc084fc), Color(0xFF38bdf8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: const Text(
                        'MemoryMuse ⚡',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Your intelligent voice assistant that remembers\neverything that matters to you",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.74),
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                              color: Colors.deepPurpleAccent.withOpacity(0.12),
                              blurRadius: 12)
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Responsive memory cards row or column
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      final children = [
                        memoryCard(
                          title: "Birthday Reminder",
                          subtitle:
                              "Mom's birthday is next Tuesday, need to call her and send flowers",
                          tag: "personal",
                          time: "2 hours ago",
                          gradient: [Color(0xFFa78bfa), Color(0xFF7c3aed)],
                        ),
                        memoryCard(
                          title: "Project Meeting",
                          subtitle:
                              "Discussed the neural network implementation with the team, Sarah suggested using transformer architecture",
                          tag: "work",
                          time: "1 day ago",
                          gradient: [Color(0xFF38bdf8), Color(0xFF4338ca)],
                        ),
                      ];
                      return isWide
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: children,
                            )
                          : Column(
                              children: children,
                            );
                    }),
                    const SizedBox(height: 27),
                    // Center animated glowing mic button
                    AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurpleAccent
                                      .withOpacity(_glowAnimation.value),
                                  blurRadius: 40,
                                  spreadRadius: 13,
                                ),
                                BoxShadow(
                                  color: Colors.blueAccent
                                      .withOpacity(_glowAnimation.value / 3),
                                  blurRadius: 18,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(100),
                                onTap: () {
                                  if (_assistantRunning) {
                                    _handleStop();
                                  } else {
                                    _handleStart();
                                  }
                                },
                                child: Ink(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFA78BFA),
                                        Color(0xFF38BDF8)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _assistantRunning
                                          ? Icons.stop
                                          : Icons.mic,
                                      color: Colors.white,
                                      size: 56,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                    const SizedBox(height: 18),
                    // Assistant status text/button
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.deepPurple.withOpacity(0.73),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.19),
                            width: 1.1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            !_assistantRunning
                                ? "Ready to assist  ✨"
                                : "Listening...",
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_isLoading) ...[
                            const SizedBox(width: 12),
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Responsive bottom memory cards
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      final children = [
                        memoryCard(
                          title: "Learning Notes",
                          subtitle:
                              "Quantum computing principles: superposition allows qubits to exist in multiple states simultaneously",
                          tag: "learning",
                          time: "3 days ago",
                          gradient: [Color(0xFFfbbf24), Color(0xFFf472b6)],
                        ),
                        memoryCard(
                          title: "Travel Plans",
                          subtitle:
                              "Flight to Tokyo is confirmed for December 15th, need to book hotel near Shibuya",
                          tag: "personal",
                          time: "2 days ago",
                          gradient: [Color(0xFFa78bfa), Color(0xFF4338ca)],
                        ),
                      ];
                      return isWide
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: children,
                            )
                          : Column(
                              children: children,
                            );
                    }),
                    if (_statusMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 18, bottom: 3),
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _statusMessage.contains("success")
                                ? Colors.greenAccent.shade200
                                : Colors.redAccent.shade100,
                            fontSize: 21,
                            letterSpacing: 0.7,
                            shadows: [
                              Shadow(
                                  color: Colors.black.withOpacity(0.24),
                                  blurRadius: 5)
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
