abstract class AuthUser {
  String get uid;
  String? get email;
  Future<String?> getIdToken({bool forceRefresh = false});
}

abstract class AuthService {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;
  Future<AuthUser> signInWithEmailAndPassword(String email, String password);
  Future<AuthUser> createUserWithEmailAndPassword(String email, String password);
  Future<void> signOut();
}

class AuthException implements Exception {
  final String code;

  AuthException(this.code);

  String get userMessage {
    switch (code) {
      case 'EMAIL_NOT_FOUND':
      case 'INVALID_LOGIN_CREDENTIALS':
      case 'INVALID_EMAIL':
        return 'Invalid email or password.';
      case 'INVALID_PASSWORD':
        return 'Incorrect password.';
      case 'USER_DISABLED':
        return 'This account has been disabled.';
      case 'EMAIL_EXISTS':
        return 'An account already exists with this email.';
      case 'WEAK_PASSWORD':
        return 'Password must be at least 6 characters.';
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
        return 'Too many attempts. Please try again later.';
      case 'NETWORK_REQUEST_FAILED':
        return 'Network error. Check your connection.';
      default:
        return code;
    }
  }

  @override
  String toString() => 'AuthException: $code';
}
