import 'package:flutter/material.dart';

/// Cores para telas de auth (login, registro).
class AuthWelcomeColors {
  AuthWelcomeColors._();

  static const Color primary = Color(0xFFFF6A00);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE5E7EB);
  static const Color cardFill = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7F9FC);
}

/// Layout padrão para telas de auth com logo e footer.
class AuthWelcomeLayout extends StatelessWidget {
  final bool showLogo;
  final bool showFooter;
  final Widget child;

  const AuthWelcomeLayout({
    super.key,
    this.showLogo = true,
    this.showFooter = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthWelcomeColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showLogo) ...[
                    Icon(
                      Icons.pets,
                      size: 64,
                      color: AuthWelcomeColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'FoX LinK',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AuthWelcomeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  child,
                  if (showFooter)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Text(
                        'Agendamento inteligente',
                        style: TextStyle(
                          fontSize: 12,
                          color: AuthWelcomeColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão primário para auth.
class AuthWelcomePrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool showArrow;

  const AuthWelcomePrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthWelcomeColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label),
                  if (showArrow) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}
