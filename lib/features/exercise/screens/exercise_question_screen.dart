import 'package:flutter/material.dart';

class ExerciseQuestionScreen extends StatelessWidget {
  const ExerciseQuestionScreen({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Question ${index + 1}')),
      body: const Center(child: Text('ExerciseQuestionScreen — TODO')),
    );
  }
}
