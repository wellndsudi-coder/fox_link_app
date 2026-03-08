import 'package:flutter/material.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';

/// Horizontal 4-step progress: Professional → Services → Date → Time.
/// Highlights completed and current step with smooth animations.
class StepProgressIndicator extends StatelessWidget {
  static const steps = ['Profissional', 'Serviços', 'Data', 'Horário'];

  final bool hasProfessional;
  final bool hasServices;
  final bool hasDate;
  final bool hasTime;

  const StepProgressIndicator({
    super.key,
    this.hasProfessional = false,
    this.hasServices = false,
    this.hasDate = false,
    this.hasTime = false,
  });

  int get currentStep {
    if (!hasProfessional) return 0;
    if (!hasServices) return 1;
    if (!hasDate) return 2;
    if (!hasTime) return 3;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: _StepConnector(
                isCompleted: (i ~/ 2) + 1 <= currentStep,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isCompleted = stepIndex < currentStep ||
              (stepIndex == 0 && hasProfessional) ||
              (stepIndex == 1 && hasServices) ||
              (stepIndex == 2 && hasDate) ||
              (stepIndex == 3 && hasTime);
          final isCurrent = stepIndex == currentStep;

          return _StepItem(
            label: steps[stepIndex],
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            theme: theme,
          );
        }),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String label;
  final bool isCompleted;
  final bool isCurrent;
  final ThemeData theme;

  const _StepItem({
    required this.label,
    required this.isCompleted,
    required this.isCurrent,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    final muted = AppColors.mutedForeground(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCompleted || isCurrent ? primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted || isCurrent ? primary : muted,
              width: 2,
            ),
          ),
          child: isCompleted
              ? Icon(Icons.check_rounded, size: 16, color: theme.colorScheme.onPrimary)
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isCompleted || isCurrent ? primary : muted,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  final bool isCompleted;

  const _StepConnector({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCompleted
        ? theme.colorScheme.primary
        : AppColors.mutedForeground(context).withValues(alpha: 0.4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
