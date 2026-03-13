import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';

import 'audio_backend.dart';
import 'audio_capture_service_desktop.dart';
import 'audio_capture_service_mobile.dart';
import 'audio_capture_service_stub.dart';

class AudioCaptureService {
  AudioCaptureService._(this._backend);

  final AudioCaptureBackend _backend;

  factory AudioCaptureService({required Object recordingsDir}) {
    final dir = recordingsDir is Directory
        ? recordingsDir
        : throw ArgumentError.value(
            recordingsDir,
            'recordingsDir',
            'Expected a dart:io Directory on IO platforms.',
          );
    const isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
    if (isFlutterTest) {
      return AudioCaptureService._(
        StubAudioCaptureBackend(recordingsDir: dir),
      );
    }
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return AudioCaptureService._(
        DesktopAudioCaptureBackend(recordingsDir: dir),
      );
    }
    if (Platform.isAndroid || Platform.isIOS) {
      return AudioCaptureService._(
        MobileAudioCaptureBackend(recordingsDir: dir),
      );
    }
    return AudioCaptureService._(
      StubAudioCaptureBackend(recordingsDir: dir),
    );
  }

  RecordingState get state => _backend.state;

  Future<void> startRecording() => _backend.startRecording();

  Future<List<XFile>> stopAndSave() => _backend.stopAndSave();

  Future<void> Function(Duration elapsed)? get onHourElapsed =>
      _backend.onHourElapsed;

  set onHourElapsed(Future<void> Function(Duration elapsed)? callback) {
    _backend.onHourElapsed = callback;
  }

  Stream<double>? get audioLevelStream => _backend.audioLevelStream;
}

