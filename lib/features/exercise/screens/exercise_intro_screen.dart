import 'package:flutter/material.dart';

class ExerciseIntroScreen extends StatelessWidget {
  const ExerciseIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      appBar: AppBar(primary: false, title: const Text('ExerciseIntroScreen')),
      body: const Center(child: Text('ExerciseIntroScreen — TODO')),
    );
  }
}
