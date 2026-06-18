import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_scaffold.dart';
import 'login_screen.dart';

/// Create a new account with email + password (with confirmation).
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await auth.signUp(_email.text, _password.text);
      if (!mounted) return;
      // The account is created and signed out again — return to login so the
      // user signs in deliberately, and confirm success.
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Account created! Please log in.')),
      );
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _google() async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      // On success the auth gate switches to the home screen automatically.
      await auth.signInWithGoogle();
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    final busy = context.watch<AuthProvider>().isBusy;

    return AuthScaffold(
      title: 'CREATE ACCOUNT',
      subtitle: 'Join FinTrack to start tracking your income and expenses.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Already have an account?'),
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text('Log in'),
          ),
        ],
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                controller: _email,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
              ),
              const SizedBox(height: 16),
              AuthField(
                controller: _password,
                label: 'Password',
                icon: Icons.lock_outline,
                obscure: _obscure,
                validator: (v) => (v == null || v.length < 6)
                    ? 'Use at least 6 characters'
                    : null,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: p.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 16),
              AuthField(
                controller: _confirm,
                label: 'Confirm password',
                icon: Icons.lock_outline,
                obscure: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) =>
                    v != _password.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 20),
              AuthButton(label: 'SIGN UP', busy: busy, onPressed: _submit),
              const SizedBox(height: 18),
              const OrDivider(),
              const SizedBox(height: 18),
              GoogleButton(busy: busy, onPressed: _google),
            ],
          ),
        ),
      ],
    );
  }
}
