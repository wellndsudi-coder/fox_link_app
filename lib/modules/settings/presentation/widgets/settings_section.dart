import 'package:flutter/material.dart';

/// Cabeçalho de seção para telas de configuração.
class SettingsSection extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.label,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}
