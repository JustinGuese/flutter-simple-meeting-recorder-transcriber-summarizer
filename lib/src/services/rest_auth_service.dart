import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

const _identityToolkitBase =
    'https://identitytoolkit.googleapis.com/v1/accounts';
const _secureTokenBase = 'https://securetoken.googleapis.com/v1/token';

class _RestAuthUser implements AuthUser {
  @override
  final String uid;

  @override
  final String? email;

  String _idToken;
  final String _refreshToken;
  DateTime _tokenExpiry;
  final String _apiKey;

  _RestAuthUser({
    required this.uid,
    required this.email,
    required String idToken,
    required String refreshToken,
    required DateTime tokenExpiry,
    required String apiKey,
  })  : _idToken = idToken,
        _refreshToken = refreshToken,
        _tokenExpiry = tokenExpiry,
        _apiKey = apiKey;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final expiresSoon =
        DateTime.now().isAfter(_tokenExpiry.subtract(const Duration(minutes: 5)));
    if (forceRefresh || expiresSoon) {
      await _refresh();
    }
    return _idToken;
  }

  Future<void> _refresh() async {
    final resp = await http.post(
      Uri.parse('$_secureTokenBase?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'grant_type': 'refresh_token', 'refresh_token': _refreshToken}),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      _idToken = data['id_token'] as String;
      _tokenExpiry = DateTime.now().add(
          Duration(seconds: int.parse(data['expires_in'] as String)));
    }
  }
}

/// Firebase Auth via REST API — works on all platforms including Windows/Linux.
class RestAuthService implements AuthService {
  final String _apiKey;
  final FlutterSecureStorage _storage;
  final _controller = StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? currentUser;

  static const _kUid = 'rest_uid';
  static const _kEmail = 'rest_email';
  static const _kIdToken = 'rest_id_token';
  static const _kRefreshToken = 'rest_refresh_token';
  static const _kExpiry = 'rest_expiry';

  RestAuthService({required String apiKey})
      : _apiKey = apiKey,
        _storage = const FlutterSecureStorage() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final uid = await _storage.read(key: _kUid);
    final email = await _storage.read(key: _kEmail);
    final idToken = await _storage.read(key: _kIdToken);
    final refreshToken = await _storage.read(key: _kRefreshToken);
    final expiryStr = await _storage.read(key: _kExpiry);

    if (uid != null && idToken != null && refreshToken != null) {
      currentUser = _RestAuthUser(
        uid: uid,
        email: email,
        idToken: idToken,
        refreshToken: refreshToken,
        tokenExpiry: expiryStr != null
            ? DateTime.tryParse(expiryStr) ?? DateTime.now()
            : DateTime.now(),
        apiKey: _apiKey,
      );
      _controller.add(currentUser);
    } else {
      _controller.add(null);
    }
  }

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  Future<AuthUser> signInWithEmailAndPassword(
      String email, String password) async {
    final resp = await http.post(
      Uri.parse('$_identityToolkitBase:signInWithPassword?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'email': email, 'password': password, 'returnSecureToken': true}),
    );
    _checkError(resp);
    return _storeAndEmit(
        jsonDecode(resp.body) as Map<String, dynamic>, email);
  }

  @override
  Future<AuthUser> createUserWithEmailAndPassword(
      String email, String password) async {
    final resp = await http.post(
      Uri.parse('$_identityToolkitBase:signUp?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'email': email, 'password': password, 'returnSecureToken': true}),
    );
    _checkError(resp);
    return _storeAndEmit(
        jsonDecode(resp.body) as Map<String, dynamic>, email);
  }

  void _checkError(http.Response resp) {
    if (resp.statusCode != 200) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final message =
          (body['error'] as Map<String, dynamic>?)?['message'] as String? ??
              'UNKNOWN_ERROR';
      // Strip detail suffix e.g. "WEAK_PASSWORD : ..."
      final code = message.split(' :').first.trim();
      throw AuthException(code);
    }
  }

  Future<AuthUser> _storeAndEmit(
      Map<String, dynamic> data, String email) async {
    final uid = data['localId'] as String;
    final idToken = data['idToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    final expiresIn = int.parse(data['expiresIn'] as String);
    final expiry = DateTime.now().add(Duration(seconds: expiresIn));

    await _storage.write(key: _kUid, value: uid);
    await _storage.write(key: _kEmail, value: email);
    await _storage.write(key: _kIdToken, value: idToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
    await _storage.write(key: _kExpiry, value: expiry.toIso8601String());

    currentUser = _RestAuthUser(
      uid: uid,
      email: email,
      idToken: idToken,
      refreshToken: refreshToken,
      tokenExpiry: expiry,
      apiKey: _apiKey,
    );
    _controller.add(currentUser);
    return currentUser!;
  }

  @override
  Future<void> signOut() async {
    await _storage.deleteAll();
    currentUser = null;
    _controller.add(null);
  }
}
