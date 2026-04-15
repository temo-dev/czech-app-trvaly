import 'package:flutter/material.dart';

class SimulatorQuestionScreen extends StatelessWidget {
  const SimulatorQuestionScreen({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Question ${index + 1}')),
      body: const Center(child: Text('SimulatorQuestionScreen — TODO')),
    );
  }
}
