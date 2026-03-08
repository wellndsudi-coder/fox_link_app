import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double shadowOpacity;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.shadowOpacity = 0.06,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: shadowOpacity),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        borderRadius:
        BorderRadius.circular(AppTheme.borderRadius),
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}