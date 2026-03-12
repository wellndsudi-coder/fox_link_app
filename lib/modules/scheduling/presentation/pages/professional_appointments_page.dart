import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/utils/date_formatter.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:fox_link_app/modules/services/domain/usecases/get_services.dart';
import 'package:fox_link_app/modules/users/domain/repositories/user_repository.dart';
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';

/// Página de Agendamentos com 3 seções: Confirmados, Aguardando confirmação, Concluídos.
class ProfessionalAppointmentsPage extends StatefulWidget {
  final bool isActive;
  final void Function(DateTime date)? onNavigateToAgendaWithDate;

  const ProfessionalAppointmentsPage({
    super.key,
    this.isActive = true,
    this.onNavigateToAgendaWithDate,
  });

  @override
  State<ProfessionalAppointmentsPage> createState() =>
      _ProfessionalAppointmentsPageState();
}

class _ProfessionalAppointmentsPageState
    extends State<ProfessionalAppointmentsPage> {
  final _schedulingRepo = GetIt.I<SchedulingRepository>();
  final _session = GetIt.I<TenantSession>();
  final _userRepo = GetIt.I<UserRepository>();
  final _getServices = GetIt.I<GetServices>();
  final _professionalRemote = GetIt.I<ProfessionalRemoteDataSource>();

  List<Appointment> _confirmed = [];
  List<Appointment> _pending = [];
  List<Appointment> _completed = [];
  Map<String, String> _clientNames = {};
  Map<String, String> _serviceNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfessionalAppointmentsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _load();
    }
  }

  Future<String?> _resolveProfessionalId() async {
    var profId = _session.professionalId;
    if (profId == null && _session.uid != null) {
      final prof =
          await _professionalRemote.getProfessionalByUid(_session.uid!);
      if (prof != null && prof['id'] != null) {
        profId = prof['id'] as String;
        _session.setProfessionalId(profId);
      }
    }
    return profId;
  }

  Future<void> _load() async {
    final profId = await _resolveProfessionalId();
    if (profId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 60));
    final end = now.add(const Duration(days: 60));

    try {
      final periodList = await _schedulingRepo.getByProfessionalAndPeriod(
        professionalId: profId,
        start: start,
        end: end,
      );
      final pendingList =
          await _schedulingRepo.getPendingByProfessional(profId);

      final confirmed = periodList
          .where((a) =>
              a.status == AppointmentStatus.approved &&
              a.scheduledStart.isAfter(now))
          .toList()
        ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));

      final completed = periodList
          .where((a) => a.status == AppointmentStatus.completed)
          .toList()
        ..sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));

      pendingList.sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));

      final clientIds = [
        ...confirmed.map((a) => a.clientId),
        ...pendingList.map((a) => a.clientId),
        ...completed.map((a) => a.clientId),
      ].toSet()
          .toList();

      Map<String, String> clientNames = {};
      if (clientIds.isNotEmpty) {
        final users = await _userRepo.getUsersByIds(clientIds);
        for (var i = 0; i < clientIds.length && i < users.length; i++) {
          final u = users[i];
          final name = (u['name'] as String?) ??
              (u['displayName'] as String?) ??
              (u['email'] as String?) ??
              clientIds[i];
          clientNames[clientIds[i]] = name;
        }
      }

      Map<String, String> serviceNames = {};
      final tenantId = _session.tenantId;
      if (tenantId != null) {
        final services = await _getServices(tenantId);
        for (final s in services) {
          serviceNames[s.id] = s.name.value;
        }
      }

      if (mounted) {
        setState(() {
          _confirmed = confirmed;
          _pending = pendingList;
          _completed = completed;
          _clientNames = clientNames;
          _serviceNames = serviceNames;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _serviceName(Appointment a) =>
      _serviceNames[a.effectiveBaseServiceId] ??
      _serviceNames[a.serviceId] ??
      'Atendimento';

  String _clientName(Appointment a) =>
      _clientNames[a.clientId] ?? a.clientId;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              title: 'Aguardando confirmação',
              icon: Icons.schedule,
              color: AppColors.warning(context),
              appointments: _pending,
              emptyMessage: 'Nenhum agendamento aguardando confirmação',
              serviceName: _serviceName,
              clientName: _clientName,
              onAppointmentTap: widget.onNavigateToAgendaWithDate != null
                  ? (a) => widget.onNavigateToAgendaWithDate!(
                        DateTime(
                          a.scheduledStart.year,
                          a.scheduledStart.month,
                          a.scheduledStart.day,
                        ),
                      )
                  : null,
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Agendamentos confirmados',
              icon: Icons.check_circle_outline,
              color: AppColors.success(context),
              appointments: _confirmed,
              emptyMessage: 'Nenhum agendamento confirmado',
              serviceName: _serviceName,
              clientName: _clientName,
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Concluídos',
              icon: Icons.done_all,
              color: AppColors.mutedForeground(context),
              appointments: _completed,
              emptyMessage: 'Nenhum agendamento concluído',
              serviceName: _serviceName,
              clientName: _clientName,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Appointment> appointments;
  final String emptyMessage;
  final String Function(Appointment) serviceName;
  final String Function(Appointment) clientName;
  final void Function(Appointment)? onAppointmentTap;

  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.appointments,
    required this.emptyMessage,
    required this.serviceName,
    required this.clientName,
    this.onAppointmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (appointments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Text(
              emptyMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...appointments.map((a) => _AppointmentCard(
                appointment: a,
                serviceName: serviceName(a),
                clientName: clientName(a),
                color: color,
                onTap: onAppointmentTap != null
                    ? () => onAppointmentTap!(a)
                    : null,
              )),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final String serviceName;
  final String clientName;
  final Color color;
  final VoidCallback? onTap;

  const _AppointmentCard({
    required this.appointment,
    required this.serviceName,
    required this.clientName,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr =
        DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(appointment.scheduledStart);
    final timeStr = DateFormat('HH:mm', 'pt_BR').format(appointment.scheduledStart);

    final child = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            serviceName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            clientName,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedForeground(context),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                '$dateStr • $timeStr',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedForeground(context),
                ),
              ),
            ],
          ),
          if (appointment.finalDuration > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Duração: ${AppDateFormatter.friendlyDuration(appointment.finalDuration)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
            ),
          ],
        ],
      ),
    );

    final card = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }
    return card;
  }
}
