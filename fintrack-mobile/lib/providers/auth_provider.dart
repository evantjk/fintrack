import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Holds transient auth UI state (the "busy" spinner flag) and forwards
/// email/password actions to [AuthService].
///
/// The actual signed-in / signed-out routing is driven by the
/// `authStateChanges()` stream in the app's auth gate, so this provider only
/// tracks whether a request is in flight.
class AuthProvider extends ChangeNotifier {
  final AuthService _service;

  AuthProvider([AuthService? service]) : _service = service ?? AuthService();

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  // True while a new account is being created. createUser() momentarily signs
  // the user in before we sign them back out, so the auth gate watches this to
  // avoid flashing the home screen during sign-up.
  bool _registering = false;
  bool get registering => _registering;

  User? get currentUser => _service.currentUser;

  // Runs an auth action while showing the busy spinner, then clears it.
  Future<void> _run(Future<void> Function() action) async {
    _isBusy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Each method rethrows [AuthException] so the screen can show the message.
  // Log in with email and password.
  Future<void> signIn(String email, String password) =>
      _run(() => _service.signIn(email: email, password: password));

  // Create a new account with email and password.
  Future<void> signUp(String email, String password) async {
    _registering = true;
    notifyListeners();
    try {
      await _run(() => _service.signUp(email: email, password: password));
    } finally {
      _registering = false;
      notifyListeners();
    }
  }

  /// Returns `false` if the user dismissed the Google sheet.
  // Log in using a Google account.
  Future<bool> signInWithGoogle() async {
    var dismissed = false;
    await _run(() async => dismissed = !await _service.signInWithGoogle());
    return !dismissed;
  }

  // Send a password-reset email.
  Future<void> sendPasswordReset(String email) =>
      _run(() => _service.sendPasswordReset(email));

  // Log out.
  Future<void> signOut() => _service.signOut();
}
