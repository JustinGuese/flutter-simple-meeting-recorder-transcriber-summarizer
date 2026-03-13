import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/app_controller.dart';
import '../../services/app_mode_service.dart';
import '../dialogs/api_key_dialog.dart';
import '../dialogs/microphone_permission_rationale_dialog.dart';
import '../dialogs/paywall_dialog.dart';
import '../pages/settings_page.dart';
import 'meeting_list_tile.dart';

class SidebarPanel extends StatefulWidget {
  const SidebarPanel({super.key, required this.controller});

  final AppController controller;

  @override
  State<SidebarPanel> createState() => _SidebarPanelState();
}

class _SidebarPanelState extends State<SidebarPanel> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showOnboarding(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _OnboardingDialog(),
    );
  }

  bool _shouldShowMicRationale() {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS => true,
      _ => false,
    };
  }

  Future<void> _handleStartRecording(BuildContext context) async {
    // Check usage limit before starting (managed mode only)
    if (widget.controller.isManagedMode) {
      try {
        final usage =
            await widget.controller.usageService.fetchUsage();
        if (usage.isLimitReached) {
          if (!context.mounted) return;
          await PaywallDialog.show(
            context,
            usage,
            onSwitchToOpenSource: () async {
              Navigator.pop(context);
              await widget.controller.appModeService
                  .setMode(AppMode.openSource);
              widget.controller.onModeChanged();
            },
            backendApiService: widget.controller.backendApiService,
            isSignedIn: widget.controller.isSignedIn,
            onNavigateToLogin: () => context.go('/login'),
          );
          return;
        }
      } catch (_) {
        // If check fails, let the backend enforce it during transcription
      }
    }

    if (_shouldShowMicRationale()) {
      final proceed = await MicrophonePermissionRationaleDialog.show(context);
      if (!proceed) return;
    }
    await widget.controller.startRecording();
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder here ensures the sidebar always rebuilds when
    // controller state changes (recording start/stop, new meetings, search).
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final isRecording = widget.controller.activeMeeting != null;

        return Container(
          width: 280,
          color: theme.colorScheme.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Meeting Recorder',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      tooltip: 'Help & Setup',
                      onPressed: () => _showOnboarding(context),
                      iconSize: 20,
                    ),
                    IconButton(
                      icon: const Icon(Icons.folder_open),
                      tooltip: 'Open Folder',
                      onPressed: widget.controller.openMeetingsFolder,
                      iconSize: 20,
                    ),
                    if (!widget.controller.isManagedMode)
                      IconButton(
                        icon: const Icon(Icons.vpn_key_outlined),
                        tooltip: 'Configure API keys',
                        onPressed: () => showApiKeyDialog(
                          context,
                          widget.controller.falService,
                          widget.controller.openRouterService,
                        ),
                        iconSize: 20,
                      ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Settings',
                      onPressed: () => SettingsPage.show(
                        context,
                        appModeService: widget.controller.appModeService,
                        usageService: widget.controller.usageService,
                        onModeChanged: widget.controller.onModeChanged,
                        falService: widget.controller.falService,
                        openRouterService: widget.controller.openRouterService,
                        authService: widget.controller.authService,
                        backendApiService: widget.controller.backendApiService,
                      ),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Search + Sort
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search meetings...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    widget.controller.setSearchQuery('');
                                  },
                                )
                              : null,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onChanged: (val) {
                          widget.controller.setSearchQuery(val);
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<MeetingSortOrder>(
                      icon: Icon(
                        Icons.swap_vert,
                        color: widget.controller.sortOrder !=
                                MeetingSortOrder.recentlyModified
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Sort by',
                      onSelected: widget.controller.setSortOrder,
                      itemBuilder: (context) => [
                        CheckedPopupMenuItem(
                          value: MeetingSortOrder.recentlyModified,
                          checked: widget.controller.sortOrder ==
                              MeetingSortOrder.recentlyModified,
                          child: const Text('Recently modified'),
                        ),
                        CheckedPopupMenuItem(
                          value: MeetingSortOrder.title,
                          checked: widget.controller.sortOrder ==
                              MeetingSortOrder.title,
                          child: const Text('Title'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Record / Stop button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: isRecording
                    ? FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(context).colorScheme.onError,
                        ),
                        onPressed: widget.controller.stopRecording,
                        icon: const Icon(Icons.stop),
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Stop & transcribe'),
                            RecordingTimerInline(
                              elapsed: widget.controller.elapsedRecording,
                            ),
                          ],
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: () => _handleStartRecording(context),
                        icon: const Icon(Icons.mic),
                        label: const Text('Start recording'),
                      ),
              ),
              const Divider(height: 16),
              // Meeting list
              Expanded(
                child: ListView.builder(
                  itemCount: widget.controller.filteredMeetings.length,
                  itemBuilder: (context, index) {
                    final meeting = widget.controller.filteredMeetings[index];
                    final isRecordingThis =
                        widget.controller.activeMeeting?.id == meeting.id;
                    final isSelected =
                        widget.controller.selectedMeeting?.id == meeting.id;

                    return MeetingListTile(
                      meeting: meeting,
                      isSelected: isSelected,
                      isRecording: isRecordingThis,
                      controller: widget.controller,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact timer text shown inline in the stop button.
class RecordingTimerInline extends StatelessWidget {
  const RecordingTimerInline({super.key, required this.elapsed});
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final h = elapsed.inHours;
    final m = elapsed.inMinutes % 60;
    final s = elapsed.inSeconds % 60;
    final text = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return Text(
      text,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
    );
  }
}

class _OnboardingDialog extends StatelessWidget {
  const _OnboardingDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Welcome to Meeting Recorder'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Setup Required',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildStep(
              context,
              '1. Get FAL API Key',
              'Visit https://fal.ai/dashboard/keys to create a free account and generate your FAL API key.',
            ),
            const SizedBox(height: 12),
            _buildStep(
              context,
              '2. Configure Key',
              'Click the key icon (🔑) in the sidebar to paste your FAL API key securely.',
            ),
            const SizedBox(height: 12),
            _buildStep(
              context,
              '3. Get OpenRouter API Key',
              'Visit https://openrouter.ai/settings/keys to create or retrieve your OpenRouter API key.',
            ),
            const SizedBox(height: 24),
            Text(
              'How It Works',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildStep(
              context,
              '📹 Record',
              'Click "Start recording" to capture mic + system audio. Add notes anytime.',
            ),
            const SizedBox(height: 12),
            _buildStep(
              context,
              '✨ Transcribe',
              'Click "Stop & transcribe" to send audio to FAL Whisper for transcription.',
            ),
            const SizedBox(height: 12),
            _buildStep(
              context,
              '💾 Save & Edit',
              'Meetings auto-save. Edit title, notes, and transcript anytime.',
            ),
            const SizedBox(height: 12),
            _buildStep(
              context,
              '🔍 Search',
              'Search by title, notes, or transcript content instantly.',
            ),
            const SizedBox(height: 12),
            _buildStep(
              context,
              '📁 Organize',
              'All meetings stored locally. Click folder icon to browse files.',
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it!'),
        ),
      ],
    );
  }

  Widget _buildStep(BuildContext context, String title, String description) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}
