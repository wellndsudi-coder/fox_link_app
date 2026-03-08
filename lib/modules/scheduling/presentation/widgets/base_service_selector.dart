import 'package:flutter/material.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/modules/services/domain/entities/service.dart';

/// Single-select base service cards.
class BaseServiceSelector extends StatelessWidget {
  final List<Service> baseServices;
  final Service? selectedBase;
  final ValueChanged<Service> onSelected;

  const BaseServiceSelector({
    super.key,
    required this.baseServices,
    required this.selectedBase,
    required this.onSelected,
  });

  String _formatPrice(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: baseServices
          .map((service) {
            final isSelected = selectedBase?.id == service.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(service),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : AppColors.border(context),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name.value,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.schedule_rounded, size: 14, color: AppColors.mutedForeground(context)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${service.baseDuration.minutes} min',
                                    style: TextStyle(color: AppColors.mutedForeground(context), fontSize: 13),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _formatPrice(service.basePrice.value),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : AppColors.mutedForeground(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          })
          .toList(),
    );
  }
}
