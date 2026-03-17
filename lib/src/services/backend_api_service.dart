import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:df_device_id/df_device_id.dart';

const _defaultBaseUrl = 'https://meetingrecorderbackend-api.datafortress.cloud';

class FreeTierLimitException implements Exception {
  final int meetingsUsed;
  final int minutesUsed;
  final String reason;

  FreeTierLimitException({
    required this.meetingsUsed,
    required this.minutesUsed,
    required this.reason,
  });

  @override
  String toString() => 'FreeTierLimitException: $reason limit reached.';
}

class BackendApiException implements Exception {
  final int statusCode;
  final String message;

  BackendApiException(this.statusCode, this.message);

  @override
  String toString() => 'BackendApiException($statusCode): $message';
}

class BackendApiService {
  final DeviceIdService _deviceIdService;
  final http.Client _client;
  final String _baseUrl;

  String? _firebaseIdToken;

  BackendApiService({
    required DeviceIdService deviceIdService,
    http.Client? client,
    String? baseUrl,
  })  : _deviceIdService = deviceIdService,
        _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? _defaultBaseUrl;

  void setFirebaseIdToken(String? token) {
    _firebaseIdToken = token;
  }

  Future<Map<String, String>> _headers() async {
    final deviceId = await _deviceIdService.getDeviceId();
    final headers = <String, String>{
      'X-Device-ID': deviceId,
    };
    if (_firebaseIdToken != null) {
      headers['Authorization'] = 'Bearer $_firebaseIdToken';
    }
    return headers;
  }

  Future<Map<String, dynamic>> getUsage() async {
    final resp = await _client.get(
      Uri.parse('$_baseUrl/api/v1/usage'),
      headers: await _headers(),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw BackendApiException(resp.statusCode, resp.body);
  }

  Future<Map<String, dynamic>> transcribe(
    Uint8List audioBytes, {
    required String filename,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v1/transcribe');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await _headers());
    final subtype = filename.toLowerCase().endsWith('.wav') ? 'wav' : 'mpeg';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      audioBytes,
      filename: filename,
      contentType: MediaType('audio', subtype),
    ));

    final streamed = await _client.send(request);
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    if (resp.statusCode == 402) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final detail = body['detail'] as Map<String, dynamic>? ?? {};
      throw FreeTierLimitException(
        meetingsUsed: (detail['meetings_used'] as int?) ?? 0,
        minutesUsed: (detail['minutes_used'] as int?) ?? 0,
        reason: (detail['reason'] as String?) ?? 'meetings',
      );
    }
    throw BackendApiException(resp.statusCode, resp.body);
  }

  Future<Map<String, dynamic>> summarize({
    required String transcript,
    String? title,
    String? notes,
  }) async {
    final resp = await _client.post(
      Uri.parse('$_baseUrl/api/v1/summarize'),
      headers: {
        ...await _headers(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'transcript': transcript,
        if (title != null) 'title': title,
        if (notes != null) 'notes': notes,
      }),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw BackendApiException(resp.statusCode, resp.body);
  }

  Future<void> linkDevice({required String firebaseIdToken}) async {
    final headers = await _headers();
    headers['Authorization'] = 'Bearer $firebaseIdToken';
    headers['Content-Type'] = 'application/json';
    final resp = await _client.post(
      Uri.parse('$_baseUrl/api/v1/auth/link-device'),
      headers: headers,
      body: '{}',
    );
    if (resp.statusCode != 200) {
      throw BackendApiException(resp.statusCode, resp.body);
    }
  }

  /// Resets all usage counters for this device. Debug/dev only.
  Future<void> debugResetUsage() async {
    final resp = await _client.post(
      Uri.parse('$_baseUrl/api/v1/debug/reset-usage'),
      headers: await _headers(),
    );
    if (resp.statusCode != 200) {
      throw BackendApiException(resp.statusCode, resp.body);
    }
  }

  /// Returns the Stripe Checkout Session URL for the given [tier] ('m' or 'pro').
  /// Requires a Firebase ID token to be set via [setFirebaseIdToken].
  Future<String> createCheckoutSession(String tier) async {
    final resp = await _client.post(
      Uri.parse('$_baseUrl/api/v1/checkout/session?tier=$tier'),
      headers: {
        ...await _headers(),
        'Content-Type': 'application/json',
      },
      body: '{}',
    );
    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      return body['url'] as String;
    }
    throw BackendApiException(resp.statusCode, resp.body);
  }
}
