import 'package:flutter/material.dart';

import '../../controllers/app_controller.dart';
import 'package:df_ui_widgets/df_ui_widgets.dart';

class RecordingOverlay extends StatefulWidget {
  const RecordingOverlay({super.key, required this.controller});

  final AppController controller;

  @override
  State<RecordingOverlay> createState() => _RecordingOverlayState();
}

class _RecordingOverlayState extends State<RecordingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0, end: 1).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: theme.colorScheme.errorContainer.withOpacity(0.95),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Pulsing red dot
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (0.3 * _pulseAnimation.value),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.error,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.error.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            // Timer
            RecordingTimer(elapsed: widget.controller.elapsedRecording),
            const SizedBox(width: 16),
            // Audio level bars
            AudioLevelBar(level: widget.controller.audioLevel),
            const Spacer(),
            // Label
            Text(
              'Mic + System',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
