import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const PaApp());
}

class PaApp extends StatelessWidget {
  const PaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PA-APP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
