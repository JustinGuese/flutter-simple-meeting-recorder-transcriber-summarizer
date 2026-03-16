import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';

import 'audio_backend.dart';

class StubAudioCaptureBackend implements AudioCaptureBackend {
  StubAudioCaptureBackend({required Directory recordingsDir})
      : _recordingsDir = recordingsDir;

  final Directory _recordingsDir;

  @override
  RecordingState get state => RecordingState.idle;

  @override
  Future<void> Function(Duration elapsed)? onHourElapsed;

  @override
  Stream<double>? get audioLevelStream => null;

  @override
  Future<void> startRecording() async {
    throw UnsupportedError(
      'Audio recording is not supported on this platform.',
    );
  }

  @override
  Future<List<XFile>> stopAndSave() async {
    return <XFile>[];
  }
}

