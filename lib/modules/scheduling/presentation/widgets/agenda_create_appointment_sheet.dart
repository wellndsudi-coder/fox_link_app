import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/utils/date_formatter.dart';
import 'package:fox_link_app/modules/services/domain/entities/service.dart';
import 'package:fox_link_app/modules/services/domain/usecases/get_services.dart';
import 'package:fox_link_app/modules/services/domain/usecases/get_addons_for_base_service_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/create_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_clients_by_professional_usecase.dart';
import 'package:fox_link_app/modules/scheduling/presentation/controllers/schedule_controller.dart';
import 'package:fox_link_app/modules/scheduling/presentation/widgets/base_service_selector.dart';
import 'package:fox_link_app/modules/scheduling/presentation/widgets/addon_selector.dart';
import 'package:intl/intl.dart';
import 'package:fox_link_app/shared/widgets/app_button.dart';

/// Sheet para criar agendamento direto na agenda: cliente + serviço, sem trocar de página.
class AgendaCreateAppointmentSheet extends StatefulWidget {
  final DateTime date;
  final DateTime slot;
  final String professionalId;
  final String? initialClientId;
  final String? initialClientName;
  final VoidCallback? onSuccess;

  const AgendaCreateAppointmentSheet({
    super.key,
    required this.date,
    required this.slot,
    required this.professionalId,
    this.initialClientId,
    this.initialClientName,
    this.onSuccess,
  });

  @override
  State<AgendaCreateAppointmentSheet> createState() =>
      _AgendaCreateAppointmentSheetState();
}

class _AgendaCreateAppointmentSheetState
    extends State<AgendaCreateAppointmentSheet> {
  final _createUseCase = GetIt.I<CreateAppointmentUseCase>();
  final _getServices = GetIt.I<GetServices>();
  final _getAddons = GetIt.I<GetAddonsForBaseServiceUseCase>();
  final _getClients = GetIt.I<GetClientsByProfessionalUseCase>();
  final _tenantSession = GetIt.I<TenantSession>();

  late ScheduleController _controller;
  List<ClientDisplay> _clients = [];
  List<Service> _services = [];
  List<Service> _addons = [];
  ClientDisplay? _selectedClient;
  bool _loading = true;
  bool _submitting = false;
  late DateTime _effectiveSlot;

  @override
  void initState() {
    super.initState();
    _effectiveSlot = widget.slot;
    _controller = ScheduleController();
    _controller.setSelectedDate(widget.date);
    _controller.setSelectedTime(widget.slot);
    _controller.setSelectedProfessional(widget.professionalId, null);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final tenantId = _tenantSession.tenantId;
      if (tenantId == null) return;

      var clients = await _getClients(widget.professionalId);
      final services = await _getServices(tenantId);

      ClientDisplay? initialClient;
      if (widget.initialClientId != null && widget.initialClientName != null) {
        try {
          initialClient = clients.firstWhere((c) => c.id == widget.initialClientId);
        } catch (_) {
          initialClient = ClientDisplay(
            id: widget.initialClientId!,
            name: widget.initialClientName!,
          );
          clients = [initialClient, ...clients];
        }
      }

      setState(() {
        _clients = clients;
        _services = services.where((s) => s.isBase && s.isActive).toList();
        _selectedClient = initialClient;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _onServiceSelected(Service s) async {
    _controller.setBaseService(s);
    _controller.setSelectedTime(_effectiveSlot);
    final tenantId = _tenantSession.tenantId;
    if (tenantId == null) return;
    final addons = await _getAddons(tenantId, s.id);
    setState(() => _addons = addons);
  }

  Future<void> _create() async {
    final client = _selectedClient;
    final baseService = _controller.baseService;
    final tenantId = _tenantSession.tenantId;
    final time = _controller.selectedTime;

    if (client == null || baseService == null || tenantId == null || time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione cliente e serviço.')),
      );
      return;
    }

    setState(() => _submitting = true);
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
        clientId: client.id,
        professionalId: widget.professionalId,
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
          SnackBar(content: Text('Agendamento criado para ${client.name}')),
        );
        Navigator.pop(context, true);
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        final isConflict = msg.contains('conflito') ||
            msg.contains('ocupado') ||
            msg.contains('agendamento nesse horário');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isConflict
                  ? 'Horário em conflito com outro agendamento. Escolha outro horário.'
                  : (msg.startsWith('Exception: ') ? msg.substring(11) : msg),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openClientSelector() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Selecionar cliente',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Procurar cliente'),
                subtitle: Text(
                  'Clientes que usam o app',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground(context),
                  ),
                ),
                onTap: () => Navigator.pop(ctx, 'search'),
              ),
              ListTile(
                leading: const Icon(Icons.person_add_outlined),
                title: const Text('Inserir nome do cliente'),
                subtitle: Text(
                  'Cliente sem o app',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground(context),
                  ),
                ),
                onTap: () => Navigator.pop(ctx, 'insert'),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == 'search' && context.mounted) {
      await _showSearchClientSheet();
    } else if (choice == 'insert' && context.mounted) {
      await _showInsertClientNameSheet();
    }
  }

  Future<void> _showSearchClientSheet() async {
    final searchController = TextEditingController();
    List<ClientDisplay> filtered = List.from(_clients);

    final selected = await showModalBottomSheet<ClientDisplay>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) {
          void filter() {
            final q = searchController.text.toLowerCase().trim();
            setModalState(() {
              filtered = q.isEmpty
                  ? List.from(_clients)
                  : _clients.where((c) => c.name.toLowerCase().contains(q)).toList();
            });
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollController) => Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Procurar cliente',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: AppColors.fillColor(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (_) => filter(),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              _clients.isEmpty
                                  ? 'Nenhum cliente cadastrado. Use "Inserir nome do cliente" para agendar quem não tem o app.'
                                  : 'Nenhum resultado encontrado.',
                              style: TextStyle(
                                color: AppColors.mutedForeground(context),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final c = filtered[i];
                              return ListTile(
                                title: Text(c.name),
                                onTap: () => Navigator.pop(ctx, c),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (selected != null && mounted) {
      setState(() => _selectedClient = selected);
    }
  }

  Future<void> _showInsertClientNameSheet() async {
    final nameController = TextEditingController();

    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Inserir nome do cliente',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Para clientes que não usam o app',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground(context),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nome do cliente',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              text: 'Confirmar',
              onPressed: () {
                final n = nameController.text.trim();
                if (n.isNotEmpty) Navigator.pop(ctx, n);
              },
            ),
          ],
        ),
      ),
    );

    if (name != null && name.isNotEmpty && mounted) {
      final guestClient = ClientDisplay(
        id: 'guest:$name',
        name: name,
      );
      setState(() => _selectedClient = guestClient);
    }
  }

  void _onDateSelected(DateTime date) {
    final hour = _effectiveSlot.hour;
    final minute = _effectiveSlot.minute;
    _effectiveSlot = DateTime(date.year, date.month, date.day, hour, minute);
    _controller.setSelectedDate(date);
    _controller.setSelectedTime(_effectiveSlot);
    setState(() {});
  }

  Future<void> _pickFullCalendar() async {
    final date = _controller.selectedDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      _onDateSelected(picked);
    }
  }

  Future<void> _pickExtraTime() async {
    final date = _controller.selectedDate!;
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;
    final initial = isToday
        ? TimeOfDay.fromDateTime(widget.slot)
        : TimeOfDay(hour: widget.slot.hour, minute: widget.slot.minute);
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
      _effectiveSlot = combined;
      _controller.setSelectedTime(combined);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, __) => Center(child: CircularProgressIndicator()),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return ChangeNotifierProvider.value(
          value: _controller,
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Agendar cliente',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Data',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedForeground(context),
                      ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickFullCalendar,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.fillColor(context),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 20, color: AppColors.primary(context)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            DateFormat("EEEE, d 'de' MMMM 'de' yyyy", 'pt_BR')
                                .format(_controller.selectedDate ?? _effectiveSlot),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.mutedForeground(context)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.fillColor(context),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppDateFormatter.friendlyTime(_effectiveSlot),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          Text(
                            'Horário',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedForeground(context),
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _pickExtraTime,
                        icon: const Icon(Icons.schedule, size: 18),
                        label: const Text('Horário extra'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Cliente',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedForeground(context),
                      ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _openClientSelector,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border(context)),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedClient?.name ?? 'Selecione o cliente',
                            style: TextStyle(
                              color: _selectedClient != null
                                  ? AppColors.textPrimary(context)
                                  : AppColors.mutedForeground(context),
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.mutedForeground(context)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Consumer<ScheduleController>(
                  builder: (context, ctrl, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Serviço',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.mutedForeground(context),
                              ),
                        ),
                        const SizedBox(height: 12),
                        if (_services.isEmpty)
                          Text(
                            'Nenhum serviço disponível.',
                            style: TextStyle(
                              color: AppColors.mutedForeground(context),
                            ),
                          )
                        else
                          BaseServiceSelector(
                            baseServices: _services,
                            selectedBase: ctrl.baseService,
                            onSelected: _onServiceSelected,
                          ),
                        if (ctrl.baseService != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Add-ons (opcional)',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mutedForeground(context),
                                ),
                          ),
                          const SizedBox(height: 8),
                          AddonSelector(
                            addons: _addons,
                            selectedAddons: ctrl.selectedAddons,
                            onToggle: (s) {
                              ctrl.toggleAddon(s);
                              ctrl.setSelectedTime(_effectiveSlot);
                            },
                            totalDurationMinutes: ctrl.totalDurationMinutes,
                            totalPrice: ctrl.totalPrice,
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Consumer<ScheduleController>(
                  builder: (context, ctrl, _) {
                    final canConfirm = _selectedClient != null &&
                        ctrl.baseService != null &&
                        ctrl.selectedTime != null;
                    return AppButton(
                      text: 'Confirmar agendamento',
                      onPressed:
                          canConfirm && !_submitting ? _create : null,
                      isLoading: _submitting,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
