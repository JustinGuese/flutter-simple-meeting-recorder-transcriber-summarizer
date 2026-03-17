import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:df_audio_capture/df_audio_capture.dart';
import 'package:df_device_id/df_device_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:goatly_meeting_transcriber_summarizer/src/controllers/app_controller.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/repository/meeting_repository.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/services/ai_consent_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/services/app_mode_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/services/backend_api_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/services/usage_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/summary/managed_summary_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/summary/openrouter_summary_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/transcription/fal_transcription_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/transcription/managed_transcription_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/transcription/models.dart';

class _FakeFalService extends FalTranscriptionService {
  _FakeFalService() : super();

  @override
  Future<TranscriptionResult> transcribeBlocking(XFile audioFile) async {
    return TranscriptionResult(
      text: 'hello world transcript',
      chunks: const [],
      languages: const ['en'],
    );
  }
}

class _FakeSummaryService extends OpenRouterSummaryService {
  _FakeSummaryService() : super();

  @override
  Future<MeetingSummaryResult> summarizeWithTitle({
    required String transcript,
    String? title,
    String? notes,
    String? modelOverride,
  }) async {
    return MeetingSummaryResult(
      title: 'Test Meeting',
      summary: 'summary for: $transcript',
    );
  }
}

void main() {
  test('AppController triggers summary after transcription', () async {
    final tempDir = await Directory.systemTemp.createTemp('meetings_test');
    final recordingsDir =
        await Directory.systemTemp.createTemp('recordings_test');
    final repository = MeetingRepository(meetingsDir: tempDir);
    final audioService = AudioCaptureService(recordingsDir: recordingsDir);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final aiConsentService = AiConsentService(prefs: prefs);
    final appModeService = AppModeService(prefs: prefs);

    final falService = _FakeFalService();
    final openRouterService = _FakeSummaryService();
    final backendApiService =
        BackendApiService(deviceIdService: DeviceIdService());
    final usageService = UsageService(backendApi: backendApiService);
    final managedTranscription = ManagedTranscriptionService(
      backendApi: backendApiService,
      usageService: usageService,
    );
    final managedSummary = ManagedSummaryService(backendApi: backendApiService);

    final controller = AppController(
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

    // Start and stop recording, which will invoke transcription and summary.
    await controller.startRecording();
    await controller.stopRecording();

    final meetings = await repository.loadAll();
    expect(meetings.length, 1);
  });
}
