import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../summary/openrouter_summary_service.dart';
import '../../transcription/fal_transcription_service.dart';

Future<void> showApiKeyDialog(
  BuildContext context,
  FalTranscriptionService falService,
  OpenRouterSummaryService summaryService,
) {
  final falController = TextEditingController();
  final openRouterController = TextEditingController();

  return showDialog<void>(
    context: context,
    builder: (context) => FutureBuilder<List<String?>>(
      future: Future.wait([
        falService.loadCurrentKeySource(),
        summaryService.loadCurrentKeySource(),
      ]),
      builder: (context, snapshot) {
        final falSource = snapshot.data != null && snapshot.data!.isNotEmpty
            ? snapshot.data![0]
            : null;
        final openRouterSource =
            snapshot.data != null && snapshot.data!.length > 1
                ? snapshot.data![1]
                : null;

        return AlertDialog(
          title: const Text('API Keys'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Open Source mode active — your own keys are used.',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              if (falSource != null) ...[
                Text(
                  'FAL key source: $falSource',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: falController,
                decoration: InputDecoration(
                  labelText: 'Override FAL_KEY',
                  helperText:
                      'Stored securely on this device. Leave empty to keep existing.',
                  helperMaxLines: 3,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Get a key at '),
                  InkWell(
                    onTap: () => launchUrl(Uri.parse('https://fal.ai/dashboard/keys')),
                    child: Text(
                      'https://fal.ai/dashboard/keys',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (openRouterSource != null) ...[
                Text(
                  'OpenRouter key source: $openRouterSource',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: openRouterController,
                decoration: InputDecoration(
                  labelText: 'Override OPENROUTER_API_KEY',
                  helperText:
                      'Stored securely on this device. Leave empty to keep existing.',
                  helperMaxLines: 3,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Get a key at '),
                  InkWell(
                    onTap: () => launchUrl(Uri.parse('https://openrouter.ai/settings/keys')),
                    child: Text(
                      'https://openrouter.ai/settings/keys',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final falValue = falController.text.trim();
                    if (falValue.isNotEmpty) {
                      await falService.saveOverrideKey(falValue);
                    }

                    final openRouterValue = openRouterController.text.trim();
                    if (openRouterValue.isNotEmpty) {
                      await summaryService.saveOverrideKey(openRouterValue);
                    }

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}
