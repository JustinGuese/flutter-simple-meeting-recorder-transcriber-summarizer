import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:goatly_meeting_transcriber_summarizer/src/audio/audio_capture_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/controllers/app_controller.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/models/meeting.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/repository/meeting_repository.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/services/ai_consent_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/services/app_mode_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/summary/openrouter_summary_service.dart';
import 'package:goatly_meeting_transcriber_summarizer/src/transcription/fal_transcription_service.dart';
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

    final transcriptionService = _FakeFalService();
    final summaryService = _FakeSummaryService();

    final controller = AppController(
      audioService: audioService,
      transcriptionService: transcriptionService,
      summaryService: summaryService,
      repository: repository,
      aiConsentService: aiConsentService,
      appModeService: appModeService,
      backendApiService: null,
      usageService: null,
    );

    await controller.init();

    // Start and stop recording, which will invoke transcription and summary.
    await controller.startRecording();
    await controller.stopRecording();

    final meetings = await repository.loadAll();
    expect(meetings, isNotEmpty);
    final loaded = meetings.first;

    expect(loaded.transcription, isNotEmpty);
    expect(loaded.summaryStatus, SummaryStatus.completed);
    expect(loaded.summary, isNotNull);
    expect(loaded.summary, contains('hello world transcript'));
  });
}
