import 'package:df_ui_widgets/df_ui_widgets.dart';
import 'package:flutter/material.dart';

class AiDataProcessingDialog extends StatelessWidget {
  const AiDataProcessingDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AiDataProcessingDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.smart_toy_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Expanded(child: Text('AI Processing Consent')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We will transcribe and summarize your meeting using AI services.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SummaryBulletList(
              compact: true,
              points: const [
                'Audio will be sent to transcription service (Fal Whisper)',
                'Transcripts will be sent to summarization service (OpenRouter)',
                'Data is processed according to the service providers\' privacy policies',
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You can review the privacy policies of these services before proceeding.',
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
          child: const Text('Decline'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('I agree'),
        ),
      ],
    );
  }
}
