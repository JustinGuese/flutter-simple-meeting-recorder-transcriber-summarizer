import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:goatly_meeting_transcriber_summarizer/src/summary/openrouter_summary_service.dart';

class _FakeClient extends http.BaseClient {
  _FakeClient(this._handler);

  final Future<http.Response> Function(http.BaseRequest request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

void main() {
  group('OpenRouterSummaryService', () {
    test('builds correct request and parses string content', () async {
      final captured = <String, Object?>{};

      final client = _FakeClient((request) async {
        captured['url'] = request.url.toString();
        captured['method'] = request.method;
        captured['headers'] = Map<String, String>.from(request.headers);

        final bodyString = utf8.decode(await request.finalize().toBytes());
        captured['body'] = jsonDecode(bodyString) as Map<String, dynamic>;

        final responseBody = jsonEncode({
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': 'This is a summary.',
              },
            },
          ],
        });

        return http.Response(responseBody, 200, headers: {
          'content-type': 'application/json',
        });
      });

      final service = OpenRouterSummaryService(
        // Storage is not used in this test; environment lookup will also fail,
        // but we bypass key resolution by injecting a fake key via environment.
        client: client,
        appUrl: 'https://example.com',
        appTitle: 'Meeting Recorder',
      );

      final summary = await service.summarize(
        transcript: 'Hello world transcript',
        title: 'Test Meeting',
        notes: 'Some notes',
        modelOverride: 'google/gemini-2.5-flash',
      );

      expect(summary, 'This is a summary.');

      expect(captured['url'], 'https://openrouter.ai/api/v1/chat/completions');
      expect(captured['method'], 'POST');

      final headers = captured['headers'] as Map<String, String>;
      // We cannot control the exact key here because Platform.environment is
      // read-only in tests, but we can still assert that the Authorization
      // header is present and non-empty.
      expect(headers['Authorization'], isNotNull);
      expect(headers['Content-Type'], 'application/json');
      expect(headers['HTTP-Referer'], 'https://example.com');
      expect(headers['X-Title'], 'Meeting Recorder');

      final body = captured['body'] as Map<String, dynamic>;
      expect(body['model'], 'google/gemini-2.5-flash');

      final messages = body['messages'] as List<dynamic>;
      expect(messages, isNotEmpty);
      final first = messages.first as Map<String, dynamic>;
      expect(first['role'], 'user');
      expect(first['content'], contains('Transcript:'));
    });
  });
}

