import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart'; // Correct import
import 'screens/home_screen.dart'; // Update this import path if your home screen file is located elsewhere

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit before running the app
  MediaKit.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MemoryForFuture',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.cyanAccent,
      ),
      home: const HomeScreen(), // Replace with your initial screen widget if different
    );
  }
}
