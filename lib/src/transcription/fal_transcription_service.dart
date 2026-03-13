import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:fal_client/fal_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';
import 'transcription_service.dart';
import '../platform/env.dart';

class FalMissingKeyException implements Exception {
  FalMissingKeyException();

  @override
  String toString() =>
      'FalMissingKeyException: FAL_KEY is not configured. Set it as an '
      'environment variable or via the in-app settings.';
}

class FalTranscriptionService implements TranscriptionService {
  FalTranscriptionService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<FalClient> _getClient() async {
    final overrideKey = await _storage.read(key: 'fal_key');
    final envKey = readEnv('FAL_KEY');
    final key = overrideKey?.trim().isNotEmpty == true
        ? overrideKey
        : envKey?.trim().isNotEmpty == true
            ? envKey
            : null;

    if (key == null) {
      throw FalMissingKeyException();
    }

    return FalClient.withCredentials(key);
  }

  /// Uploads a local audio file and performs a blocking transcription using
  /// fal.subscribe on fal-ai/wizper.
  @override
  Future<TranscriptionResult> transcribeBlocking(XFile audioFile) async {
    final client = await _getClient();

    final audioUrl = await client.storage.upload(audioFile);

    final output = await client.subscribe(
      'fal-ai/wizper',
      input: <String, dynamic>{
        'audio_url': audioUrl,
        'task': 'transcribe',
        'language': null,
        'chunk_level': 'segment',
        'max_segment_len': 29,
        'merge_chunks': true,
        'version': '3',
      },
      logs: true,
    );

    final data = output.data;
    return TranscriptionResult.fromMap(data);
  }

  Future<void> saveOverrideKey(String key) async {
    await _storage.write(key: 'fal_key', value: key.trim());
  }

  Future<String?> loadCurrentKeySource() async {
    final override = await _storage.read(key: 'fal_key');
    if (override != null && override.trim().isNotEmpty) {
      return 'secure_storage';
    }
    final envKey = readEnv('FAL_KEY');
    if (envKey != null && envKey.trim().isNotEmpty) {
      return 'environment';
    }
    return null;
  }
}

