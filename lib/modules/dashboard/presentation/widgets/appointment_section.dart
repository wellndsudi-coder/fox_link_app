import 'package:flutter/material.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/modules/dashboard/domain/entities/client_appointment_display.dart';
import 'package:fox_link_app/modules/dashboard/presentation/widgets/client_appointment_card.dart';

class AppointmentSection extends StatelessWidget {
  final String title;
  final List<ClientAppointmentDisplay> appointments;
  final void Function(ClientAppointmentDisplay)? onAppointmentTap;
  final Future<void> Function(String appointmentId)? onCancel;
  final VoidCallback? Function(ClientAppointmentDisplay)? onRebook;
  final bool enableSwipeToCancel;

  const AppointmentSection({
    super.key,
    required this.title,
    required this.appointments,
    this.onAppointmentTap,
    this.onCancel,
    this.onRebook,
    this.enableSwipeToCancel = false,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.mutedForeground(context),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...appointments.asMap().entries.map((entry) {
          final index = entry.key;
          final d = entry.value;
          final card = TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 150)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClientAppointmentCard(
                display: d,
                onTap: onAppointmentTap != null ? () => onAppointmentTap!(d) : null,
                onCancel: onCancel != null
                    ? () async {
                        await onCancel!(d.appointment.id);
                      }
                    : null,
                onRebook: onRebook?.call(d) != null ? onRebook!(d) : null,
              ),
            ),
          );
          if (enableSwipeToCancel && onCancel != null) {
            return Dismissible(
              key: ValueKey(d.appointment.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
              ),
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cancelar agendamento?'),
                    content: const Text('Tem certeza que deseja cancelar este agendamento?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Não'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Sim', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) => onCancel!(d.appointment.id),
              child: card,
            );
          }
          return card;
        }),
      ],
    );
  }
}
