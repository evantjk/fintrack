import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_scaffold.dart';
import 'login_screen.dart';

/// Sends a Firebase password-reset email to the entered address.
// The page where a user asks for a password-reset email.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  // Checks the email, sends the reset link, then shows the "sent" message.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  // Builds the "reset password" form with a single email field.
  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().isBusy;

    return AuthScaffold(
      title: 'RESET PASSWORD',
      subtitle: _sent
          ? 'Check your inbox for a link to reset your password.'
          : "Enter your email and we'll send you a reset link.",
      footer: TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Back to login'),
      ),
      children: [
        if (_sent)
          Column(
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 48),
              const SizedBox(height: 16),
              AuthButton(
                label: 'BACK TO LOGIN',
                busy: false,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          )
        else
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
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: validateEmail,
                ),
                const SizedBox(height: 20),
                AuthButton(
                    label: 'SEND RESET LINK', busy: busy, onPressed: _submit),
              ],
            ),
          ),
      ],
    );
  }
}
