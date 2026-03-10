import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
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
import '../widgets/date_carousel.dart';
import '../widgets/time_grid.dart';
import '../widgets/schedule_summary.dart';
import '../widgets/schedule_loading_skeleton.dart';
import 'package:fox_link_app/shared/widgets/app_button.dart';

class CreateAppointmentPage extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? initialSlot;
  final String? initialProfessionalId;
  final bool embeddedInShell;
  final VoidCallback? onSuccess;
  /// Fechar/cancelar o fluxo (ex: voltar ao dashboard quando embedded).
  final VoidCallback? onCancel;

  const CreateAppointmentPage({
    super.key,
    this.initialDate,
    this.initialSlot,
    this.initialProfessionalId,
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

  late ScheduleController _controller;
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
    _controller.setSelectedProfessional(widget.initialProfessionalId, null);
    _loadData();
  }

  Future<void> _loadData() async {
    final tenantId = _tenantSession.tenantId;
    if (tenantId == null) {
      setState(() => _initialLoad = false);
      return;
    }

    try {
      _services = await _getServices(tenantId);
      _addons = [];
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

    setState(() => _initialLoad = false);
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
      );
      await _createUseCase(appointment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agendamento enviado!')),
        );
        if (widget.embeddedInShell && widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          Navigator.pop(context);
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
              const SizedBox(height: 28),
              _sectionTitle('Data'),
              const SizedBox(height: 12),
              DateCarousel(
                selectedDate: ctrl.selectedDate,
                onDateSelected: (date) async {
                  ctrl.setSelectedDate(date);
                  await _loadSlots();
                },
              ),
              const SizedBox(height: 28),
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
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Continuar',
              onPressed: ctrl.canContinue ? _onContinue : null,
            ),
        ),
        ],
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
