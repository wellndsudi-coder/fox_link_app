// ALTERAÇÃO FOX LINK DASHBOARD — Refatoração UX estilo SaaS (Booksy, Fresha, Trinks)

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_client_appointments_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
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

  const ClientDashboardPage({this.onNavigateToPage});

  @override
  State<ClientDashboardPage> createState() => _ClientDashboardPageState();
}

class _ClientDashboardPageState extends State<ClientDashboardPage> {
  final _session = GetIt.I<TenantSession>();
  final _getAppointments = GetIt.I<GetClientAppointmentsUseCase>();

  late Future<List<Appointment>> _futureAppointments;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (_session.uid != null) {
      _futureAppointments = _getAppointments(_session.uid!);
    } else {
      _futureAppointments = Future.value(<Appointment>[]);
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
        child: FutureBuilder<List<Appointment>>(
          future: _futureAppointments,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _DashboardSkeleton();
            }

            final appointments = snapshot.data!;
            final now = DateTime.now();
            final upcoming = appointments
                .where((a) =>
                    a.scheduledStart.isAfter(now) &&
                    (a.status == AppointmentStatus.approved ||
                        a.status == AppointmentStatus.pending))
                .toList()
              ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
            final nextAppointment = upcoming.isNotEmpty ? upcoming.first : null;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ALTERAÇÃO FOX LINK DASHBOARD: Header profissional
                  AppHeader(
                    title: 'Olá, ${_getUserName()} 👋',
                    subtitle: 'Pronto para seu próximo horário?',
                    isGreeting: true,
                  ),
                  const SizedBox(height: 16),
                  // ALTERAÇÃO FOX LINK DASHBOARD: Card principal (borderRadius 16, elevation 2)
                  if (nextAppointment != null)
                    _NextAppointmentCard(
                      appointment: nextAppointment,
                      onTap: () => widget.onNavigateToPage?.call(2),
                      onReagendar: () => widget.onNavigateToPage?.call(2),
                      onCancelar: () {},
                    )
                  else
                    _EmptyNextAppointmentCard(
                      onTap: () => widget.onNavigateToPage?.call(1),
                    ),
                  const SizedBox(height: 16),
                  // ALTERAÇÃO FOX LINK DASHBOARD: Botão principal único
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
                  // FOX LINK BOOKING INTELLIGENCE: Agendar novamente
                  RepeatAppointmentCard(
                    onNavigateToPage: widget.onNavigateToPage,
                  ),
                  const SizedBox(height: 16),
                  // FOX LINK BOOKING INTELLIGENCE: Sugestões inteligentes
                  SmartSuggestionsCard(
                    onNavigateToPage: widget.onNavigateToPage,
                  ),
                  const SizedBox(height: 16),
                  // ALTERAÇÃO FOX LINK DASHBOARD: Serviços populares (horizontal scroll)
                  _PopularServicesSection(
                    onNavigateToPage: widget.onNavigateToPage,
                  ),
                  const SizedBox(height: 16),
                  // FOX LINK BOOKING INTELLIGENCE: Profissionais favoritos
                  FavoritesProfessionalsSection(
                    onNavigateToPage: widget.onNavigateToPage,
                  ),
                  const SizedBox(height: 16),
                  // FOX LINK BOOKING INTELLIGENCE: Fila virtual
                  QueueStatusCard(
                    onNavigateToPage: widget.onNavigateToPage,
                  ),
                  const SizedBox(height: 16),
                  // FOX LINK: Vagas oferecidas (cliente confirma)
                  ClientOfferedSlotsSection(
                    onNavigateToPage: widget.onNavigateToPage,
                  ),
                  const SizedBox(height: 16),
                  // FOX LINK BOOKING INTELLIGENCE: Lista de espera
                  WaitingListCard(
                    onNavigateToPage: widget.onNavigateToPage,
                  ),
                  const SizedBox(height: 16),
                  // FOX LINK BOOKING INTELLIGENCE: Histórico inteligente
                  ClientHistorySection(
                    onNavigateToPage: widget.onNavigateToPage,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ALTERAÇÃO FOX LINK DASHBOARD: Card principal com borderRadius 16, elevation 2
class _NextAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;
  final VoidCallback? onReagendar;
  final VoidCallback? onCancelar;

  const _NextAppointmentCard({
    required this.appointment,
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
                        _statusLabel(appointment.status),
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
                      .format(appointment.scheduledStart),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm', 'pt_BR').format(appointment.scheduledStart),
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
