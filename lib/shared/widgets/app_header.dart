import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  /// Titulo principal ou saudacao (ex: "Ola, Joao!")
  final String title;
  /// Subtitulo (ex: "Aqui esta o resumo de hoje")
  final String? subtitle;
  /// Acao opcional (ex: botao "Ver tudo")
  final Widget? action;
  /// Se true, usa estilo de saudacao (titulo maior, mais destaque)
  final bool isGreeting;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.isGreeting = false,
  });

  /// Header para saudacao do dashboard
  factory AppHeader.greeting({
    required String name,
    String? subtitle,
    Widget? action,
  }) {
    return AppHeader(
      title: 'Ola, $name!',
      subtitle: subtitle ?? 'Aqui esta o resumo de hoje',
      action: action,
      isGreeting: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = isGreeting
        ? Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            )
        : Theme.of(context).textTheme.headlineMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: titleStyle,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
