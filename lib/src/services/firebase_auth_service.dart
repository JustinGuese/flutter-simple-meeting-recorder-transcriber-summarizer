import 'package:firebase_auth/firebase_auth.dart' as fa;

import 'auth_service.dart';

class _FaAuthUser implements AuthUser {
  final fa.User _user;
  _FaAuthUser(this._user);

  @override
  String get uid => _user.uid;

  @override
  String? get email => _user.email;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) =>
      _user.getIdToken(forceRefresh);
}

class FirebaseAuthService implements AuthService {
  @override
  Stream<AuthUser?> get authStateChanges =>
      fa.FirebaseAuth.instance.authStateChanges().map(
        (u) => u == null ? null : _FaAuthUser(u),
      );

  @override
  AuthUser? get currentUser {
    final u = fa.FirebaseAuth.instance.currentUser;
    return u == null ? null : _FaAuthUser(u);
  }

  @override
  Future<AuthUser> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred = await fa.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _FaAuthUser(cred.user!);
    } on fa.FirebaseAuthException catch (e) {
      throw AuthException(
          (e.code).toUpperCase().replaceAll('-', '_'));
    }
  }

  @override
  Future<AuthUser> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred =
          await fa.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _FaAuthUser(cred.user!);
    } on fa.FirebaseAuthException catch (e) {
      throw AuthException(
          (e.code).toUpperCase().replaceAll('-', '_'));
    }
  }

  @override
  Future<void> signOut() => fa.FirebaseAuth.instance.signOut();
}
