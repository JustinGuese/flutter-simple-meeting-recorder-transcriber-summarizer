import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';

import '../services/backend_api_service.dart';
import '../services/usage_service.dart';
import 'models.dart';
import 'transcription_service.dart';

class ManagedTranscriptionService implements TranscriptionService {
  final BackendApiService _backendApi;
  final UsageService _usageService;

  ManagedTranscriptionService({
    required BackendApiService backendApi,
    required UsageService usageService,
  })  : _backendApi = backendApi,
        _usageService = usageService;

  @override
  Future<TranscriptionResult> transcribeBlocking(XFile audioFile) async {
    Uint8List audioBytes;
    if (kIsWeb) {
      audioBytes = await audioFile.readAsBytes();
    } else {
      audioBytes = await File(audioFile.path).readAsBytes();
    }

    final result = await _backendApi.transcribe(
      audioBytes,
      filename: audioFile.name.isNotEmpty ? audioFile.name : 'audio.m4a',
    );

    // Invalidate usage cache after a successful transcription
    _usageService.invalidate();

    return TranscriptionResult.fromMap(result);
  }
}
