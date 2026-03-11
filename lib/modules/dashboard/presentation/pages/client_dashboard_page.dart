// ALTERAÇÃO FOX LINK DASHBOARD — Refatoração UX estilo SaaS (Booksy, Fresha, Trinks)

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/storage/acknowledged_cancellations_storage.dart';
import 'package:fox_link_app/core/utils/date_formatter.dart';
import 'package:fox_link_app/modules/dashboard/domain/entities/client_appointment_display.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_client_appointments_display_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/accept_reschedule_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/cancel_appointment_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_top_services_usecase.dart'
    show GetTopServicesUseCase, TopServiceItem;
import 'package:fox_link_app/modules/booking_intelligence/presentation/widgets/first_available_slot_card.dart';
import 'package:fox_link_app/modules/booking_intelligence/presentation/widgets/repeat_appointment_card.dart';
import 'package:fox_link_app/modules/booking_intelligence/presentation/widgets/smart_suggestions_card.dart';
import 'package:fox_link_app/modules/booking_intelligence/presentation/widgets/queue_status_card.dart';
import 'package:fox_link_app/modules/booking_intelligence/presentation/widgets/waiting_list_card.dart';
import 'package:fox_link_app/modules/booking_intelligence/presentation/widgets/client_offered_slots_section.dart';
import 'package:fox_link_app/modules/booking_intelligence/presentation/widgets/favorites_professionals_section.dart';
import 'package:fox_link_app/modules/booking_intelligence/presentation/widgets/client_history_section.dart';
import 'package:fox_link_app/shared/widgets/app_header.dart';
import 'package:fox_link_app/shared/widgets/app_button.dart';

class ClientDashboardPage extends StatefulWidget {
  final void Function(int pageIndex)? onNavigateToPage;
  final bool isActive;

  const ClientDashboardPage({
    this.onNavigateToPage,
    this.isActive = true,
  });

  @override
  State<ClientDashboardPage> createState() => _ClientDashboardPageState();
}

class _ClientDashboardPageState extends State<ClientDashboardPage> {
  final _session = GetIt.I<TenantSession>();
  final _getAppointments = GetIt.I<GetClientAppointmentsDisplayUseCase>();
  final _ackStorage = GetIt.I<AcknowledgedCancellationsStorage>();
  final _acceptReschedule = GetIt.I<AcceptRescheduleUseCase>();
  final _cancelAppointment = GetIt.I<CancelAppointmentUseCase>();

  late Future<List<ClientAppointmentDisplay>> _futureAppointments;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ClientDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _load();
    }
  }

  void _load() {
    if (_session.uid != null) {
      _futureAppointments = _getAppointments(_session.uid!);
    } else {
      _futureAppointments = Future.value(<ClientAppointmentDisplay>[]);
    }
  }

  String _getUserName() {
    return _session.email?.split('@').first ?? 'Cliente';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          _load();
          setState(() {});
        },
        child: FutureBuilder<List<ClientAppointmentDisplay>>(
          future: _futureAppointments,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _DashboardSkeleton();
            }

            final all = snapshot.data!;
            final now = DateTime.now();
            final uid = _session.uid ?? '';

            return FutureBuilder<Set<String>>(
              future: _ackStorage.getAcknowledged(uid),
              builder: (context, ackSnapshot) {
                final acknowledged = ackSnapshot.data ?? {};
                final rescheduleRequested = all
                    .where((d) =>
                        d.appointment.scheduledStart.isAfter(now) &&
                        d.appointment.status == AppointmentStatus.rescheduleRequested)
                    .toList()
                  ..sort((a, b) => a.appointment.scheduledStart.compareTo(b.appointment.scheduledStart));
                final recentCancelled = all
                    .where((d) =>
                        d.appointment.status == AppointmentStatus.cancelled &&
                        !acknowledged.contains(d.appointment.id) &&
                        d.appointment.cancelledAt != null &&
                        d.appointment.cancelledAt!.isAfter(now.subtract(const Duration(days: 7))))
                    .toList()
                  ..sort((a, b) => (b.appointment.cancelledAt ?? DateTime.now())
                      .compareTo(a.appointment.cancelledAt ?? DateTime.now()));
                final upcoming = all
                    .where((d) =>
                        d.appointment.scheduledStart.isAfter(now) &&
                        (d.appointment.status == AppointmentStatus.approved ||
                            d.appointment.status == AppointmentStatus.pending))
                    .toList()
                  ..sort((a, b) => a.appointment.scheduledStart.compareTo(b.appointment.scheduledStart));
                final nextAppointment = upcoming.isNotEmpty ? upcoming.first : null;

                DashboardCardType cardType;
                ClientAppointmentDisplay? cardDisplay;
                if (rescheduleRequested.isNotEmpty) {
                  cardType = DashboardCardType.rescheduleRequested;
                  cardDisplay = rescheduleRequested.first;
                } else if (recentCancelled.isNotEmpty) {
                  cardType = DashboardCardType.cancelled;
                  cardDisplay = recentCancelled.first;
                } else if (nextAppointment != null) {
                  cardType = DashboardCardType.nextAppointment;
                  cardDisplay = nextAppointment;
                } else {
                  cardType = DashboardCardType.empty;
                }

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppHeader(
                        title: 'Olá, ${_getUserName()} 👋',
                        subtitle: 'Pronto para seu próximo horário?',
                        isGreeting: true,
                      ),
                      const SizedBox(height: 16),
                      if (cardType == DashboardCardType.rescheduleRequested && cardDisplay != null)
                        _RescheduleRequestedCard(
                          display: cardDisplay,
                          onAccept: () async {
                            final d = cardDisplay;
                            if (d == null) return;
                            final a = d.appointment;
                            if (a.proposedStart == null) return;
                            try {
                              await _acceptReschedule(a);
                              if (mounted) {
                                _load();
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Reagendamento confirmado!')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                          onRefuse: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Recusar reagendamento?'),
                                content: const Text('O agendamento será cancelado.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text('Sim', style: TextStyle(color: AppColors.error(ctx))),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && cardDisplay != null) {
                              await _cancelAppointment(cardDisplay.appointment.id);
                              await _ackStorage.acknowledge(uid, cardDisplay.appointment.id);
                              if (mounted) {
                                _load();
                                setState(() {});
                              }
                            }
                          },
                          onSeeDetails: () => widget.onNavigateToPage?.call(2),
                        )
                      else if (cardType == DashboardCardType.cancelled && cardDisplay != null)
                        _CancelledNoticeCard(
                          display: cardDisplay,
                          appointmentId: cardDisplay.appointment.id,
                          onOk: (appointmentId) async {
                            await _ackStorage.acknowledge(uid, appointmentId);
                            if (mounted) {
                              _load();
                              setState(() {});
                            }
                          },
                        )
                      else if (cardType == DashboardCardType.nextAppointment && cardDisplay != null)
                        _NextAppointmentCard(
                          display: cardDisplay,
                          onTap: () => widget.onNavigateToPage?.call(2),
                          onReagendar: () => widget.onNavigateToPage?.call(2),
                          onCancelar: () {},
                        )
                      else
                        _EmptyNextAppointmentCard(
                          onTap: () => widget.onNavigateToPage?.call(1),
                        ),
                      const SizedBox(height: 16),
                      AppButton(
                    text: '+ Agendar horário',
                    onPressed: () => widget.onNavigateToPage?.call(1),
                  ),
                  const SizedBox(height: 16),
                  // FOX LINK BOOKING INTELLIGENCE: Primeiro horário disponível
                      FirstAvailableSlotCard(
                        onNavigateToPage: widget.onNavigateToPage,
                      ),
                      const SizedBox(height: 16),
                      RepeatAppointmentCard(
                    onNavigateToPage: widget.onNavigateToPage,
                  ),
                      const SizedBox(height: 16),
                      SmartSuggestionsCard(
                        onNavigateToPage: widget.onNavigateToPage,
                      ),
                      const SizedBox(height: 16),
                      _PopularServicesSection(
                    onNavigateToPage: widget.onNavigateToPage,
                  ),
                      const SizedBox(height: 16),
                      FavoritesProfessionalsSection(
                        onNavigateToPage: widget.onNavigateToPage,
                      ),
                      const SizedBox(height: 16),
                      QueueStatusCard(
                        onNavigateToPage: widget.onNavigateToPage,
                      ),
                      const SizedBox(height: 16),
                      ClientOfferedSlotsSection(
                        onNavigateToPage: widget.onNavigateToPage,
                      ),
                      const SizedBox(height: 16),
                      WaitingListCard(
                        onNavigateToPage: widget.onNavigateToPage,
                      ),
                      const SizedBox(height: 16),
                      ClientHistorySection(
                        onNavigateToPage: widget.onNavigateToPage,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

enum DashboardCardType { rescheduleRequested, cancelled, nextAppointment, empty }

class _RescheduleRequestedCard extends StatelessWidget {
  final ClientAppointmentDisplay display;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;
  final VoidCallback? onSeeDetails;

  const _RescheduleRequestedCard({
    required this.display,
    required this.onAccept,
    required this.onRefuse,
    this.onSeeDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = display.appointment;
    final warning = AppColors.warning(context);

    return Container(
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warning.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule_send, color: warning),
                const SizedBox(width: 8),
                Text(
                  'Reagendamento solicitado',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              display.serviceName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Seu horário de ${AppDateFormatter.friendlyDateAndTime(a.scheduledStart)} foi alterado para ${a.proposedStart != null ? AppDateFormatter.friendlyDateAndTime(a.proposedStart!) : "novo horário"}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton(
                  onPressed: onAccept,
                  child: const Text('Aceitar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onRefuse,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error(context),
                  ),
                  child: const Text('Recusar'),
                ),
                if (onSeeDetails != null) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: onSeeDetails,
                    child: const Text('Ver detalhes'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelledNoticeCard extends StatelessWidget {
  final ClientAppointmentDisplay display;
  final String appointmentId;
  final void Function(String appointmentId) onOk;

  const _CancelledNoticeCard({
    required this.display,
    required this.appointmentId,
    required this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = display.appointment;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.mutedForeground(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_busy, color: AppColors.mutedForeground(context)),
                const SizedBox(width: 8),
                Text(
                  'Agendamento cancelado',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${display.serviceName} • ${AppDateFormatter.friendlyDateAndTime(a.scheduledStart)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => onOk(appointmentId),
                child: const Text('Ok'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  final ClientAppointmentDisplay display;
  final VoidCallback? onTap;
  final VoidCallback? onReagendar;
  final VoidCallback? onCancelar;

  const _NextAppointmentCard({
    required this.display,
    this.onTap,
    this.onReagendar,
    this.onCancelar,
  });

  String _statusLabel(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.approved:
        return 'Confirmado';
      case AppointmentStatus.pending:
        return 'Pendente';
      default:
        return s.toString().split('.').last;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: primary),
                    const SizedBox(width: 8),
                    Text(
                      'Próximo agendamento',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(display.appointment.status),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  DateFormat("EEEE, d 'de' MMMM", 'pt_BR')
                      .format(display.appointment.scheduledStart),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm', 'pt_BR').format(display.appointment.scheduledStart),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.mutedForeground(context),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: onReagendar,
                      child: const Text('Reagendar'),
                    ),
                    TextButton(
                      onPressed: onCancelar,
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ALTERAÇÃO FOX LINK DASHBOARD: Empty state do card principal
class _EmptyNextAppointmentCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _EmptyNextAppointmentCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Próximo agendamento',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nenhum agendamento em breve',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedForeground(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ALTERAÇÃO FOX LINK DASHBOARD: Seção Serviços populares
class _PopularServicesSection extends StatelessWidget {
  final void Function(int pageIndex)? onNavigateToPage;

  const _PopularServicesSection({this.onNavigateToPage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<TopServiceItem>>(
      future: GetIt.I<GetTopServicesUseCase>()(limit: 6),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Serviços populares',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final name = item.serviceName;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < items.length - 1 ? 12 : 0,
                    ),
                    child: _ServiceChip(
                      label: name,
                      onTap: () => onNavigateToPage?.call(1),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ServiceChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 90,
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatefulWidget {
  @override
  State<_DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<_DashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
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

  Widget _shimmerBox(double width, double height) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withValues(
              alpha: _animation.value,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _shimmerBox(180, 28),
          const SizedBox(height: 8),
          _shimmerBox(220, 18),
          const SizedBox(height: 16),
          _shimmerBox(double.infinity, 160),
          const SizedBox(height: 16),
          _shimmerBox(double.infinity, 52),
          const SizedBox(height: 16),
          _shimmerBox(120, 20),
          const SizedBox(height: 8),
          _shimmerBox(double.infinity, 100),
          const SizedBox(height: 16),
          _shimmerBox(double.infinity, 80),
          const SizedBox(height: 16),
          _shimmerBox(double.infinity, 100),
        ],
      ),
    );
  }
}
