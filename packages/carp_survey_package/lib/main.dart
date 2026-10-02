import 'package:flutter/material.dart';

/// A placeholder app entry point. Not part of the sampling package.
void main() {
  runApp(const MainApp());
}

/// A placeholder "Hello World" app. Not part of the sampling package.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Hello World!'))),
    );
  }
}
