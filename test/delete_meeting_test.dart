import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:df_audio_capture/df_audio_capture.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/controllers/app_controller.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/models/meeting.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/repository/meeting_repository.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/services/ai_consent_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/services/app_mode_service.dart';
import 'package:df_device_id/df_device_id.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/services/usage_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/services/backend_api_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/summary/managed_summary_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/summary/openrouter_summary_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/transcription/fal_transcription_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/transcription/managed_transcription_service.dart';

void main() {
  late Directory tempDir;
  late Directory recordingsDir;
  late MeetingRepository repository;
  late AppController controller;
  late SharedPreferences prefs;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('meeting_recorder_test_');
    recordingsDir = Directory('${tempDir.path}/recordings')..createSync();

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    final audioService = AudioCaptureService(recordingsDir: recordingsDir);
    repository = MeetingRepository(meetingsDir: tempDir);
    final aiConsentService = AiConsentService(prefs: prefs);
    final appModeService = AppModeService(prefs: prefs);
    final deviceIdService = DeviceIdService();
    final backendApiService =
        BackendApiService(deviceIdService: deviceIdService);
    final usageService = UsageService(backendApi: backendApiService);
    final managedTranscription = ManagedTranscriptionService(
      backendApi: backendApiService,
      usageService: usageService,
    );
    final managedSummary = ManagedSummaryService(backendApi: backendApiService);
    final falService = FalTranscriptionService();
    final openRouterService = OpenRouterSummaryService(
      appUrl: 'https://test.com',
      appTitle: 'Test',
    );

    controller = AppController(
      audioService: audioService,
      managedTranscriptionService: managedTranscription,
      managedSummaryService: managedSummary,
      falService: falService,
      openRouterService: openRouterService,
      repository: repository,
      aiConsentService: aiConsentService,
      appModeService: appModeService,
      backendApiService: backendApiService,
      usageService: usageService,
    );
    await controller.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('deleteMeeting removes meeting and associated files', () async {
    // Create a mock meeting with associated files
    final meeting = Meeting.create();
    meeting.title = 'Test Meeting';
    meeting.audioFilePath = 'recordings/test.m4a';

    // Create a dummy recording file
    final recordingFile = File('${recordingsDir.path}/test.m4a')..createSync();
    expect(recordingFile.existsSync(), isTrue);

    // Save meeting to repository
    await repository.save(meeting);
    expect((await repository.loadAll()).length, 1);

    // Refresh controller
    await controller.init();
    expect(controller.allMeetings.length, 1);

    // Perform deletion
    await controller.deleteMeeting(meeting);

    // Verify deletion
    expect(controller.allMeetings.isEmpty, isTrue);
    expect((await repository.loadAll()).isEmpty, isTrue);
    expect(recordingFile.existsSync(), isFalse);
  });
}
