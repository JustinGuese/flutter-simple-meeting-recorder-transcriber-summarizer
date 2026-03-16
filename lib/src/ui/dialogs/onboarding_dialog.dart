import 'package:flutter/material.dart';

import '../../services/app_mode_service.dart';

class OnboardingDialog extends StatefulWidget {
  final void Function(AppMode mode) onModeSelected;

  const OnboardingDialog({
    super.key,
    required this.onModeSelected,
  });

  static Future<AppMode?> show(BuildContext context) async {
    return showDialog<AppMode?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OnboardingDialog(
        onModeSelected: (mode) {
          Navigator.pop(context, mode);
        },
      ),
    );
  }

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  AppMode _selectedMode = AppMode.managed;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Welcome to Meeting Recorder'),
      contentPadding: const EdgeInsets.all(24),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How do you want to use the AI features?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            _buildModeCard(
              mode: AppMode.managed,
              title: 'Managed (Recommended)',
              features: [
                'No API keys needed',
                '3 free meetings to start',
                'Upgrade for more',
              ],
              highlight: true,
            ),
            const SizedBox(height: 12),
            _buildModeCard(
              mode: AppMode.openSource,
              title: 'Open Source / Bring Your Own Keys',
              features: [
                'Use your own FAL and OpenRouter API keys',
                'No usage limits',
                'Full control',
              ],
              highlight: false,
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => widget.onModeSelected(_selectedMode),
          child: const Text('Get Started'),
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required AppMode mode,
    required String title,
    required List<String> features,
    required bool highlight,
  }) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: Card(
        color: isSelected
            ? (highlight ? Colors.blue.shade50 : Colors.grey.shade50)
            : Colors.transparent,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Radio<AppMode>(
                    value: mode,
                    groupValue: _selectedMode,
                    onChanged: (m) => setState(() => _selectedMode = m!),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(left: 40, bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✓ ', style: TextStyle(color: Colors.green)),
                      Expanded(child: Text(f)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
