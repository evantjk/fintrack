import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/auth_provider.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/transaction_provider.dart';
import '../home_screen.dart';
import 'login_screen.dart';

/// Decides the start screen based on Firebase auth state:
/// signed in → [HomeScreen], signed out → [LoginScreen]. Rebuilds reactively
/// whenever the user logs in or out.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // While a sign-up is in flight the user is briefly signed in (then signed
    // back out); stay on the login flow so the home screen never flashes.
    final registering = context.watch<AuthProvider>().registering;
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Also re-check the live currentUser so a just-signed-out user can't
        // slip through on a stale stream event.
        final user = FirebaseAuth.instance.currentUser;
        final signedIn = snapshot.hasData && user != null;
        final ready = signedIn && !registering;

        // Bind the transaction data to this user (or clear it on sign-out).
        // setUser() ignores repeat calls for the same uid, so running it after
        // every rebuild is cheap. Deferred to a post-frame callback so we don't
        // mutate the provider during build.
        final uid = ready ? user.uid : null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<TransactionProvider>().setUser(uid);
          context.read<CheckInProvider>().setUser(uid);
        });

        if (ready) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
