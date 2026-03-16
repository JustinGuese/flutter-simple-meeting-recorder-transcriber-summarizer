import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/backend_api_service.dart';
import '../../services/usage_service.dart';

class PaywallDialog extends StatefulWidget {
  final UsageInfo currentUsage;
  final VoidCallback onSwitchToOpenSource;
  final BackendApiService? backendApiService;
  final bool isSignedIn;
  final VoidCallback? onNavigateToLogin;

  const PaywallDialog({
    super.key,
    required this.currentUsage,
    required this.onSwitchToOpenSource,
    this.backendApiService,
    this.isSignedIn = false,
    this.onNavigateToLogin,
  });

  static Future<void> show(
    BuildContext context,
    UsageInfo usage, {
    required VoidCallback onSwitchToOpenSource,
    BackendApiService? backendApiService,
    bool isSignedIn = false,
    VoidCallback? onNavigateToLogin,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PaywallDialog(
        currentUsage: usage,
        onSwitchToOpenSource: onSwitchToOpenSource,
        backendApiService: backendApiService,
        isSignedIn: isSignedIn,
        onNavigateToLogin: onNavigateToLogin,
      ),
    );
  }

  @override
  State<PaywallDialog> createState() => _PaywallDialogState();
}

class _PaywallDialogState extends State<PaywallDialog> {
  Future<void> _launchUpgradeEmail() async {
    final subject = Uri.encodeComponent(
      'Premium Request for GOATLY meeting summarizer',
    );
    final body = Uri.encodeComponent(
      'Hello!\n\n'
      'I am interested in purchasing the managed premium version of GOATLY Meeting Summarizer.\n\n'
      'Please contact me with further information about pricing and available plans.\n\n'
      'Phone (optional): \n\n'
      'Thank you!',
    );
    final uri = Uri.parse(
      'mailto:info@datafortress.cloud?subject=$subject&body=$body',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email client')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Free Tier Limit Reached'),
      contentPadding: const EdgeInsets.all(24),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You've used ${widget.currentUsage.meetingsUsed}/${widget.currentUsage.meetingsLimit} meetings and "
              "${widget.currentUsage.minutesUsed}/${widget.currentUsage.minutesLimit} minutes of your free tier.",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              'Upgrade to continue:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildTierCard(
              tier: 'm',
              label: 'M',
              price: '€2.99/month',
              features: ['4 hours per month', 'Gemini Flash model'],
            ),
            const SizedBox(height: 12),
            _buildTierCard(
              tier: 'pro',
              label: 'Pro',
              price: '€39.99/month',
              features: ['Unlimited transcriptions', 'Gemini Pro model'],
              isPro: true,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onSwitchToOpenSource,
                child: const Text('Or use Open Source mode'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildTierCard({
    required String tier,
    required String label,
    required String price,
    required List<String> features,
    bool isPro = false,
  }) {
    return Card(
      elevation: isPro ? 4 : 1,
      color: isPro ? Colors.blue.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPro ? Colors.blue : Colors.grey.shade300,
          width: isPro ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$label Tier',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                if (isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Popular',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Text('✓ ', style: TextStyle(color: Colors.green)),
                    Expanded(child: Text(f)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _launchUpgradeEmail,
                icon: const Icon(Icons.email_outlined, size: 18),
                label: const Text('Request Upgrade'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
