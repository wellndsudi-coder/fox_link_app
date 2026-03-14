import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/layout/layout_breakpoints.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';

import '../../../services/domain/usecases/get_services.dart';
import '../../../services/domain/usecases/get_addons_for_base_service_usecase.dart';
import '../../../services/domain/entities/service.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/create_appointment_usecase.dart';
import '../../domain/usecases/get_available_slots_usecase.dart';
import '../controllers/schedule_controller.dart';
import '../widgets/base_service_selector.dart';
import '../widgets/addon_selector.dart';
import '../widgets/date_carousel.dart';
import '../widgets/time_grid.dart';
import '../widgets/schedule_summary.dart';
import '../widgets/schedule_loading_skeleton.dart';
import 'package:fox_link_app/shared/widgets/app_button.dart';

/// Profissional cria agendamento para um cliente específico.
class CreateAppointmentForClientPage extends StatefulWidget {
  final String clientId;
  final String clientName;
  final DateTime? initialDate;
  final DateTime? initialSlot;

  const CreateAppointmentForClientPage({
    super.key,
    required this.clientId,
    required this.clientName,
    this.initialDate,
    this.initialSlot,
  });

  @override
  State<CreateAppointmentForClientPage> createState() =>
      _CreateAppointmentForClientPageState();
}

class _CreateAppointmentForClientPageState
    extends State<CreateAppointmentForClientPage> {
  final _createUseCase = GetIt.I<CreateAppointmentUseCase>();
  final _slotsUseCase = GetIt.I<GetAvailableSlotsUseCase>();
  final _getServices = GetIt.I<GetServices>();
  final _getAddons = GetIt.I<GetAddonsForBaseServiceUseCase>();
  final _tenantSession = GetIt.I<TenantSession>();

  late ScheduleController _controller;
  List<Service> _services = [];
  List<Service> _addons = [];
  bool _initialLoad = true;
  int _stepIndex = 0; // 0 = Service, 1 = Date+Time

  @override
  void initState() {
    super.initState();
    _controller = ScheduleController();
    _controller.setSelectedDate(widget.initialDate ?? DateTime.now());
    _controller.setSelectedTime(widget.initialSlot);
    _controller.setSelectedProfessional(
      _tenantSession.professionalId,
      null,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final tenantId = _tenantSession.tenantId;
    final profId = _tenantSession.professionalId;
    if (tenantId == null || profId == null) {
      setState(() => _initialLoad = false);
      return;
    }

    try {
      _services = await _getServices(tenantId);
      if (_controller.baseService != null) {
        _addons = await _getAddons(tenantId, _controller.baseService!.id);
      } else {
        _addons = [];
      }
    } catch (_) {
      _addons = [];
    }
    setState(() => _initialLoad = false);
  }

  Future<void> _loadSlots() async {
    final services = _controller.selectedServices;
    final profId = _tenantSession.professionalId;
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

  Future<void> _createAppointment() async {
    final baseService = _controller.baseService;
    final profId = _tenantSession.professionalId;
    final tenantId = _tenantSession.tenantId;
    final date = _controller.selectedDate;
    final time = _controller.selectedTime;

    if (baseService == null || profId == null || tenantId == null ||
        date == null || time == null) {
      _showError('Preencha todos os campos.');
      return;
    }

    _controller.setSubmitting(true);

    try {
      final addons = _controller.selectedAddons;
      final totalDuration = _controller.totalDurationMinutes;
      final totalPrice = _controller.totalPrice;
      final appointment = Appointment(
        id: const Uuid().v4(),
        tenantId: tenantId,
        serviceId: baseService.id,
        baseServiceId: baseService.id,
        selectedAddonIds: addons.map((s) => s.id).toList(),
        clientId: widget.clientId,
        professionalId: profId,
        scheduledStart: time,
        scheduledEnd: time.add(Duration(minutes: totalDuration)),
        finalPrice: totalPrice,
        finalDuration: totalDuration,
        status: AppointmentStatus.pending,
        createdAt: DateTime.now(),
        initiatedBy: 'professional',
      );
      await _createUseCase(appointment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Agendamento criado para ${widget.clientName}')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError(e.toString());
    }
    _controller.setSubmitting(false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onContinue() {
    setState(() => _stepIndex = 1);
    if (_controller.selectedDate == null) {
      _controller.setSelectedDate(DateTime.now());
    }
    _loadSlots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Agendar para ${widget.clientName}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ChangeNotifierProvider.value(
        value: _controller,
        child: Column(
          children: [
            Expanded(
              child: _initialLoad
                  ? const ScheduleLoadingSkeleton()
                  : IndexedStack(
                      index: _stepIndex,
                      children: [
                        _buildStep1Service(),
                        _buildStep2DateAndTime(),
                      ],
                    ),
            ),
            Consumer<ScheduleController>(
              builder: (context, ctrl, _) {
                if (_stepIndex == 0) {
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
                          color: Theme.of(context)
                              .colorScheme
                              .shadow
                              .withValues(alpha: 0.08),
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
                        color: Theme.of(context)
                            .colorScheme
                            .shadow
                            .withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScheduleSummary(
                        services: ctrl.selectedServices,
                        professionalName: null,
                        date: ctrl.selectedDate,
                        time: ctrl.selectedTime,
                        compact: true,
                        totalDurationMinutes: ctrl.totalDurationMinutes,
                        totalPrice: ctrl.totalPrice,
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        text: 'Confirmar agendamento',
                        onPressed: ctrl.canConfirm && !ctrl.submitting
                            ? _createAppointment
                            : null,
                        isLoading: ctrl.submitting,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Service() {
    return SingleChildScrollView(
      padding: LayoutBreakpoints.pagePadding(context),
      child: Consumer<ScheduleController>(
        builder: (context, ctrl, _) {
          final baseServices =
              _services.where((s) => s.isBase && s.isActive).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _sectionTitle('Serviço'),
              const SizedBox(height: 12),
              if (baseServices.isEmpty)
                _EmptyState(
                  message: 'Nenhum serviço disponível.',
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
                      setState(() {});
                    }
                  },
                ),
              if (ctrl.baseService != null) ...[
                const SizedBox(height: 24),
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
              const SizedBox(height: 8),
              _sectionTitle('Data'),
              const SizedBox(height: 12),
              DateCarousel(
                selectedDate: ctrl.selectedDate,
                onDateSelected: (date) async {
                  ctrl.setSelectedDate(date);
                  await _loadSlots();
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: ctrl.selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (picked != null) {
                    ctrl.setSelectedDate(picked);
                    await _loadSlots();
                  }
                },
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text('Ver calendário completo'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Horário'),
              const SizedBox(height: 12),
              TimeGrid(
                slots: ctrl.availableSlots,
                selectedSlot: ctrl.selectedTime,
                onSelected: (v) => ctrl.setSelectedTime(v),
                isLoading: ctrl.loadingSlots,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: ctrl.selectedDate == null
                    ? null
                    : () async {
                        final date = ctrl.selectedDate!;
                        final isToday = date.year == DateTime.now().year &&
                            date.month == DateTime.now().month &&
                            date.day == DateTime.now().day;
                        final initial = isToday
                            ? TimeOfDay.now()
                            : const TimeOfDay(hour: 9, minute: 0);
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: initial,
                        );
                        if (picked != null) {
                          final combined = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            picked.hour,
                            picked.minute,
                          );
                          ctrl.setSelectedTime(combined);
                        }
                      },
                icon: const Icon(Icons.schedule, size: 18),
                label: const Text('Definir horário manualmente'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
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
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.spa_rounded,
              size: 32, color: AppColors.mutedForeground(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedForeground(context),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
