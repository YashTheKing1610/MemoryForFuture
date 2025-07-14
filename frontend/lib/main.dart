import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MemoryForFutureApp());
}

class MemoryForFutureApp extends StatelessWidget {
  const MemoryForFutureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory For Future',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.purpleAccent,
      ),
      home: const HomeScreen(),
    );
  }
}
