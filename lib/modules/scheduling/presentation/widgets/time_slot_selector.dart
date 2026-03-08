import 'package:flutter/material.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';

/// Premium time slot selector with animated ChoiceChip-style selection.
class TimeSlotSelector extends StatelessWidget {
  final List<DateTime> slots;
  final DateTime? selectedSlot;
  final ValueChanged<DateTime?> onSelected;
  final bool isLoading;

  const TimeSlotSelector({
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
      return _TimeSlotSkeleton();
    }

    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Center(
          child: Text(
            'Nenhum horário disponível para esta data.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedForeground(context),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: slots.map((slot) => _AnimatedTimeChip(
        slot: slot,
        isSelected: selectedSlot == slot,
        onTap: () => onSelected(selectedSlot == slot ? null : slot),
      )).toList(),
    );
  }
}

class _AnimatedTimeChip extends StatefulWidget {
  final DateTime slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedTimeChip({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AnimatedTimeChip> createState() => _AnimatedTimeChipState();
}

class _AnimatedTimeChipState extends State<_AnimatedTimeChip>
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
    final label = '${widget.slot.hour.toString().padLeft(2, '0')}:${widget.slot.minute.toString().padLeft(2, '0')}';

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: widget.isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimeSlotSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(8, (i) => _ShimmerChip()),
    );
  }
}

class _ShimmerChip extends StatefulWidget {
  @override
  State<_ShimmerChip> createState() => _ShimmerChipState();
}

class _ShimmerChipState extends State<_ShimmerChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: 72,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest
                .withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}
