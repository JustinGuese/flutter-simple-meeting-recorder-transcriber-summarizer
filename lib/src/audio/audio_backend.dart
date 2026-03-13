import 'dart:async';

import 'package:cross_file/cross_file.dart';

enum RecordingState { idle, recording }

abstract class AudioCaptureBackend {
  RecordingState get state;

  Future<void> startRecording();

  Future<List<XFile>> stopAndSave();

  Future<void> Function(Duration elapsed)? get onHourElapsed;

  set onHourElapsed(Future<void> Function(Duration elapsed)? callback);

  Stream<double>? get audioLevelStream;
}

