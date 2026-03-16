import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:go_router/go_router.dart';

import '../../services/app_mode_service.dart';
import '../../services/auth_service.dart';
import '../../services/backend_api_service.dart';
import '../../services/usage_service.dart';
import '../../transcription/fal_transcription_service.dart';
import '../../summary/openrouter_summary_service.dart';
import '../dialogs/api_key_dialog.dart';

class SettingsPage extends StatefulWidget {
  final AppModeService appModeService;
  final UsageService? usageService;
  final VoidCallback onModeChanged;
  final FalTranscriptionService? falService;
  final OpenRouterSummaryService? openRouterService;
  final AuthService? authService;
  final BackendApiService? backendApiService;

  const SettingsPage({
    super.key,
    required this.appModeService,
    this.usageService,
    required this.onModeChanged,
    this.falService,
    this.openRouterService,
    this.authService,
    this.backendApiService,
  });

  static Future<void> show(
    BuildContext context, {
    required AppModeService appModeService,
    UsageService? usageService,
    required VoidCallback onModeChanged,
    FalTranscriptionService? falService,
    OpenRouterSummaryService? openRouterService,
    AuthService? authService,
    BackendApiService? backendApiService,
  }) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => SettingsPage(
            appModeService: appModeService,
            usageService: usageService,
            onModeChanged: onModeChanged,
            falService: falService,
            openRouterService: openRouterService,
            authService: authService,
            backendApiService: backendApiService,
          ),
        ),
      );

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppMode _selectedMode;
  AuthUser? _currentUser;
  StreamSubscription<AuthUser?>? _authSub;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.appModeService.currentMode;
    _currentUser = widget.authService?.currentUser;
    _authSub = widget.authService?.authStateChanges.listen((user) {
      if (mounted) setState(() => _currentUser = user);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

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
    final isManagedMode = _selectedMode == AppMode.managed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          if (isManagedMode) ...[
            _buildSectionTitle('Account'),
            _buildAccountSection(),
            const Divider(),
            _buildSectionTitle('Usage'),
            _buildUsageSection(),
            const Divider(),
          ],
          _buildSectionTitle('Mode'),
          _buildModeSection(),
          const Divider(),
          if (!isManagedMode) ...[
            _buildSectionTitle('API Keys'),
            _buildApiKeysSection(),
            const Divider(),
          ],
          _buildSectionTitle('About'),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentUser != null) ...[
            Text('Signed in as:',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Text(_currentUser!.email ?? 'User'),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () async {
                await widget.authService?.signOut();
              },
              child: const Text('Sign Out'),
            ),
          ] else ...[
            const Text('You are not signed in.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.pop(context); // close settings first
                context.go('/login');
              },
              child: const Text('Sign In / Create Account'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsageSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: FutureBuilder<UsageInfo>(
        future: widget.usageService?.fetchUsage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          final usage = snapshot.data;
          if (usage == null) {
            return const Text('Unable to load usage');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(usage.displayString,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Chip(
                label: Text(usage.tier.toUpperCase()),
                backgroundColor: _getTierColor(usage.tier),
              ),
              if (!usage.isLimitReached) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _launchUpgradeEmail,
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: const Text('Request Upgrade'),
                ),
              ],
              if (kDebugMode && widget.backendApiService != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: () async {
                    await widget.backendApiService!.debugResetUsage();
                    if (context.mounted) {
                      setState(() {}); // triggers usage FutureBuilder refresh
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Usage reset — restart app to reflect'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: const Text('[DEV] Reset usage counters'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select how to provide transcription and summarization services:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          SegmentedButton<AppMode>(
            segments: const [
              ButtonSegment(label: Text('Managed'), value: AppMode.managed),
              ButtonSegment(
                  label: Text('Open Source'), value: AppMode.openSource),
            ],
            selected: {_selectedMode},
            onSelectionChanged: (Set<AppMode> newSelection) async {
              setState(() => _selectedMode = newSelection.first);
              await widget.appModeService.setMode(_selectedMode);
              widget.onModeChanged();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Switched to ${_selectedMode == AppMode.managed ? 'Managed' : 'Open Source'} mode',
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          Text(
            _selectedMode == AppMode.managed
                ? 'Use our managed service for transcription and summarization.'
                : 'Provide your own FAL and OpenRouter API keys.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeysSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          const Text(
            'Configure your API keys for FAL Whisper and OpenRouter.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed:
                widget.falService != null && widget.openRouterService != null
                    ? () => showApiKeyDialog(
                          context,
                          widget.falService!,
                          widget.openRouterService!,
                        )
                    : null,
            child: const Text('Configure API Keys'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meeting Recorder & Transcriber',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            'Version 0.1.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'm':
        return Colors.blue.shade300;
      case 'pro':
        return Colors.amber.shade300;
      default:
        return Colors.grey.shade300;
    }
  }
}
