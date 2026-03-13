import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/layout/layout_breakpoints.dart';
import 'package:fox_link_app/core/utils/date_formatter.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/approve_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/complete_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/reject_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/request_reschedule_usecase.dart';
import 'package:fox_link_app/modules/services/domain/usecases/get_services.dart';
import 'package:fox_link_app/modules/users/domain/repositories/user_repository.dart';
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';
import '../widgets/waitlist_dashboard_card.dart';

/// Dashboard do profissional integrado ao ProfessionalShell.
class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({
    super.key,
    this.isActive = true,
    this.onNavigateToAgenda,
    this.onNavigateToPage,
  });

  final bool isActive;
  final VoidCallback? onNavigateToAgenda;
  final void Function(int pageIndex)? onNavigateToPage;

  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  final _session = GetIt.I<TenantSession>();
  final _schedulingRepo = GetIt.I<SchedulingRepository>();
  final _userRepo = GetIt.I<UserRepository>();
  final _getServices = GetIt.I<GetServices>();
  final _approveUseCase = GetIt.I<ApproveAppointmentUseCase>();
  final _rejectUseCase = GetIt.I<RejectAppointmentUseCase>();
  final _rescheduleUseCase = GetIt.I<RequestRescheduleUseCase>();
  final _completeUseCase = GetIt.I<CompleteAppointmentUseCase>();
  final _professionalRemote = GetIt.I<ProfessionalRemoteDataSource>();

  List<Appointment> _pendingAppointments = [];
  List<Appointment> _upcomingApproved = [];
  Map<String, String> _clientNames = {};
  Map<String, String> _serviceNames = {};
  final Set<String> _startedAppointmentIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfessionalDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _load();
    }
  }

  Future<void> _load() async {
    final profId = await _resolveProfessionalId();
    if (profId == null) return;
    _loadPending();
    _loadUpcomingApproved();
  }

  Future<String?> _resolveProfessionalId() async {
    var profId = _session.professionalId;
    if (profId == null && _session.uid != null) {
      final prof = await _professionalRemote.getProfessionalByUid(_session.uid!);
      if (prof != null && prof['id'] != null) {
        profId = prof['id'] as String;
        _session.setProfessionalId(profId);
      }
    }
    return profId;
  }

  Future<void> _loadUpcomingApproved() async {
    final profId = _session.professionalId;
    final tenantId = _session.tenantId;
    if (profId == null) return;
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 7));
      final list = await _schedulingRepo.getByProfessionalAndPeriod(
        professionalId: profId,
        start: start,
        end: end,
      );
      final approved = list
          .where((a) =>
              a.status == AppointmentStatus.approved &&
              a.scheduledStart.isAfter(now))
          .toList()
        ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));

      final clientIds = approved.map((a) => a.clientId).toSet().toList();
      Map<String, String> clientNames = Map.from(_clientNames);
      Map<String, String> serviceNames = Map.from(_serviceNames);
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
      if (tenantId != null) {
        final services = await _getServices(tenantId);
        for (final s in services) {
          serviceNames[s.id] = s.name.value;
        }
      }

      if (mounted) {
        setState(() {
          _upcomingApproved = approved;
          _clientNames = clientNames;
          _serviceNames = serviceNames;
          _startedAppointmentIds.removeWhere(
            (id) => !approved.any((a) => a.id == id),
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPending() async {
    final profId = _session.professionalId;
    final tenantId = _session.tenantId;
    if (profId == null) return;
    try {
      final list = await _schedulingRepo.getPendingByProfessional(profId);
      list.sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));

      Map<String, String> clientNames = {};
      Map<String, String> serviceNames = {};

      if (list.isNotEmpty) {
        final clientIds = list.map((a) => a.clientId).toSet().toList();
        final users = await _userRepo.getUsersByIds(clientIds);
        for (var i = 0; i < clientIds.length && i < users.length; i++) {
          final u = users[i];
          final name = (u['name'] as String?) ??
              (u['displayName'] as String?) ??
              (u['email'] as String?) ??
              clientIds[i];
          clientNames[clientIds[i]] = name;
        }

        if (tenantId != null) {
          final services = await _getServices(tenantId);
          for (final s in services) {
            serviceNames[s.id] = s.name.value;
          }
        }
      }

      if (mounted) {
        setState(() {
          _pendingAppointments = list;
          _clientNames = clientNames;
          _serviceNames = serviceNames;
        });
      }
    } catch (_) {}
  }

  Future<void> _refresh() async {
    _load();
  }

  Future<void> _reschedulePending(Appointment appointment) async {
    final message = await showDialog<String>(
      context: context,
      builder: (c) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Solicitar reagendamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Digite uma mensagem para o cliente (opcional):',
                style: TextStyle(fontSize: 14, color: AppColors.mutedForeground(c)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Ex: Preciso alterar o horário...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(c, controller.text.trim()), child: const Text('Continuar')),
          ],
        );
      },
    );
    if (!mounted || message == null) return;

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: appointment.scheduledStart,
    );
    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appointment.scheduledStart),
    );
    if (!mounted || time == null) return;

    final newStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final newEnd = newStart.add(Duration(minutes: appointment.finalDuration));

    try {
      await _rescheduleUseCase(
        appointment: appointment,
        newStart: newStart,
        newEnd: newEnd,
        message: message.isEmpty ? null : message,
      );
      if (mounted) {
        _loadPending();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reagendamento solicitado! O cliente será notificado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.onNavigateToPage != null) ...[
                  _QuickAccessGrid(onNavigate: widget.onNavigateToPage!),
                  const SizedBox(height: 24),
                ],
                _UpcomingAppointmentsCarousel(
                  appointments: _upcomingApproved,
                  clientNames: _clientNames,
                  serviceNames: _serviceNames,
                  startedAppointmentIds: _startedAppointmentIds,
                  onStartService: (appointment) {
                    setState(() => _startedAppointmentIds.add(appointment.id));
                    if (widget.onNavigateToAgenda != null) {
                      widget.onNavigateToAgenda!();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Abra Minha Agenda para gerenciar o atendimento.'),
                        ),
                      );
                    }
                  },
                  onOpenAgenda: widget.onNavigateToAgenda ?? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Abra Minha Agenda para gerenciar o atendimento.'),
                      ),
                    );
                  },
                  onCompleteService: (appointment) async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) {
                        final serviceName = _serviceNames[
                                appointment.effectiveBaseServiceId] ??
                            _serviceNames[appointment.serviceId] ??
                            'Atendimento';
                        return AlertDialog(
                          title: const Text('Concluir serviço?'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$serviceName',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Duração: ${AppDateFormatter.friendlyDuration(appointment.finalDuration)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.mutedForeground(c),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'O serviço será marcado como concluído na agenda e aparecerá no relatório.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.mutedForeground(c),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Concluir'),
                            ),
                          ],
                        );
                      },
                    );
                    if (!mounted || confirm != true) return;
                    try {
                      await _completeUseCase(appointment);
                      if (mounted) {
                        _loadUpcomingApproved();
                        _load();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Serviço concluído! Atualizado no relatório.'),
                          ),
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
                ),
                const SizedBox(height: 24),
                _PendingAppointmentsCarousel(
                  appointments: _pendingAppointments,
                  clientNames: _clientNames,
                  serviceNames: _serviceNames,
                  onAccept: (a) async {
                    try {
                      await _approveUseCase(a);
                      if (mounted) {
                        _loadPending();
                        _load();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Agendamento confirmado!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                  onReschedule: _reschedulePending,
                  onReject: (a) async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Recusar agendamento?'),
                        content: const Text('O horário ficará livre. Tem certeza?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Não')),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Sim', style: TextStyle(color: AppColors.error(c)))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await _rejectUseCase(a);
                        if (mounted) {
                          _loadPending();
                          _load();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Agendamento recusado.')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    }
                  },
                ),
                const SizedBox(height: 24),
                WaitlistDashboardCard(
                  professionalId: _session.professionalId,
                ),
              ],
            ),
          ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final void Function(int) onNavigate;

  const _QuickAccessGrid({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: LayoutBreakpoints.gridSpacing(context),
      mainAxisSpacing: LayoutBreakpoints.gridSpacing(context),
      childAspectRatio: 2 / 1.2,
      children: [
        _QuickAccessCard(
          label: 'Clientes',
          icon: Icons.people,
          iconColor: primary,
          onTap: () => onNavigate(4),
        ),
        _QuickAccessCard(
          label: 'Agendamentos',
          icon: Icons.event_note,
          iconColor: primary,
          onTap: () => onNavigate(2),
        ),
        _QuickAccessCard(
          label: 'Serviços',
          icon: Icons.design_services,
          iconColor: primary,
          onTap: () => onNavigate(5),
        ),
        _QuickAccessCard(
          label: 'Minha Agenda',
          icon: Icons.calendar_month,
          iconColor: primary,
          onTap: () => onNavigate(1),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _UpcomingAppointmentsCarousel extends StatefulWidget {
  final List<Appointment> appointments;
  final Map<String, String> clientNames;
  final Map<String, String> serviceNames;
  final Set<String> startedAppointmentIds;
  final void Function(Appointment) onStartService;
  final void Function(Appointment) onCompleteService;
  final VoidCallback? onOpenAgenda;

  const _UpcomingAppointmentsCarousel({
    required this.appointments,
    required this.clientNames,
    required this.serviceNames,
    required this.startedAppointmentIds,
    required this.onStartService,
    required this.onCompleteService,
    this.onOpenAgenda,
  });

  @override
  State<_UpcomingAppointmentsCarousel> createState() => _UpcomingAppointmentsCarouselState();
}

class _UpcomingAppointmentsCarouselState extends State<_UpcomingAppointmentsCarousel> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appointments = widget.appointments;
    final hasMultiple = appointments.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: hasMultiple
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 20),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      )
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Agenda da semana',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: hasMultiple
                    ? IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 20),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      )
                    : null,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: appointments.isEmpty
              ? _EmptyUpcomingCard(
                  onOpenAgenda: widget.onOpenAgenda ?? () {},
                )
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.horizontal,
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final a = appointments[index];
                    final clientName = widget.clientNames[a.clientId] ?? a.clientId;
                    final serviceName = widget.serviceNames[a.effectiveBaseServiceId] ??
                        widget.serviceNames[a.serviceId] ??
                        'Atendimento';
                    final isStarted = widget.startedAppointmentIds.contains(a.id);
                    return _UpcomingAppointmentCard(
                      appointment: a,
                      clientName: clientName,
                      serviceName: serviceName,
                      isStarted: isStarted,
                      onStartService: () => widget.onStartService(a),
                      onCompleteService: () => widget.onCompleteService(a),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptyUpcomingCard extends StatelessWidget {
  final VoidCallback onOpenAgenda;

  const _EmptyUpcomingCard({required this.onOpenAgenda});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = AppColors.primary(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 32,
              color: AppColors.mutedForeground(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Nenhum horário agendado',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onOpenAgenda,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Ver agenda',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final String clientName;
  final String serviceName;
  final bool isStarted;
  final VoidCallback onStartService;
  final VoidCallback onCompleteService;

  const _UpcomingAppointmentCard({
    required this.appointment,
    required this.clientName,
    required this.serviceName,
    required this.isStarted,
    required this.onStartService,
    required this.onCompleteService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = AppColors.primary(context);
    final dateStr = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(appointment.scheduledStart);
    final timeStr = DateFormat('HH:mm', 'pt_BR').format(appointment.scheduledStart);

    return Container(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, color: primary, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Próximo agendamento',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Confirmado',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              serviceName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$dateStr $timeStr',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 0.75,
                  alignment: Alignment.center,
                  child: _ChipStyleButton(
                    label: 'Iniciar serviço',
                    onTap: onStartService,
                    enabled: true,
                    primary: primary,
                  ),
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.75,
                  alignment: Alignment.center,
                  child: _ChipStyleButton(
                    label: 'Concluir serviço',
                    onTap: onCompleteService,
                    enabled: isStarted,
                    primary: primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Botão no formato do chip Hoje/Semana/Mês da agenda cliente - fundo transparente.
class _ChipStyleButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final Color primary;

  const _ChipStyleButton({
    required this.label,
    required this.onTap,
    required this.enabled,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? primary : AppColors.mutedForeground(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(
            color: color,
            width: enabled ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: enabled ? FontWeight.w600 : FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _PendingAppointmentsCarousel extends StatefulWidget {
  final List<Appointment> appointments;
  final Map<String, String> clientNames;
  final Map<String, String> serviceNames;
  final void Function(Appointment) onAccept;
  final void Function(Appointment) onReschedule;
  final void Function(Appointment) onReject;

  const _PendingAppointmentsCarousel({
    required this.appointments,
    required this.clientNames,
    required this.serviceNames,
    required this.onAccept,
    required this.onReschedule,
    required this.onReject,
  });

  @override
  State<_PendingAppointmentsCarousel> createState() => _PendingAppointmentsCarouselState();
}

class _PendingAppointmentsCarouselState extends State<_PendingAppointmentsCarousel> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appointments = widget.appointments;
    final hasMultiple = appointments.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: hasMultiple
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 20),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      )
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Agendamentos para confirmar',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: hasMultiple
                    ? IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 20),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      )
                    : null,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: appointments.isEmpty
              ? _EmptyPendingCard(onOpenAgenda: null)
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.horizontal,
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final a = appointments[index];
                    final clientName = widget.clientNames[a.clientId] ?? a.clientId;
                    final serviceName = widget.serviceNames[a.effectiveBaseServiceId] ??
                        widget.serviceNames[a.serviceId] ??
                        'Atendimento';
                    return _PendingAppointmentCard(
                      appointment: a,
                      clientName: clientName,
                      serviceName: serviceName,
                      onAccept: () => widget.onAccept(a),
                      onReschedule: () => widget.onReschedule(a),
                      onReject: () => widget.onReject(a),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptyPendingCard extends StatelessWidget {
  final VoidCallback? onOpenAgenda;

  const _EmptyPendingCard({this.onOpenAgenda});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = AppColors.warning(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: warning.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 32, color: AppColors.mutedForeground(context)),
            const SizedBox(height: 8),
            Text(
              'Nenhum agendamento pendente',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final String clientName;
  final String serviceName;
  final VoidCallback onAccept;
  final VoidCallback onReschedule;
  final VoidCallback onReject;

  const _PendingAppointmentCard({
    required this.appointment,
    required this.clientName,
    required this.serviceName,
    required this.onAccept,
    required this.onReschedule,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = AppColors.warning(context);
    final dateStr = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(appointment.scheduledStart);
    final timeStr = DateFormat('HH:mm', 'pt_BR').format(appointment.scheduledStart);

    return Container(
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, color: warning, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pendente',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: warning,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Aguardando',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: warning,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                serviceName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$dateStr $timeStr',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedForeground(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 0.75,
                    alignment: Alignment.center,
                    child: _ChipStyleButton(
                      label: 'Aceitar',
                      onTap: onAccept,
                      enabled: true,
                      primary: AppColors.success(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: 0.75,
                    alignment: Alignment.center,
                    child: _ChipStyleButton(
                      label: 'Reagendar',
                      onTap: onReschedule,
                      enabled: true,
                      primary: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: 0.75,
                    alignment: Alignment.center,
                    child: _ChipStyleButton(
                      label: 'Recusar',
                      onTap: onReject,
                      enabled: true,
                      primary: AppColors.error(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
