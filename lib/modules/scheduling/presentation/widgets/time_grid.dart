import 'package:flutter/material.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/shared/widgets/loading_skeleton.dart';

/// Premium time slot grid with animated selection, fixed-width columns,
/// stronger selected shadow, and polished typography.
class TimeGrid extends StatelessWidget {
  final List<DateTime> slots;
  final DateTime? selectedSlot;
  final ValueChanged<DateTime?> onSelected;
  final bool isLoading;

  static const double _chipWidth = 76;
  static const double _chipHeight = 48;

  const TimeGrid({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.onSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return _TimeGridSkeleton();
    }

    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 40,
                color: AppColors.mutedForeground(context),
              ),
              const SizedBox(height: 12),
              Text(
                'Nenhum horário disponível para esta data.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedForeground(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: slots
          .map((slot) => SizedBox(
                width: _chipWidth,
                height: _chipHeight,
                child: _TimeChip(
                  slot: slot,
                  isSelected: selectedSlot == slot,
                  onTap: () => onSelected(selectedSlot == slot ? null : slot),
                ),
              ))
          .toList(),
    );
  }
}

class _TimeChip extends StatefulWidget {
  final DateTime slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeChip({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TimeChip> createState() => _TimeChipState();
}

class _TimeChipState extends State<_TimeChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label =
        '${widget.slot.hour.toString().padLeft(2, '0')}:${widget.slot.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isSelected
                      ? theme.colorScheme.primary
                      : AppColors.border(context),
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: theme.colorScheme.shadow
                              .withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: widget.isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimeGridSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(12, (_) => ShimmerBox(width: 76, height: 48)),
    );
  }
}
