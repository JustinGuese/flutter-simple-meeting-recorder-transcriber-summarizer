import 'package:flutter/material.dart';

import '../../models/meeting.dart';

class TranscriptionStatusChip extends StatelessWidget {
  const TranscriptionStatusChip({super.key, required this.status});

  final TranscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (status) {
      case TranscriptionStatus.none:
        return const SizedBox.shrink();
      case TranscriptionStatus.inProgress:
        return Chip(
          avatar: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          label: Text('Transcribing...', style: theme.textTheme.bodySmall),
          backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
        );
      case TranscriptionStatus.completed:
        return Chip(
          avatar: Icon(
            Icons.check_circle_outline,
            size: 16,
            color: theme.colorScheme.tertiary,
          ),
          label: Text('Done', style: theme.textTheme.bodySmall),
          backgroundColor: theme.colorScheme.tertiaryContainer.withOpacity(0.5),
        );
      case TranscriptionStatus.failed:
        return Chip(
          avatar: Icon(
            Icons.error_outline,
            size: 16,
            color: theme.colorScheme.error,
          ),
          label: Text('Failed', style: theme.textTheme.bodySmall),
          backgroundColor: theme.colorScheme.errorContainer.withOpacity(0.5),
        );
    }
  }
}
