import 'package:flutter/material.dart';

class RecordingTimer extends StatelessWidget {
  const RecordingTimer({super.key, required this.elapsed});

  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    final seconds = elapsed.inSeconds % 60;
    final time = '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';

    return Text(
      time,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: 'monospace',
            color: Theme.of(context).colorScheme.error,
          ),
    );
  }
}
