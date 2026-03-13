import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:goatly_meeting_transcriber_summarizer/src/audio/audio_capture_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/controllers/app_controller.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/models/meeting.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/repository/meeting_repository.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/services/ai_consent_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/services/app_mode_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/services/backend_api_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/services/device_id_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/services/usage_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/summary/managed_summary_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/summary/openrouter_summary_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/transcription/fal_transcription_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/transcription/managed_transcription_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/ui/app_shell.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/ui/dialogs/delete_confirmation_dialog.dart';

void main() {
  testWidgets('Delete meeting dialog shows and can be cancelled',
      (WidgetTester tester) async {
    final tempDir = Directory.systemTemp.createTempSync('delete_test_');
    final recordingsDir = Directory('${tempDir.path}/recordings')..createSync();
    final meetingsDir = Directory('${tempDir.path}/meetings')..createSync();

    final audioService = AudioCaptureService(recordingsDir: recordingsDir);
    final repository = MeetingRepository(meetingsDir: meetingsDir);

    SharedPreferences.setMockInitialValues({
      'has_shown_onboarding': true,
      'app_mode': 'openSource',
    });
    final prefs = await SharedPreferences.getInstance();
    final aiConsentService = AiConsentService(prefs: prefs);
    final appModeService = AppModeService(prefs: prefs);
    final backendApiService = BackendApiService(deviceIdService: DeviceIdService());
    final usageService = UsageService(backendApi: backendApiService);

    final controller = AppController(
      audioService: audioService,
      managedTranscriptionService: ManagedTranscriptionService(
        backendApi: backendApiService,
        usageService: usageService,
      ),
      managedSummaryService: ManagedSummaryService(backendApi: backendApiService),
      falService: FalTranscriptionService(),
      openRouterService: OpenRouterSummaryService(
        appUrl: 'https://github.com/test/test',
        appTitle: 'Test',
      ),
      repository: repository,
      aiConsentService: aiConsentService,
      appModeService: appModeService,
      backendApiService: backendApiService,
      usageService: usageService,
    );
    await controller.init();

    // Add a meeting
    final meeting = Meeting.create();
    meeting.title = 'Test Meeting';
    await repository.save(meeting);
    await controller.init(); // Refresh meetings
    controller.selectMeeting(controller.allMeetings.first);

    await tester.pumpWidget(MaterialApp(
      home: AppShell(controller: controller),
    ));

    // Find delete button
    final deleteButton = find.byTooltip('Delete');
    expect(deleteButton, findsOneWidget);

    // Tap delete
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Check if dialog is shown
    expect(find.byType(DeleteConfirmationDialog), findsOneWidget);
    expect(find.text('Delete meeting?'), findsOneWidget);

    // Cancel deletion
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Check if dialog is gone and meeting still exists
    expect(find.byType(DeleteConfirmationDialog), findsNothing);
    expect(controller.allMeetings.length, 1);
  });

  testWidgets('Delete meeting dialog shows and can confirm deletion',
      (WidgetTester tester) async {
    final tempDir = Directory.systemTemp.createTempSync('delete_test_confirm_');
    final recordingsDir = Directory('${tempDir.path}/recordings')..createSync();
    final meetingsDir = Directory('${tempDir.path}/meetings')..createSync();

    final audioService = AudioCaptureService(recordingsDir: recordingsDir);
    final repository = MeetingRepository(meetingsDir: meetingsDir);

    SharedPreferences.setMockInitialValues({
      'has_shown_onboarding': true,
      'app_mode': 'openSource',
    });
    final prefs = await SharedPreferences.getInstance();
    final aiConsentService = AiConsentService(prefs: prefs);
    final appModeService = AppModeService(prefs: prefs);
    final backendApiService = BackendApiService(deviceIdService: DeviceIdService());
    final usageService = UsageService(backendApi: backendApiService);

    final controller = AppController(
      audioService: audioService,
      managedTranscriptionService: ManagedTranscriptionService(
        backendApi: backendApiService,
        usageService: usageService,
      ),
      managedSummaryService: ManagedSummaryService(backendApi: backendApiService),
      falService: FalTranscriptionService(),
      openRouterService: OpenRouterSummaryService(
        appUrl: 'https://github.com/test/test',
        appTitle: 'Test',
      ),
      repository: repository,
      aiConsentService: aiConsentService,
      appModeService: appModeService,
      backendApiService: backendApiService,
      usageService: usageService,
    );
    await controller.init();

    // Add a meeting
    final meeting = Meeting.create();
    meeting.title = 'Test Meeting';
    await repository.save(meeting);
    await controller.init(); // Refresh meetings
    controller.selectMeeting(controller.allMeetings.first);

    await tester.pumpWidget(MaterialApp(
      home: AppShell(controller: controller),
    ));

    // Tap delete
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();

    // Confirm deletion
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Check if dialog is gone and meeting is deleted
    expect(find.byType(DeleteConfirmationDialog), findsNothing);
    expect(controller.allMeetings.length, 0);
  });
}
