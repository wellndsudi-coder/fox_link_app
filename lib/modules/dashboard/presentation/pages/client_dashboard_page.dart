import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_client_appointments_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/shared/widgets/app_header.dart';
import 'package:fox_link_app/shared/widgets/app_card.dart';

class ClientDashboardPage extends StatefulWidget {
  final void Function(int pageIndex)? onNavigateToPage;

  const ClientDashboardPage({this.onNavigateToPage});

  @override
  State<ClientDashboardPage> createState() => _ClientDashboardPageState();
}

class _ClientDashboardPageState extends State<ClientDashboardPage> {
  final _session = GetIt.I<TenantSession>();
  final _getAppointments = GetIt.I<GetClientAppointmentsUseCase>();

  late Future<List<Appointment>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (_session.uid != null) {
      _future = _getAppointments(_session.uid!);
    } else {
      _future = Future.value(<Appointment>[]);
    }
  }

  String _getUserName() {
    return _session.email?.split('@').first ?? 'Cliente';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _load();
        setState(() {});
      },
      child: FutureBuilder<List<Appointment>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
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
          final pastCount = appointments
              .where((a) =>
                  a.scheduledStart.isBefore(now) ||
                  a.status == AppointmentStatus.completed ||
                  a.status == AppointmentStatus.cancelled)
              .length;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppHeader.greeting(
                  name: _getUserName(),
                  subtitle: 'Gerencie seus agendamentos',
                ),
                const SizedBox(height: 24),
                if (nextAppointment != null)
                  _NextAppointmentCard(
                    appointment: nextAppointment,
                    onTap: () => widget.onNavigateToPage?.call(2),
                  )
                else
                  _EmptyCard(
                    icon: Icons.calendar_today,
                    title: 'Próximo agendamento',
                    subtitle: 'Nenhum agendamento em breve',
                    buttonLabel: 'Agendar serviço',
                    onTap: () => widget.onNavigateToPage?.call(1),
                  ),
                const SizedBox(height: 16),
                _QuickActionCard(
                  icon: Icons.history,
                  title: 'Histórico',
                  subtitle: '$pastCount agendamentos anteriores',
                  onTap: () => widget.onNavigateToPage?.call(3),
                ),
                const SizedBox(height: 16),
                _QuickActionCard(
                  icon: Icons.favorite_border,
                  title: 'Favoritos',
                  subtitle: 'Profissionais e serviços favoritos',
                  onTap: () => widget.onNavigateToPage?.call(4),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => widget.onNavigateToPage?.call(1),
                      icon: const Icon(Icons.add),
                      label: const Text('Agendar serviço'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => widget.onNavigateToPage?.call(2),
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Ver agenda'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;

  const _NextAppointmentCard({
    required this.appointment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Próximo agendamento',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            DateFormat("EEEE, d 'de' MMMM 'às' HH:mm", 'pt_BR')
                .format(appointment.scheduledStart),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _statusLabel(appointment.status),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.mutedForeground(context),
            ),
          ),
        ],
      ),
    );
  }

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
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onTap;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedForeground(context),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onTap,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedForeground(context),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}
