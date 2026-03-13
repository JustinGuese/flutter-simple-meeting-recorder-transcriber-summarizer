import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

import 'audio_backend.dart';

class MobileAudioCaptureBackend implements AudioCaptureBackend {
  MobileAudioCaptureBackend({required Directory recordingsDir})
      : _recordingsDir = recordingsDir;

  final Directory _recordingsDir;
  final AudioRecorder _recorder = AudioRecorder();

  RecordingState _state = RecordingState.idle;

  @override
  RecordingState get state => _state;

  @override
  Future<void> Function(Duration elapsed)? onHourElapsed;

  @override
  Stream<double>? get audioLevelStream => null;

  @override
  Future<void> startRecording() async {
    if (_state == RecordingState.recording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw StateError('Microphone permission not granted.');
    }

    if (!await _recordingsDir.exists()) {
      await _recordingsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final path =
        p.join(_recordingsDir.path, 'meeting-$timestamp-mobile-mic.m4a');

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacHe,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );

    _state = RecordingState.recording;
  }

  @override
  Future<List<XFile>> stopAndSave() async {
    if (_state != RecordingState.recording) return <XFile>[];

    _state = RecordingState.idle;

    final path = await _recorder.stop();
    if (path == null) {
      return <XFile>[];
    }

    return <XFile>[XFile(path)];
  }
}

