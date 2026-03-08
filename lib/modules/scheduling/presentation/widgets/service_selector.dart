import 'package:flutter/material.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/modules/services/domain/entities/service.dart';

/// Card-style service selector with name, duration, price.
/// Selected state with primary border and check icon.
class ServiceSelector extends StatelessWidget {
  final Service? selectedService;
  final List<Service> services;
  final ValueChanged<Service?> onChanged;

  const ServiceSelector({
    super.key,
    required this.selectedService,
    required this.services,
    required this.onChanged,
  });

  String _formatPrice(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: services
          .map((service) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ServiceCard(
                  service: service,
                  isSelected: selectedService?.id == service.id,
                  onTap: () => onChanged(selectedService?.id == service.id ? null : service),
                  formatPrice: _formatPrice,
                ),
              ))
          .toList(),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  final bool isSelected;
  final VoidCallback onTap;
  final String Function(double) formatPrice;

  const _ServiceCard({
    required this.service,
    required this.isSelected,
    required this.onTap,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : AppColors.border(context),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: isSelected ? 0.08 : 0.04),
                blurRadius: isSelected ? 16 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name.value,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.mutedForeground(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${service.baseDuration.minutes} min',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedForeground(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          formatPrice(service.basePrice.value),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : AppColors.border(context),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check_rounded, size: 18, color: theme.colorScheme.onPrimary)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
