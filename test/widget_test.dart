import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:goatly_meeting_transcriber_summarizer/main.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/audio/audio_capture_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/controllers/app_controller.dart';
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

AppController _makeController({
  required Directory tempDir,
  required Directory recordingsDir,
  required SharedPreferences prefs,
}) {
  final backendApiService =
      BackendApiService(deviceIdService: DeviceIdService());
  final usageService = UsageService(backendApi: backendApiService);
  return AppController(
    audioService: AudioCaptureService(recordingsDir: recordingsDir),
    managedTranscriptionService: ManagedTranscriptionService(
      backendApi: backendApiService,
      usageService: usageService,
    ),
    managedSummaryService: ManagedSummaryService(backendApi: backendApiService),
    falService: FalTranscriptionService(),
    openRouterService: OpenRouterSummaryService(
      appUrl:
          'https://github.com/guessedpencil/flutter-simple-meeting-recorder-transcriber-summarizer',
      appTitle: 'Meeting Recorder & Transcriber',
    ),
    repository: MeetingRepository(meetingsDir: tempDir),
    aiConsentService: AiConsentService(prefs: prefs),
    appModeService: AppModeService(prefs: prefs),
    backendApiService: backendApiService,
    usageService: usageService,
  );
}

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    final tempDir =
        Directory.systemTemp.createTempSync('meeting_recorder_test_');
    final recordingsDir =
        Directory('${tempDir.path}/recordings')..createSync();

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final controller = _makeController(
      tempDir: tempDir,
      recordingsDir: recordingsDir,
      prefs: prefs,
    );
    await controller.init();

    await tester.pumpWidget(MeetingRecorderApp(controller: controller));

    expect(find.byType(MeetingRecorderApp), findsOneWidget);
  });

  testWidgets('Shows microphone rationale before starting recording',
      (WidgetTester tester) async {
    final tempDir =
        Directory.systemTemp.createTempSync('meeting_recorder_test_');
    final recordingsDir =
        Directory('${tempDir.path}/recordings')..createSync();

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final controller = _makeController(
      tempDir: tempDir,
      recordingsDir: recordingsDir,
      prefs: prefs,
    );
    await controller.init();

    await tester.pumpWidget(MeetingRecorderApp(controller: controller));

    await tester.tap(find.widgetWithIcon(FilledButton, Icons.mic));
    await tester.pumpAndSettle();

    expect(find.text('Microphone permission'), findsOneWidget);
    expect(
      find.textContaining('record audio from a meeting'),
      findsOneWidget,
    );

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Microphone permission'), findsNothing);
  });
}
