import 'dart:async';
import 'dart:typed_data';

import 'dart:html' as html;
import 'package:cross_file/cross_file.dart';
import 'package:record/record.dart';

import 'audio_backend.dart';

// Web/Chrome-only backend: records mic via MediaRecorder.
class WebAudioCaptureBackend implements AudioCaptureBackend {
  WebAudioCaptureBackend();

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

    await _recorder.start(
      const RecordConfig(
        // Web impl uses MediaRecorder; opus/webm is the most common output.
        encoder: AudioEncoder.opus,
        numChannels: 1,
      ),
      // On web, the plugin returns a blob: URL on stop; file paths are not used.
      path: '',
    );

    _state = RecordingState.recording;
  }

  @override
  Future<List<XFile>> stopAndSave() async {
    if (_state != RecordingState.recording) return <XFile>[];
    _state = RecordingState.idle;

    final blobUrl = await _recorder.stop();
    if (blobUrl == null || blobUrl.isEmpty) {
      return <XFile>[];
    }

    final bytes = await _downloadBlobUrl(blobUrl);
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final name = 'meeting-$timestamp-web-mic.webm';

    return <XFile>[
      XFile.fromData(
        bytes,
        name: name,
        mimeType: 'audio/webm',
      ),
    ];
  }

  Future<Uint8List> _downloadBlobUrl(String url) async {
    final req = await html.HttpRequest.request(
      url,
      responseType: 'arraybuffer',
    );
    final response = req.response;
    if (response is ByteBuffer) {
      return Uint8List.view(response);
    }
    if (response is Uint8List) {
      return response;
    }
    throw StateError('Unexpected blob download response type: ${response.runtimeType}');
  }
}

class AudioCaptureService {
  AudioCaptureService._(this._backend);

  final AudioCaptureBackend _backend;

  factory AudioCaptureService({required Object recordingsDir}) {
    // recordingsDir is ignored on web, but we keep the same ctor shape as IO so
    // main.dart can build a single service graph.
    const isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
    if (isFlutterTest) {
      // Web tests still shouldn’t attempt to access MediaRecorder.
      return AudioCaptureService._(_UnsupportedBackend());
    }
    return AudioCaptureService._(WebAudioCaptureBackend());
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

class _UnsupportedBackend implements AudioCaptureBackend {
  @override
  RecordingState get state => RecordingState.idle;

  @override
  Future<void> Function(Duration elapsed)? onHourElapsed;

  @override
  Stream<double>? get audioLevelStream => null;

  @override
  Future<void> startRecording() async {
    throw UnsupportedError(
      'Audio recording is not supported in tests on web.',
    );
  }

  @override
  Future<List<XFile>> stopAndSave() async => <XFile>[];
}

