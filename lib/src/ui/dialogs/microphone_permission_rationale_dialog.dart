import 'package:df_ui_widgets/df_ui_widgets.dart';
import 'package:flutter/material.dart';

class MicrophonePermissionRationaleDialog extends StatelessWidget {
  const MicrophonePermissionRationaleDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const MicrophonePermissionRationaleDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.mic_none, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Expanded(child: Text('Microphone permission')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To record audio from a meeting, we need access to your microphone.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SummaryBulletList(
              compact: true,
              points: const [
                'Record meeting audio while you take notes',
                'Transcribe and summarize after you stop recording',
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Next, your device will show the system permission prompt.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

