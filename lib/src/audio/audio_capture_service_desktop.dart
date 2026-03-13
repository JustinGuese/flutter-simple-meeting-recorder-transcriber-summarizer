// ignore_for_file: uri_does_not_exist, undefined_class, undefined_method

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_audio_capture/audio_capture.dart';
import 'package:path/path.dart' as p;

import 'audio_backend.dart';

class DesktopAudioCaptureBackend implements AudioCaptureBackend {
  DesktopAudioCaptureBackend({required Directory recordingsDir})
      : _recordingsDir = recordingsDir;

  final Directory _recordingsDir;

  MicAudioCapture? _micCapture;
  SystemAudioCapture? _systemCapture;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<Uint8List>? _systemSub;
  final BytesBuilder _micBuffer = BytesBuilder(copy: false);
  final BytesBuilder _systemBuffer = BytesBuilder(copy: false);

  late final StreamController<double> _audioLevelController =
      StreamController<double>.broadcast();

  Timer? _hourlyTimer;
  DateTime? _startedAt;

  @override
  Future<void> Function(Duration elapsed)? onHourElapsed;

  @override
  Stream<double>? get audioLevelStream => _audioLevelController.stream;

  RecordingState _state = RecordingState.idle;

  @override
  RecordingState get state => _state;

  static const int _sampleRate = 16000;
  static const int _channels = 1;
  static const int _bitsPerSample = 16;

  @override
  Future<void> startRecording() async {
    if (_state == RecordingState.recording) return;

    _micBuffer.clear();
    _systemBuffer.clear();
    _startedAt = DateTime.now();

    final micCapture = MicAudioCapture(
      config: MicAudioConfig(
        sampleRate: _sampleRate,
        channels: _channels,
        bitDepth: _bitsPerSample,
      ),
    );

    await micCapture.startCapture();

    SystemAudioCapture? systemCapture;
    try {
      systemCapture = SystemAudioCapture(
        config: SystemAudioConfig(
          sampleRate: 44100,
          channels: 2,
        ),
      );
      await systemCapture.startCapture();
    } catch (_) {
      systemCapture = null;
    }

    _micCapture = micCapture;
    _systemCapture = systemCapture;
    _micSub = micCapture.audioStream?.listen(
      (chunk) {
        _micBuffer.add(chunk);
        _emitAudioLevel(chunk);
      },
      onError: (Object error, StackTrace stackTrace) {},
      cancelOnError: false,
    );

    if (systemCapture != null) {
      _systemSub = systemCapture.audioStream?.listen(
        (chunk) {
          _systemBuffer.add(chunk);
        },
        onError: (Object error, StackTrace stackTrace) {},
        cancelOnError: false,
      );
    }

    _hourlyTimer?.cancel();
    _hourlyTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      if (_state != RecordingState.recording || _startedAt == null) {
        _hourlyTimer?.cancel();
        return;
      }
      final cb = onHourElapsed;
      if (cb != null) {
        final elapsed = DateTime.now().difference(_startedAt!);
        await cb(elapsed);
      }
    });

    _state = RecordingState.recording;
  }

  @override
  Future<List<XFile>> stopAndSave() async {
    if (_state != RecordingState.recording) return <XFile>[];

    _state = RecordingState.idle;
    _hourlyTimer?.cancel();
    _hourlyTimer = null;

    await _micSub?.cancel();
    _micSub = null;

    await _systemSub?.cancel();
    _systemSub = null;

    await _micCapture?.stopCapture();
    _micCapture = null;

    await _systemCapture?.stopCapture();
    _systemCapture = null;

    _audioLevelController.add(0.0);

    final files = <XFile>[];

    if (_micBuffer.isEmpty && _systemBuffer.isEmpty) {
      return files;
    }

    // Mix mic and system audio into a single 16kHz mono WAV
    final micPcm = _micBuffer.takeBytes();
    final sysPcm = _systemBuffer.takeBytes();

    final mixedPcm = _mixToPcm16Mono(
      micPcm: micPcm,
      sysPcm: sysPcm,
    );

    final file = await _createRecordingFile(suffix: 'mixed');
    final wavBytes = _encodeWav(
      Uint8List.fromList(mixedPcm),
      sampleRate: _sampleRate,
      channels: _channels,
      bitsPerSample: _bitsPerSample,
    );
    await file.writeAsBytes(wavBytes, flush: true);
    files.add(XFile(file.path));

    return files;
  }

  Future<File> _createRecordingFile({required String suffix}) async {
    if (!await _recordingsDir.exists()) {
      await _recordingsDir.create(recursive: true);
    }
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final path = p.join(_recordingsDir.path, 'meeting-$timestamp-$suffix.wav');
    return File(path);
  }

  List<int> _encodeWav(
    Uint8List pcmBytes, {
    required int sampleRate,
    required int channels,
    required int bitsPerSample,
  }) {
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final blockAlign = channels * (bitsPerSample ~/ 8);
    final dataSize = pcmBytes.length;
    final fileSize = 44 - 8 + dataSize;

    final buffer = BytesBuilder();

    void writeString(String s) {
      buffer.add(s.codeUnits);
    }

    void writeInt32(int value) {
      final b = ByteData(4)..setUint32(0, value, Endian.little);
      buffer.add(b.buffer.asUint8List());
    }

    void writeInt16(int value) {
      final b = ByteData(2)..setUint16(0, value, Endian.little);
      buffer.add(b.buffer.asUint8List());
    }

    // RIFF header
    writeString('RIFF');
    writeInt32(fileSize);
    writeString('WAVE');

    // fmt chunk
    writeString('fmt ');
    writeInt32(16); // PCM chunk size
    writeInt16(1); // Audio format: PCM
    writeInt16(channels);
    writeInt32(sampleRate);
    writeInt32(byteRate);
    writeInt16(blockAlign);
    writeInt16(bitsPerSample);

    // data chunk
    writeString('data');
    writeInt32(dataSize);
    buffer.add(pcmBytes);

    return buffer.toBytes();
  }

  void _emitAudioLevel(Uint8List pcmChunk) {
    if (pcmChunk.length < 2) return;
    final bd = ByteData.sublistView(pcmChunk);
    double sumOfSquares = 0.0;
    final sampleCount = pcmChunk.length ~/ 2;
    for (int i = 0; i < sampleCount; i++) {
      final sample = bd.getInt16(i * 2, Endian.little).toDouble();
      sumOfSquares += sample * sample;
    }
    final rms = math.sqrt(sumOfSquares / sampleCount);
    final normalized = (rms / 32767.0).clamp(0.0, 1.0);
    if (!_audioLevelController.isClosed) {
      _audioLevelController.add(normalized);
    }
  }

  List<int> _mixToPcm16Mono({
    required Uint8List micPcm,
    required Uint8List sysPcm,
  }) {
    final micSampleCount = micPcm.length ~/ 2;
    final sysSampleCount = sysPcm.length ~/ 4; // stereo: 4 bytes per frame

    // Use mic count as reference; if no mic data, approximate from system audio
    final outputCount = micSampleCount > 0
        ? micSampleCount
        : (sysSampleCount * 16000 ~/ 44100);

    final output = BytesBuilder();

    for (int i = 0; i < outputCount; i++) {
      int micSample = 0;
      if (i < micSampleCount) {
        micSample = ByteData.sublistView(micPcm, i * 2, i * 2 + 2)
            .getInt16(0, Endian.little);
      }

      // Downsample system audio from 44100Hz stereo to 16000Hz mono
      int sysSample = 0;
      if (sysSampleCount > 0) {
        final sysFrameIndex = (i * 44100 / 16000).round();
        if (sysFrameIndex < sysSampleCount) {
          final offset = sysFrameIndex * 4;
          if (offset + 4 <= sysPcm.length) {
            final sysL = ByteData.sublistView(sysPcm, offset, offset + 2)
                .getInt16(0, Endian.little);
            final sysR = ByteData.sublistView(sysPcm, offset + 2, offset + 4)
                .getInt16(0, Endian.little);
            sysSample = ((sysL + sysR) / 2).round();
          }
        }
      }

      // Keep mic at full volume; reduce system to 50% so voice isn't drowned out
      final mixed =
          (micSample + (sysSample * 0.5).round()).clamp(-32768, 32767);
      final b = ByteData(2)..setInt16(0, mixed, Endian.little);
      output.add(b.buffer.asUint8List());
    }

    return output.toBytes();
  }
}

