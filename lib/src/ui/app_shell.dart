import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../controllers/app_controller.dart';
import '../services/app_mode_service.dart';
import '../services/usage_service.dart';
import 'content/empty_state_view.dart';
import 'content/meeting_detail_view.dart';
import 'content/recording_overlay.dart';
import 'dialogs/onboarding_dialog.dart';
import 'dialogs/paywall_dialog.dart';
import 'sidebar/sidebar_panel.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!widget.controller.appModeService.hasShownOnboarding) {
        final mode = await OnboardingDialog.show(context);
        if (mode != null) {
          await widget.controller.appModeService.setMode(mode);
          await widget.controller.appModeService.markOnboardingShown();
          widget.controller.onModeChanged();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final isRecording = widget.controller.activeMeeting != null;
        final selectedMeeting = widget.controller.selectedMeeting;
        final isActiveMeeting =
            selectedMeeting?.id == widget.controller.activeMeeting?.id;

        // Check for pending paywall
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.controller.pendingPaywall != null) {
            final paywall = widget.controller.pendingPaywall;
            widget.controller.clearPendingPaywall();
            if (paywall != null) {
              final usage = UsageInfo.fromFreeTierException(paywall);
              PaywallDialog.show(
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
            }
          }
        });

        return Scaffold(
          body: Row(
            children: [
              // Left sidebar
              SidebarPanel(controller: widget.controller),
              // Right content area
              Expanded(
                child: Stack(
                  children: [
                    // Content view
                    if (selectedMeeting == null)
                      const EmptyStateView()
                    else
                      MeetingDetailView(
                        meeting: selectedMeeting,
                        controller: widget.controller,
                        isActive: isActiveMeeting,
                      ),
                    // Recording overlay (bottom bar)
                    if (isRecording)
                      RecordingOverlay(controller: widget.controller),
                    // Recording header (top bar) when active
                    if (isRecording)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Theme.of(context).colorScheme.errorContainer,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.fiber_manual_record,
                                color: Theme.of(context).colorScheme.error,
                                size: 12,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Recording in progress',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer,
                                      ),
                                ),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () =>
                                    widget.controller
                                        .stopRecordingWithAiConsent(context),
                                icon: const Icon(Icons.stop),
                                label: const Text('Stop'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
