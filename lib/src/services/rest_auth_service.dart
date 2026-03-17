import 'dart:async';

import 'package:df_firebase_rest/df_firebase_rest.dart';

import 'auth_service.dart';

class _AppRestAuthUser implements AuthUser {
  final FirebaseRestUser _delegate;

  _AppRestAuthUser(this._delegate);

  @override
  String get uid => _delegate.uid;

  @override
  String? get email => _delegate.email;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) =>
      _delegate.getIdToken(forceRefresh: forceRefresh);
}

/// Firebase Auth via REST API — works on all platforms including Windows/Linux.
/// This implementation delegates to the generic [firebase_rest] package.
class RestAuthService implements AuthService {
  final FirebaseRestAuth _delegate;
  final _controller = StreamController<AuthUser?>.broadcast();
  StreamSubscription<FirebaseRestUser?>? _sub;

  RestAuthService({required String apiKey})
      : _delegate = FirebaseRestAuth(apiKey: apiKey) {
    _sub = _delegate.authStateChanges.listen((user) {
      if (user != null) {
        _controller.add(_AppRestAuthUser(user));
      } else {
        _controller.add(null);
      }
    });
  }

  void dispose() {
    _sub?.cancel();
    _delegate.dispose();
    _controller.close();
  }

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser {
    final user = _delegate.currentUser;
    return user != null ? _AppRestAuthUser(user) : null;
  }

  @override
  Future<AuthUser> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final user =
          await _delegate.signInWithEmailAndPassword(email, password);
      return _AppRestAuthUser(user);
    } on FirebaseRestAuthException catch (e) {
      throw AuthException(e.code);
    }
  }

  @override
  Future<AuthUser> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final user =
          await _delegate.createUserWithEmailAndPassword(email, password);
      return _AppRestAuthUser(user);
    } on FirebaseRestAuthException catch (e) {
      throw AuthException(e.code);
    }
  }

  @override
  Future<void> signOut() => _delegate.signOut();
}
