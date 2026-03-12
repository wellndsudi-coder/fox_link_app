import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:fox_link_app/core/auth/session_manager.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/utils/date_formatter.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/layout/layout_breakpoints.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';

import '../../../professionals/domain/usecases/get_professionals_by_service_usecase.dart';
import '../../../services/domain/usecases/get_services.dart';
import '../../../services/domain/usecases/get_addons_for_base_service_usecase.dart';
import '../../../services/domain/entities/service.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/create_appointment_usecase.dart';
import '../../domain/usecases/get_available_slots_usecase.dart';
import '../controllers/schedule_controller.dart';
import '../widgets/step_progress_indicator.dart';
import '../widgets/base_service_selector.dart';
import '../widgets/addon_selector.dart';
import '../widgets/professional_selector.dart';
import '../widgets/time_grid.dart';
import '../widgets/schedule_summary.dart';
import '../widgets/schedule_loading_skeleton.dart';
import 'package:fox_link_app/shared/widgets/app_button.dart';

class CreateAppointmentPage extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? initialSlot;
  final String? initialProfessionalId;
  final String? initialServiceId;
  final String? initialProfessionalName;
  final bool embeddedInShell;
  final VoidCallback? onSuccess;
  /// Fechar/cancelar o fluxo (ex: voltar ao dashboard quando embedded).
  final VoidCallback? onCancel;

  const CreateAppointmentPage({
    super.key,
    this.initialDate,
    this.initialSlot,
    this.initialProfessionalId,
    this.initialServiceId,
    this.initialProfessionalName,
    this.embeddedInShell = false,
    this.onSuccess,
    this.onCancel,
  });

  @override
  State<CreateAppointmentPage> createState() => _CreateAppointmentPageState();
}

class _CreateAppointmentPageState extends State<CreateAppointmentPage> {
  final _createUseCase = GetIt.I<CreateAppointmentUseCase>();
  final _slotsUseCase = GetIt.I<GetAvailableSlotsUseCase>();
  final _getServices = GetIt.I<GetServices>();
  final _getAddons = GetIt.I<GetAddonsForBaseServiceUseCase>();
  final _getProfessionalsByService = GetIt.I<GetProfessionalsByServiceUseCase>();
  final _tenantSession = GetIt.I<TenantSession>();
  final _sessionManager = GetIt.I<SessionManager>();

  late ScheduleController _controller;
  DateTime _focusedMonth = DateTime.now();
  int _viewIndex = 2; // 1=Semana, 2=Mês
  List<Service> _services = [];
  List<Service> _addons = [];
  List<Map<String, dynamic>> _professionals = [];
  bool _initialLoad = true;
  int _stepIndex = 0; // 0 = Prof+Services, 1 = Date+Time

  @override
  void initState() {
    super.initState();
    _controller = ScheduleController();
    _controller.setSelectedDate(widget.initialDate);
    _controller.setSelectedTime(widget.initialSlot);
    _controller.setSelectedProfessional(
      widget.initialProfessionalId,
      widget.initialProfessionalName,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    var tenantId = _tenantSession.tenantId;
    if (tenantId == null) {
      final refreshed = await _sessionManager.validateSessionForWeb();
      tenantId = refreshed ? _tenantSession.tenantId : null;
    }
    if (tenantId == null) {
      setState(() => _initialLoad = false);
      return;
    }

    try {
      _services = await _getServices(tenantId);
      _addons = [];
      if (widget.initialServiceId != null) {
        final svc = _services.where((s) => s.id == widget.initialServiceId).firstOrNull;
        if (svc != null) {
          _controller.setBaseService(svc);
        }
      }
      if (_controller.baseService != null) {
        _addons = await _getAddons(tenantId, _controller.baseService!.id);
        _professionals = await _getProfessionalsByService(_controller.baseService!.id);
        if (_professionals.isNotEmpty && widget.initialProfessionalId == null) {
          final first = _professionals.first;
          _controller.setSelectedProfessional(
            first['id'] as String?,
            first['name'] as String?,
          );
        }
      } else {
        _professionals = [];
      }
    } catch (_) {
      _professionals = [];
    }

    final hasInitialData = widget.initialServiceId != null &&
        widget.initialDate != null &&
        widget.initialSlot != null &&
        widget.initialProfessionalId != null;
    setState(() {
      _initialLoad = false;
      if (hasInitialData && _controller.baseService != null) {
        _stepIndex = 1;
        if (widget.initialDate != null) {
          _focusedMonth = widget.initialDate!;
        }
      }
    });
    if (hasInitialData && _controller.baseService != null) {
      await _loadSlots();
    }
  }

  Future<void> _loadSlots() async {
    final services = _controller.selectedServices;
    final profId = _controller.selectedProfessionalId;
    final date = _controller.selectedDate;

    if (services.isEmpty || profId == null || date == null) {
      _controller.setAvailableSlots([]);
      return;
    }

    final totalMinutes =
        services.fold(0, (sum, s) => sum + s.baseDuration.minutes);

    _controller.setLoadingSlots(true);
    try {
      final slots = await _slotsUseCase(
        professionalId: profId,
        date: date,
        durationMinutes: totalMinutes,
      );
      _controller.setAvailableSlots(slots);
    } catch (_) {
      _controller.setAvailableSlots([]);
    }
    _controller.setLoadingSlots(false);
  }

  Future<void> _onEncaixe() async {
    final baseService = _controller.baseService;
    final addons = _controller.selectedAddons;
    final profId = _controller.selectedProfessionalId;

    if (baseService == null || profId == null) {
      _showError('Selecione o serviço e o profissional para usar encaixe.');
      return;
    }

    _controller.setSubmitting(true);

    try {
      final totalDuration = _controller.totalDurationMinutes;
      final totalPrice = _controller.totalPrice;

      DateTime? firstSlot;
      var date = DateTime.now();
      final endDate = date.add(const Duration(days: 14));

      while (date.isBefore(endDate)) {
        final slots = await _slotsUseCase(
          professionalId: profId,
          date: date,
          durationMinutes: totalDuration,
        );
        if (slots.isNotEmpty) {
          firstSlot = slots.first;
          break;
        }
        date = date.add(const Duration(days: 1));
      }

      if (firstSlot == null) {
        _showError('Nenhum horário disponível nos próximos dias para encaixe.');
        _controller.setSubmitting(false);
        return;
      }

      final appointment = Appointment(
        id: const Uuid().v4(),
        tenantId: _tenantSession.tenantId!,
        serviceId: baseService.id,
        baseServiceId: baseService.id,
        selectedAddonIds: addons.map((s) => s.id).toList(),
        clientId: _tenantSession.uid!,
        professionalId: profId,
        scheduledStart: firstSlot,
        scheduledEnd: firstSlot.add(Duration(minutes: totalDuration)),
        finalPrice: totalPrice,
        finalDuration: totalDuration,
        status: AppointmentStatus.pending,
        createdAt: DateTime.now(),
        notes: 'Encaixe',
        initiatedBy: 'client',
      );

      await _createUseCase(appointment);

      if (mounted) {
        final serviceName = baseService.name.value;
        final profName = _getProfessionalName(profId) ?? 'Profissional';
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(ctx).colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                const Text('Encaixe realizado!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Profissional',
                  value: profName,
                  ctx: ctx,
                ),
                const SizedBox(height: 4),
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'Data',
                  value: AppDateFormatter.friendlyDate(firstSlot!),
                  ctx: ctx,
                ),
                const SizedBox(height: 4),
                _DetailRow(
                  icon: Icons.access_time,
                  label: 'Horário',
                  value: AppDateFormatter.friendlyTime(firstSlot),
                  ctx: ctx,
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Ok'),
              ),
            ],
          ),
        );
        if (mounted) {
          if (widget.embeddedInShell && widget.onSuccess != null) {
            widget.onSuccess!();
          } else {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      _showError(e.toString());
    }
    _controller.setSubmitting(false);
  }

  Future<void> _createAppointment() async {
    final baseService = _controller.baseService;
    final addons = _controller.selectedAddons;
    final profId = _controller.selectedProfessionalId;
    final date = _controller.selectedDate;
    final time = _controller.selectedTime;

    if (baseService == null || profId == null || date == null || time == null) {
      _showError('Preencha todos os campos.');
      return;
    }

    _controller.setSubmitting(true);

    try {
      final totalDuration = _controller.totalDurationMinutes;
      final totalPrice = _controller.totalPrice;
      final appointment = Appointment(
        id: const Uuid().v4(),
        tenantId: _tenantSession.tenantId!,
        serviceId: baseService.id,
        baseServiceId: baseService.id,
        selectedAddonIds: addons.map((s) => s.id).toList(),
        clientId: _tenantSession.uid!,
        professionalId: profId,
        scheduledStart: time,
        scheduledEnd: time.add(Duration(minutes: totalDuration)),
        finalPrice: totalPrice,
        finalDuration: totalDuration,
        status: AppointmentStatus.pending,
        createdAt: DateTime.now(),
        initiatedBy: 'client',
      );
      await _createUseCase(appointment);
      if (mounted) {
        final serviceName = baseService.name.value;
        final profName = _getProfessionalName(profId) ?? 'Profissional';
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(ctx).colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                const Text('Agendamento enviado!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Profissional',
                  value: profName,
                  ctx: ctx,
                ),
                const SizedBox(height: 4),
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'Data',
                  value: AppDateFormatter.friendlyDate(time),
                  ctx: ctx,
                ),
                const SizedBox(height: 4),
                _DetailRow(
                  icon: Icons.access_time,
                  label: 'Horário',
                  value: AppDateFormatter.friendlyTime(time),
                  ctx: ctx,
                ),
                const SizedBox(height: 4),
                _DetailRow(
                  icon: Icons.timer_outlined,
                  label: 'Duração',
                  value: AppDateFormatter.friendlyDuration(totalDuration),
                  ctx: ctx,
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Ok'),
              ),
            ],
          ),
        );
        if (mounted) {
          if (widget.embeddedInShell && widget.onSuccess != null) {
            widget.onSuccess!();
          } else {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      _showError(e.toString());
    }
    _controller.setSubmitting(false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _getProfessionalName(String? id) {
    if (id == null) return null;
    try {
      return _professionals.firstWhere((p) => p['id'] == id)['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  void _onContinue() {
    setState(() => _stepIndex = 1);
    if (_controller.selectedDate == null) {
      _controller.setSelectedDate(DateTime.now());
    }
    _loadSlots();
  }

  void _onBack() {
    setState(() => _stepIndex = 0);
  }

  /// Semana começa no domingo (igual agenda do profissional)
  DateTime _weekStart(DateTime date) {
    final daysSinceSunday = date.weekday == 7 ? 0 : date.weekday;
    return date.subtract(Duration(days: daysSinceSunday));
  }

  static const _dayLabels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  Future<void> _onDaySelected(DateTime day, ScheduleController ctrl) async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    if (day.isBefore(today)) return;
    setState(() {
      _focusedMonth = day;
      ctrl.setSelectedDate(day);
    });
    await _loadSlots();
  }

  Widget _buildMonthCalendar(ScheduleController ctrl) {
    final monthStart = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final calendarStart = _weekStart(monthStart);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final weeks = ((lastDay.difference(calendarStart).inDays + 1) / 7).ceil().clamp(4, 6);
    const colWidth = FlexColumnWidth(1);

    return Container(
      color: AppColors.card(context),
      padding: const EdgeInsets.all(12),
      child: Table(
        columnWidths: {for (var i = 0; i < 7; i++) i: colWidth},
        children: [
          TableRow(
            children: List.generate(7, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: Text(
                  _dayLabels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground(context),
                  ),
                ),
              ),
            )),
          ),
          ...List.generate(weeks, (weekIndex) {
            return TableRow(
              children: List.generate(7, (dayIndex) {
                final day = calendarStart.add(
                  Duration(days: weekIndex * 7 + dayIndex),
                );
                final isCurrentMonth = day.month == _focusedMonth.month;
                final isSelected = ctrl.selectedDate != null &&
                    DateUtils.isSameDay(day, ctrl.selectedDate!);
                final isToday = DateUtils.isSameDay(day, DateTime.now());
                final today = DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                );
                final isDisabled = day.isBefore(today);

                return GestureDetector(
                  onTap: isDisabled ? null : () => _onDaySelected(day, ctrl),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary(context) : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: AppColors.primary(context), width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      day.day.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.card(context)
                            : isCurrentMonth
                                ? (isDisabled
                                    ? AppColors.mutedForeground(context).withValues(alpha: 0.6)
                                    : AppColors.textPrimary(context))
                                : AppColors.mutedForeground(context),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeekRow(ScheduleController ctrl) {
    final weekStart = _weekStart(_focusedMonth);

    return Container(
      color: AppColors.card(context),
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final day = weekStart.add(Duration(days: index));
          final isSelected = ctrl.selectedDate != null &&
              DateUtils.isSameDay(day, ctrl.selectedDate!);
          final today = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          );
          final isDisabled = day.isBefore(today);

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isDisabled ? null : () => _onDaySelected(day, ctrl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayLabels[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary(context)
                          : AppColors.mutedForeground(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary(context)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      day.day.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.card(context)
                            : AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmbeddedHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border(context)),
        ),
      ),
      child: Row(
        children: [
          if (_stepIndex == 1)
            OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Voltar'),
              onPressed: _onBack,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            )
          else
            const SizedBox.shrink(),
          const Spacer(),
          if (widget.onCancel != null)
            OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Fechar'),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Column(
        children: [
          if (widget.embeddedInShell) _buildEmbeddedHeader(),
          Expanded(
            child: _initialLoad
                ? const ScheduleLoadingSkeleton()
                : IndexedStack(
                    index: _stepIndex,
                    children: [
                      _buildStep1ProfAndServices(),
                      _buildStep2DateAndTime(),
                    ],
                  ),
          ),
          Consumer<ScheduleController>(
            builder: (context, ctrl, _) {
              if (_stepIndex == 0) {
                return _buildStickyContinueButton(ctrl);
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScheduleSummary(
                    services: ctrl.selectedServices,
                    professionalName: ctrl.selectedProfessionalName,
                    date: ctrl.selectedDate,
                    time: ctrl.selectedTime,
                    compact: true,
                    totalDurationMinutes: ctrl.totalDurationMinutes,
                    totalPrice: ctrl.totalPrice,
                  ),
                  _buildEncaixeButton(ctrl),
                  _buildStickyConfirmButton(ctrl),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep1ProfAndServices() {
    return SingleChildScrollView(
      padding: LayoutBreakpoints.pagePadding(context),
      child: Consumer<ScheduleController>(
        builder: (context, ctrl, _) {
          final baseServices = _services.where((s) => s.isBase && s.isActive).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StepProgressIndicator(
                hasProfessional: ctrl.selectedProfessionalId != null,
                hasServices: ctrl.baseService != null,
                hasDate: false,
                hasTime: false,
              ),
              const SizedBox(height: 28),
              _sectionTitle('Serviço base'),
              const SizedBox(height: 12),
              if (baseServices.isEmpty)
                _EmptyStateCard(
                  icon: Icons.spa_rounded,
                  message: 'Nenhum serviço disponível no momento.',
                )
              else
                BaseServiceSelector(
                  baseServices: baseServices,
                  selectedBase: ctrl.baseService,
                  onSelected: (s) async {
                    ctrl.setBaseService(s);
                    final tenantId = _tenantSession.tenantId;
                    if (tenantId != null) {
                      _addons = await _getAddons(tenantId, s.id);
                      _professionals = await _getProfessionalsByService(s.id);
                      final currentProfId = ctrl.selectedProfessionalId;
                      final profIds = _professionals.map((p) => p['id'] as String?).toSet();
                      if (currentProfId != null && !profIds.contains(currentProfId)) {
                        ctrl.setSelectedProfessional(null, null);
                      } else if (_professionals.isNotEmpty && ctrl.selectedProfessionalId == null) {
                        final first = _professionals.first;
                        ctrl.setSelectedProfessional(
                          first['id'] as String?,
                          first['name'] as String?,
                        );
                      }
                      setState(() {});
                    }
                  },
                ),
              if (ctrl.baseService != null) ...[
                const SizedBox(height: 28),
                _sectionTitle('Add-ons (opcional)'),
                const SizedBox(height: 12),
                AddonSelector(
                  addons: _addons,
                  selectedAddons: ctrl.selectedAddons,
                  onToggle: ctrl.toggleAddon,
                  totalDurationMinutes: ctrl.totalDurationMinutes,
                  totalPrice: ctrl.totalPrice,
                ),
              ],
              const SizedBox(height: 28),
              _sectionTitle('Profissional'),
              const SizedBox(height: 12),
              if (_professionals.isEmpty)
                _EmptyStateCard(
                  icon: Icons.person_rounded,
                  message: ctrl.baseService != null
                      ? 'Nenhum profissional oferece este serviço.'
                      : 'Selecione um serviço para ver os profissionais.',
                )
              else
                ProfessionalSelector(
                  selectedProfessionalId: ctrl.selectedProfessionalId,
                  professionals: _professionals,
                  onChanged: (v) {
                    ctrl.setSelectedProfessional(v, _getProfessionalName(v));
                  },
                ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStep2DateAndTime() {
    return SingleChildScrollView(
      padding: LayoutBreakpoints.pagePadding(context),
      child: Consumer<ScheduleController>(
        builder: (context, ctrl, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StepProgressIndicator(
                hasProfessional: ctrl.selectedProfessionalId != null,
                hasServices: ctrl.selectedServices.isNotEmpty,
                hasDate: ctrl.selectedDate != null,
                hasTime: ctrl.selectedTime != null,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _ViewChip(
                      label: 'Hoje',
                      selected: ctrl.selectedDate != null &&
                          DateUtils.isSameDay(ctrl.selectedDate!, DateTime.now()),
                      onTap: () {
                        final today = DateTime.now();
                        setState(() {
                          _focusedMonth = today;
                          ctrl.setSelectedDate(today);
                        });
                        _loadSlots();
                      },
                    ),
                    const SizedBox(width: 8),
                    _ViewChip(
                      label: 'Semana',
                      selected: _viewIndex == 1,
                      onTap: () => setState(() => _viewIndex = 1),
                    ),
                    const SizedBox(width: 8),
                    _ViewChip(
                      label: 'Mês',
                      selected: _viewIndex == 2,
                      onTap: () => setState(() => _viewIndex = 2),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: AppColors.card(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          if (_viewIndex == 1) {
                            _focusedMonth = _focusedMonth.subtract(const Duration(days: 7));
                          } else {
                            final d = _focusedMonth;
                            _focusedMonth = DateTime(d.year, d.month - 1, d.day.clamp(1, 28));
                          }
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                    Text(
                      DateFormat.yMMMM('pt_BR').format(_focusedMonth),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          if (_viewIndex == 1) {
                            _focusedMonth = _focusedMonth.add(const Duration(days: 7));
                          } else {
                            final d = _focusedMonth;
                            _focusedMonth = DateTime(d.year, d.month + 1, d.day.clamp(1, 28));
                          }
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ],
                ),
              ),
              if (_viewIndex == 2)
                _buildMonthCalendar(ctrl)
              else
                _buildWeekRow(ctrl),
              const SizedBox(height: 24),
              _sectionTitle('Horário disponível'),
              const SizedBox(height: 12),
              TimeGrid(
                slots: ctrl.availableSlots,
                selectedSlot: ctrl.selectedTime,
                onSelected: (v) => ctrl.setSelectedTime(v),
                isLoading: ctrl.loadingSlots,
              ),
              const SizedBox(height: 28),
              ScheduleSummary(
                services: ctrl.selectedServices,
                professionalName: ctrl.selectedProfessionalName,
                date: ctrl.selectedDate,
                time: ctrl.selectedTime,
                totalDurationMinutes: ctrl.totalDurationMinutes,
                totalPrice: ctrl.totalPrice,
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStickyContinueButton(ScheduleController ctrl) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: AppButton(
        text: 'Continuar',
        onPressed: ctrl.canContinue ? _onContinue : null,
      ),
    );
  }

  Widget _buildEncaixeButton(ScheduleController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
      child: OutlinedButton.icon(
        onPressed: !ctrl.submitting ? _onEncaixe : null,
        icon: ctrl.submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.schedule, size: 18),
        label: Text(ctrl.submitting ? 'Buscando horário...' : 'Tentar um Encaixe'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
        ),
      ),
    );
  }

  Widget _buildStickyConfirmButton(ScheduleController ctrl) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: AppButton(
        text: 'Confirmar agendamento',
        onPressed:
            ctrl.canConfirm && !ctrl.submitting ? _createAppointment : null,
        isLoading: ctrl.submitting,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.mutedForeground(context),
            letterSpacing: 0.5,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInShell) {
      return _buildContent();
    }
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Novo agendamento',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: _stepIndex == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _onBack,
              )
            : null,
      ),
      body: _buildContent(),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final BuildContext ctx;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.mutedForeground(ctx)),
        const SizedBox(width: 10),
        Text('$label: ', style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground(ctx))),
        Expanded(
          child: Text(value, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _ViewChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(
            color: selected ? AppColors.primary(context) : AppColors.border(context),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? AppColors.primary(context)
                : AppColors.mutedForeground(context),
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyStateCard({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: AppColors.mutedForeground(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
