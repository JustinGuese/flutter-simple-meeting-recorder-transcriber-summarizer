import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../platform/env.dart';
import 'summary_service.dart';
class MeetingSummaryResult {
  const MeetingSummaryResult({required this.title, required this.summary});

  final String title;
  final String summary;
}

class OpenRouterMissingKeyException implements Exception {
  OpenRouterMissingKeyException();

  @override
  String toString() =>
      'OpenRouterMissingKeyException: OPENROUTER_API_KEY is not configured. '
      'Set it as an environment variable or via the in-app settings.';
}

class OpenRouterApiException implements Exception {
  OpenRouterApiException(this.message);

  final String message;

  @override
  String toString() => 'OpenRouterApiException: $message';
}

class OpenRouterSummaryService implements SummaryService {
  OpenRouterSummaryService({
    FlutterSecureStorage? storage,
    http.Client? client,
    String? appUrl,
    String? appTitle,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client(),
        _appUrl = appUrl,
        _appTitle = appTitle;

  final FlutterSecureStorage _storage;
  final http.Client _client;
  final String? _appUrl;
  final String? _appTitle;

  static const _storageKey = 'openrouter_key';
  static const _defaultModel = 'google/gemini-2.5-flash';

  Future<String> _getApiKey() async {
    final overrideKey = await _storage.read(key: _storageKey);
    final envKey = readEnv('OPENROUTER_API_KEY');
    final key = overrideKey?.trim().isNotEmpty == true
        ? overrideKey
        : envKey?.trim().isNotEmpty == true
            ? envKey
            : null;

    if (key == null) {
      throw OpenRouterMissingKeyException();
    }

    return key;
  }

  @override
  Future<MeetingSummaryResult> summarizeWithTitle({
    required String transcript,
    String? title,
    String? notes,
    String? modelOverride,
  }) async {
    if (transcript.trim().isEmpty) {
      throw ArgumentError.value(
        transcript,
        'transcript',
        'Transcript must not be empty',
      );
    }

    final apiKey = await _getApiKey();
    final model =
        modelOverride?.trim().isNotEmpty == true ? modelOverride!.trim() : _defaultModel;

    final userBuffer = StringBuffer();
    if (title != null && title.trim().isNotEmpty) {
      userBuffer.writeln('Current title: ${title.trim()}');
      userBuffer.writeln();
    }
    if (notes != null && notes.trim().isNotEmpty) {
      userBuffer.writeln('Notes:');
      userBuffer.writeln(notes.trim());
      userBuffer.writeln();
    }
    userBuffer.writeln('Transcript:');
    userBuffer.writeln(transcript.trim());

    final uri = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

    final headers = <String, String>{
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    if (_appUrl != null && _appUrl.trim().isNotEmpty) {
      headers['HTTP-Referer'] = _appUrl.trim();
    }
    if (_appTitle != null && _appTitle.trim().isNotEmpty) {
      headers['X-Title'] = _appTitle.trim();
    }

    final body = jsonEncode({
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content':
              'You help users by summarizing meeting transcripts and naming the meeting. '
                  'Return ONLY valid JSON with exactly these keys: "title" and "summary". '
                  '"title" must be 2-6 words, no quotes, no emojis, no date/time. '
                  '"summary" must be clear and neutral: one short overview paragraph, then bullet points for key topics, decisions, and action items. '
                  'Do not wrap JSON in markdown fences.',
        },
        {
          'role': 'user',
          'content': userBuffer.toString(),
        },
      ],
    });

    final response = await _client.post(uri, headers: headers, body: body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpenRouterApiException(
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw OpenRouterApiException('No choices in OpenRouter response');
    }

    final first = choices.first as Map<String, dynamic>;
    final message = first['message'] as Map<String, dynamic>?;
    if (message == null) {
      throw OpenRouterApiException('Missing message in OpenRouter response');
    }

    final content = message['content'];
    final rawText = _contentToText(content);

    // Preferred: strict JSON result.
    try {
      final obj = jsonDecode(rawText) as Map<String, dynamic>;
      final generatedTitle = (obj['title'] as String?)?.trim() ?? '';
      final summaryText = (obj['summary'] as String?)?.trim() ?? '';
      if (generatedTitle.isNotEmpty && summaryText.isNotEmpty) {
        return MeetingSummaryResult(title: generatedTitle, summary: summaryText);
      }
    } catch (_) {
      // Fall through to robust fallback below.
    }

    // Fallback: keep summary and generate title with a small second call.
    final summaryText = await summarize(
      transcript: transcript,
      title: title,
      notes: notes,
      modelOverride: modelOverride,
    );
    final generatedTitle = await generateTitle(
      transcript: transcript,
      title: title,
      notes: notes,
      modelOverride: modelOverride,
    );
    return MeetingSummaryResult(title: generatedTitle, summary: summaryText);
  }

  Future<String> generateTitle({
    required String transcript,
    String? title,
    String? notes,
    String? modelOverride,
  }) async {
    if (transcript.trim().isEmpty) {
      throw ArgumentError.value(
        transcript,
        'transcript',
        'Transcript must not be empty',
      );
    }

    final apiKey = await _getApiKey();
    final model =
        modelOverride?.trim().isNotEmpty == true ? modelOverride!.trim() : _defaultModel;

    final userBuffer = StringBuffer();
    if (title != null && title.trim().isNotEmpty) {
      userBuffer.writeln('Current title: ${title.trim()}');
      userBuffer.writeln();
    }
    if (notes != null && notes.trim().isNotEmpty) {
      userBuffer.writeln('Notes:');
      userBuffer.writeln(notes.trim());
      userBuffer.writeln();
    }
    userBuffer.writeln('Transcript:');
    userBuffer.writeln(transcript.trim());

    final uri = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

    final headers = <String, String>{
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    if (_appUrl != null && _appUrl.trim().isNotEmpty) {
      headers['HTTP-Referer'] = _appUrl.trim();
    }
    if (_appTitle != null && _appTitle.trim().isNotEmpty) {
      headers['X-Title'] = _appTitle.trim();
    }

    final body = jsonEncode({
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content':
              'Create a short meeting title from the transcript. '
                  'Return ONLY the title text (2-6 words). '
                  'No quotes, no emojis, no punctuation at the end, no date/time.',
        },
        {
          'role': 'user',
          'content': userBuffer.toString(),
        },
      ],
    });

    final response = await _client.post(uri, headers: headers, body: body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpenRouterApiException(
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw OpenRouterApiException('No choices in OpenRouter response');
    }

    final first = choices.first as Map<String, dynamic>;
    final message = first['message'] as Map<String, dynamic>?;
    if (message == null) {
      throw OpenRouterApiException('Missing message in OpenRouter response');
    }

    final content = message['content'];
    final generated = _contentToText(content).trim();
    if (generated.isEmpty) {
      throw OpenRouterApiException('Empty content in OpenRouter response');
    }
    return generated;
  }

  Future<String> summarize({
    required String transcript,
    String? title,
    String? notes,
    String? modelOverride,
  }) async {
    if (transcript.trim().isEmpty) {
      throw ArgumentError.value(
        transcript,
        'transcript',
        'Transcript must not be empty',
      );
    }

    final apiKey = await _getApiKey();
    final model =
        modelOverride?.trim().isNotEmpty == true ? modelOverride!.trim() : _defaultModel;

    final userBuffer = StringBuffer();
    if (title != null && title.trim().isNotEmpty) {
      userBuffer.writeln('Title: ${title.trim()}');
      userBuffer.writeln();
    }
    if (notes != null && notes.trim().isNotEmpty) {
      userBuffer.writeln('Notes:');
      userBuffer.writeln(notes.trim());
      userBuffer.writeln();
    }
    userBuffer.writeln('Transcript:');
    userBuffer.writeln(transcript.trim());

    final uri = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

    final headers = <String, String>{
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    if (_appUrl != null && _appUrl.trim().isNotEmpty) {
      headers['HTTP-Referer'] = _appUrl.trim();
    }
    if (_appTitle != null && _appTitle.trim().isNotEmpty) {
      headers['X-Title'] = _appTitle.trim();
    }

    final body = jsonEncode({
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content':
              'You summarize meeting transcripts for busy humans. Write directly to the user in a clear, neutral tone. '
                  'Always produce the best possible summary from the given text, even if it is short or incomplete. '
                  'Do not mention missing context, transcript length, or your own limitations. '
                  'Return a short overview paragraph, then bullet points for key topics, decisions, and action items.',
        },
        {
          'role': 'user',
          'content': userBuffer.toString(),
        },
      ],
    });

    final response = await _client.post(uri, headers: headers, body: body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpenRouterApiException(
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw OpenRouterApiException('No choices in OpenRouter response');
    }

    final first = choices.first as Map<String, dynamic>;
    final message = first['message'] as Map<String, dynamic>?;
    if (message == null) {
      throw OpenRouterApiException('Missing message in OpenRouter response');
    }

    final content = message['content'];
    final text = _contentToText(content).trim();
    if (text.isEmpty) {
      throw OpenRouterApiException('Empty content in OpenRouter response');
    }
    return text;
  }

  String _contentToText(dynamic content) {
    if (content is String) {
      return content;
    }

    if (content is List) {
      final buffer = StringBuffer();
      for (final part in content) {
        if (part is Map<String, dynamic>) {
          if (part['type'] == 'text' && part['text'] is String) {
            buffer.writeln((part['text'] as String).trim());
          }
        }
      }
      final text = buffer.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }

    throw OpenRouterApiException('Unsupported content format in OpenRouter response');
  }

  Future<void> saveOverrideKey(String key) async {
    await _storage.write(key: _storageKey, value: key.trim());
  }

  Future<String?> loadCurrentKeySource() async {
    final override = await _storage.read(key: _storageKey);
    if (override != null && override.trim().isNotEmpty) {
      return 'secure_storage';
    }
    final envKey = readEnv('OPENROUTER_API_KEY');
    if (envKey != null && envKey.trim().isNotEmpty) {
      return 'environment';
    }
    return null;
  }
}

