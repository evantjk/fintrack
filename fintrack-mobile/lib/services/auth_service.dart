import 'package:firebase_auth/firebase_auth.dart';

/// Thrown by [AuthService] with a human-friendly [message] ready to show in the
/// UI (e.g. in a SnackBar). The original FirebaseAuth error code is kept in
/// [code] for debugging.
class AuthException implements Exception {
  final String message;
  final String? code;
  const AuthException(this.message, [this.code]);

  @override
  String toString() => message;
}

/// Thin wrapper around [FirebaseAuth] for email/password authentication.
///
/// Keeps all Firebase calls in one place and translates raw
/// [FirebaseAuthException] codes into readable messages.
class AuthService {
  final FirebaseAuth? _injected;

  AuthService([FirebaseAuth? auth]) : _injected = auth;

  // Resolved lazily so simply constructing the service (e.g. building the
  // provider tree in a widget test) doesn't require Firebase to be initialised.
  FirebaseAuth get _auth => _injected ?? FirebaseAuth.instance;

  /// Emits the signed-in user, or `null` when signed out. The app's auth gate
  /// listens to this to decide between the login flow and the home screen.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e), e.code);
    }
  }

  /// Creates the account, then immediately signs out so the user lands back on
  /// the login screen and signs in deliberately (Firebase otherwise signs a new
  /// user in automatically).
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e), e.code);
    }
  }

  /// Google sign-in via Firebase's native OAuth flow (a Chrome Custom Tab on
  /// Android), so it works with the existing Firebase config without bundling
  /// a `google-services.json` or the `google_sign_in` package.
  ///
  /// Returns `false` if the user dismissed the Google sheet, `true` on success.
  Future<bool> signInWithGoogle() async {
    try {
      await _auth.signInWithProvider(GoogleAuthProvider());
      return true;
    } on FirebaseAuthException catch (e) {
      // The user backing out of the OAuth flow isn't an error worth surfacing.
      if (e.code.toLowerCase().contains('cancel')) return false;
      throw AuthException(_messageFor(e), e.code);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e), e.code);
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Maps FirebaseAuth error codes to messages a user can act on.
  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password is too weak (use at least 6 characters).';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled for this project.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'internal-error':
        // Seen for Google sign-in on Android when no Android app (with a SHA-1
        // fingerprint) is registered in Firebase — the message carries
        // INVALID_APP_ID.
        if ((e.message ?? '').contains('INVALID_APP_ID')) {
          return 'Google sign-in isn\'t configured for Android yet. '
              'Register the Android app + SHA-1 in Firebase.';
        }
        return 'Something went wrong. Please try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
