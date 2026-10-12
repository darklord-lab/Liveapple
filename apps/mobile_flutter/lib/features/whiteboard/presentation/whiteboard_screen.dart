import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../screens/classroom/components/digital_board.dart';

class WhiteboardScreen extends StatelessWidget {
  const WhiteboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Board Canvas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen),
            tooltip: 'Toggle Fullscreen',
            onPressed: () {},
          ),
        ],
      ),
      body: const SafeArea(
        child: DigitalBoard(isTeacher: true),
      ),
    );
  }
}
