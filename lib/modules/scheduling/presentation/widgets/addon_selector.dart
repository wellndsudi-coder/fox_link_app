import 'package:flutter/material.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/modules/services/domain/entities/service.dart';

/// Multi-select add-ons for a base service. Shows name, duration, price per add-on.
class AddonSelector extends StatelessWidget {
  final List<Service> addons;
  final List<Service> selectedAddons;
  final ValueChanged<Service> onToggle;
  final int totalDurationMinutes;
  final double totalPrice;

  const AddonSelector({
    super.key,
    required this.addons,
    required this.selectedAddons,
    required this.onToggle,
    required this.totalDurationMinutes,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    if (addons.isEmpty) {
      return _EmptyAddonState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...addons.map((addon) {
          final selected = selectedAddons.any((s) => s.id == addon.id);
          return _AddonChip(
            addon: addon,
            selected: selected,
            onTap: () => onToggle(addon),
          );
        }),
        const SizedBox(height: 16),
        if (selectedAddons.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.fillColor(context),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  '$totalDurationMinutes min • R\$ ${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary(context),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AddonChip extends StatefulWidget {
  final Service addon;
  final bool selected;
  final VoidCallback onTap;

  const _AddonChip({
    required this.addon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_AddonChip> createState() => _AddonChipState();
}

class _AddonChipState extends State<_AddonChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
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

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 - (_controller.value * 0.04);
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.selected
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : AppColors.card(context),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(
              color: widget.selected
                  ? theme.colorScheme.primary
                  : AppColors.border(context),
              width: widget.selected ? 2 : 1,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.selected ? Icons.check_circle : Icons.add_circle_outline,
                size: 22,
                color: widget.selected
                    ? theme.colorScheme.primary
                    : AppColors.mutedForeground(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.addon.name.value,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    Text(
                      '${widget.addon.baseDuration.minutes} min • R\$ ${widget.addon.basePrice.value.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAddonState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.fillColor(context),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: AppColors.mutedForeground(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Nenhum add-on disponível para este serviço',
              style: TextStyle(
                color: AppColors.mutedForeground(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
