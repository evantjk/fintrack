import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_scaffold.dart';
import '../../routes/app_routes.dart';

/// Email / password sign-in. The auth gate swaps to the home screen
/// automatically once Firebase reports a signed-in user.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.signIn(_email.text, _password.text);
      // Success: the auth gate navigates away — nothing else to do here.
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
      title: 'FINTRACK',
      subtitle: 'Welcome back. Sign in to keep tracking your money.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Don't have an account?"),
          TextButton(
            onPressed: busy
                ? null
                : () => Navigator.pushNamed(context, AppRoutes.signup),
            child: const Text('Sign up'),
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
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Enter your password'
                    : null,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: p.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: busy
                      ? null
                      : () => Navigator.pushNamed(
                          context, AppRoutes.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),
              AuthButton(label: 'LOG IN', busy: busy, onPressed: _submit),
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

/// Shared email validator used across the auth screens.
String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Enter your email';
  final re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  if (!re.hasMatch(v)) return 'Enter a valid email address';
  return null;
}
