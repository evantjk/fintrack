import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'mascots.dart';

/// Shared layout for the login / sign-up / forgot-password screens.
///
/// Draws the themed gradient header with the app mascot, then a surface card
/// holding the form [children]. Reads [PixelColors] tokens so it renders
/// correctly under every theme (soft Material, chunky pixel, or serif Luxury).
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Shown under the card, e.g. a "Sign up" / "Back to login" link.
  final Widget? footer;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    final bool pixel = p.hardShadow;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.gradientStart, p.gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ThemeMascot(size: 64, outline: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: pixel ? 16 : 26,
                        fontWeight: pixel ? null : FontWeight.bold,
                        fontFamily: p.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: pixel ? 9 : 14,
                        height: 1.5,
                        fontFamily: p.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: p.br,
                        border: p.box(),
                        boxShadow: pixel
                            ? [
                                BoxShadow(
                                    color: p.outline,
                                    offset: const Offset(4, 4)),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: children,
                      ),
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 20),
                      DefaultTextStyle.merge(
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontFamily: p.fontFamily,
                        ),
                        child: footer!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled text field styled from the active theme's input decoration.
// A styled text field used on the auth screens.
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.suffix,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: p.textMuted),
        suffixIcon: suffix,
      ),
    );
  }
}

/// A horizontal "or" separator used between the email form and Google sign-in.
// The "OR" line shown between login options.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    final line = Expanded(child: Divider(color: p.outline, thickness: 1));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(color: p.textMuted, fontFamily: p.fontFamily),
          ),
        ),
        line,
      ],
    );
  }
}

/// "Continue with Google" button following Google's brand guidance: a white
/// surface, the official multi-colour "G" mark, and medium-weight label.
/// Kept white across themes (only the corner radius follows the theme) so it
/// stays recognisably "Google".
// The "Sign in with Google" button.
class GoogleButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onPressed;

  const GoogleButton({super.key, required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: busy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF3C4043), // Google's text grey
          backgroundColor: Colors.white,
          side: BorderSide(
            color: p.hardShadow ? p.outline : const Color(0xFFDADCE0),
            width: p.borderWidth > 0 ? p.borderWidth : 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: p.br),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/google_logo.png', width: 22, height: 22),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: TextStyle(
                fontFamily: p.fontFamily,
                fontSize: p.hardShadow ? 10 : 15,
                fontWeight: p.hardShadow ? null : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width primary button that shows a spinner while [busy] is true.
///
/// Given a stronger presence (bold label + a coloured drop shadow that lifts it
/// off the card) so the main call-to-action clearly stands out instead of
/// blending into the blue background.
// The main action button (shows a spinner while busy).
class AuthButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  const AuthButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final pixel = p.hardShadow;
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
          elevation: pixel ? 0 : 6,
          shadowColor: pixel ? null : primary.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: p.br,
            side: pixel
                ? BorderSide(color: p.outline, width: p.borderWidth)
                : BorderSide.none,
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontFamily: p.fontFamily,
                  fontSize: pixel ? 11 : 16,
                  fontWeight: pixel ? null : FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
