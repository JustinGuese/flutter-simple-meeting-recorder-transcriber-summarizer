import 'package:flutter/material.dart';

class AudioLevelBar extends StatelessWidget {
  const AudioLevelBar({super.key, required this.level});

  final double level;
  static const int barCount = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(barCount, (i) {
        final threshold = (i + 1) / barCount;
        final lit = level >= threshold;
        final height = 8.0 + (i * 4.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          width: 4,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: lit
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
