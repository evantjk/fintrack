import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/add_edit_transaction_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import 'app_routes.dart';

/// Builds the route for a given name. Wired into `MaterialApp.onGenerateRoute`
/// so every `Navigator.pushNamed(...)` in the app is resolved here.
///
/// This is the `onGenerateRoute` approach from the Navigation & Routing lecture
/// (the recommended one): a single switch maps a route name to the screen to
/// show, reads any `arguments`, and forwards them to that screen's constructor.
class AppRouter {
  AppRouter._();

  // Picks the screen to show based on the route name.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return _build(const LoginScreen(), settings);

      case AppRoutes.signup:
        return _build(const SignUpScreen(), settings);

      case AppRoutes.forgotPassword:
        return _build(const ForgotPasswordScreen(), settings);

      case AppRoutes.home:
        return _build(const HomeScreen(), settings);

      case AppRoutes.transactionForm:
        // Bundled arguments (see TransactionArgs). Null when the screen is
        // opened with no arguments (a fresh "add" with no pre-selected type).
        final args = settings.arguments as TransactionArgs?;
        return _build(
          AddEditTransactionScreen(
            transaction: args?.transaction,
            initialType: args?.initialType,
          ),
          settings,
        );

      default:
        // A name we don't recognise — fail loudly rather than silently.
        return _build(
          Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
          settings,
        );
    }
  }

  /// Wraps a screen in a [MaterialPageRoute], preserving [settings] so the
  /// route keeps its name and arguments.
  static MaterialPageRoute<dynamic> _build(
          Widget screen, RouteSettings settings) =>
      MaterialPageRoute<dynamic>(builder: (_) => screen, settings: settings);
}
