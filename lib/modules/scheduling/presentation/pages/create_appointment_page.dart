import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';

import '../../../professionals/infra/datasources/professional_remote_datasource.dart';
import '../../../services/domain/usecases/get_services.dart';
import '../../../services/domain/entities/service.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/create_appointment_usecase.dart';
import '../../domain/usecases/get_available_slots_usecase.dart';

class CreateAppointmentPage extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? initialSlot;
  final String? initialProfessionalId;
  final bool embeddedInShell;
  final VoidCallback? onSuccess;

  const CreateAppointmentPage({
    super.key,
    this.initialDate,
    this.initialSlot,
    this.initialProfessionalId,
    this.embeddedInShell = false,
    this.onSuccess,
  });

  @override
  State<CreateAppointmentPage> createState() =>
      _CreateAppointmentPageState();
}

class _CreateAppointmentPageState
    extends State<CreateAppointmentPage> {

  final _createUseCase =
  GetIt.I<CreateAppointmentUseCase>();

  final _slotsUseCase =
  GetIt.I<GetAvailableSlotsUseCase>();

  final _professionalRepo =
  GetIt.I<ProfessionalRemoteDataSource>();

  final _getServices =
  GetIt.I<GetServices>();

  final _tenantSession =
  GetIt.I<TenantSession>();

  DateTime? selectedDate;
  List<DateTime> availableSlots = [];
  DateTime? selectedSlot;

  List<Map<String, dynamic>> professionals = [];
  String? selectedProfessionalId;

  List<Service> services = [];
  Service? selectedService;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    selectedSlot = widget.initialSlot;
    selectedProfessionalId = widget.initialProfessionalId;
    _loadProfessionals();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final list =
    await _getServices(_tenantSession.tenantId!);

    setState(() {
      services = list;
    });
  }

  Future<void> _loadProfessionals() async {
    final list =
    await _professionalRepo.getProfessionals();

    setState(() {
      professionals = list;
      if (list.isNotEmpty && selectedProfessionalId == null) {
        selectedProfessionalId = list.first['id'];
      }
    });
  }

  Future<void> _loadSlots() async {

    if (selectedDate == null ||
        selectedProfessionalId == null ||
        selectedService == null) return;

    try {

      final slots =
      await _slotsUseCase(
        professionalId:
        selectedProfessionalId!,
        date: selectedDate!,
        durationMinutes:
        selectedService!
            .baseDuration
            .minutes,
      );

      setState(() {
        availableSlots = slots;
        selectedSlot = null;
      });

      if (slots.isEmpty) {
        _showError("Nenhum horário disponível.");
      }

    } catch (e) {

      _showError(e.toString());

      setState(() {
        availableSlots = [];
      });
    }
  }

  Future<void> _createAppointment() async {

    if (selectedProfessionalId == null) {
      _showError("Selecione o profissional.");
      return;
    }

    if (selectedService == null) {
      _showError("Selecione o serviço.");
      return;
    }

    if (selectedDate == null) {
      _showError("Selecione a data.");
      return;
    }

    if (selectedSlot == null) {
      _showError("Selecione um horário.");
      return;
    }

    setState(() => loading = true);

    final appointment = Appointment(
      id: const Uuid().v4(),
      tenantId: _tenantSession.tenantId!,
      serviceId: selectedService!.id,
      clientId: _tenantSession.uid!,
      professionalId: selectedProfessionalId!,
      scheduledStart: selectedSlot!,
      scheduledEnd: selectedSlot!.add(
        Duration(
          minutes: selectedService!
              .baseDuration
              .minutes,
        ),
      ),
      finalPrice:
      selectedService!
          .basePrice
          .value,
      finalDuration:
      selectedService!
          .baseDuration
          .minutes,
      status:
      AppointmentStatus.pending,
      createdAt:
      DateTime.now(),
    );

    try {

      await _createUseCase(appointment);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content:
            Text("Agendamento enviado!"),
          ),
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

    setState(() => loading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildContent() {
    return Padding(
        padding:
        const EdgeInsets.all(20),
        child: Column(
          children: [

            /// SERVIÇO
            _card(
              DropdownButton<Service>(
                dropdownColor:
                AppColors.card(context),
                value: selectedService,
                hint: Text(
                  "Selecione o serviço",
                  style: TextStyle(
                      color:
                      AppColors.mutedForeground(context)),
                ),
                isExpanded: true,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary),
                items:
                services.map((service) {
                  return DropdownMenuItem<Service>(
                    value: service,
                    child: Text(
                      "${service.name.value} - ${service.baseDuration.minutes}min",
                      style: TextStyle(
                          color:
                          Theme.of(context).colorScheme.onPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (value) async {
                  setState(() {
                    selectedService =
                        value;
                    selectedSlot = null;
                  });
                  await _loadSlots();
                },
              ),
            ),

            const SizedBox(height: 16),

            /// PROFISSIONAL (AGORA SEMPRE VISÍVEL)
            _card(
              DropdownButton<String>(
                dropdownColor:
                AppColors.card(context),
                value:
                selectedProfessionalId,
                hint: Text(
                  "Selecione o profissional",
                  style: TextStyle(
                      color:
                      AppColors.mutedForeground(context)),
                ),
                isExpanded: true,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary),
                items:
                professionals.map((prof) {
                  return DropdownMenuItem<String>(
                    value: prof['id'],
                    child: Text(
                      prof['name'],
                      style: TextStyle(
                          color:
                          Theme.of(context).colorScheme.onPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (value) async {
                  setState(() {
                    selectedProfessionalId =
                        value;
                    selectedSlot = null;
                  });
                  await _loadSlots();
                },
              ),
            ),

            const SizedBox(height: 16),

            /// DATA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {

                  final date =
                  await showDatePicker(
                    context: context,
                    firstDate:
                    DateTime.now(),
                    lastDate:
                    DateTime(2100),
                  );

                  if (date != null) {
                    setState(() =>
                    selectedDate =
                        date);

                    await _loadSlots();
                  }
                },
                child: const Text(
                    "Selecionar Data"),
              ),
            ),

            if (selectedDate != null)
              Padding(
                padding:
                const EdgeInsets.only(
                    top: 8),
                child: Text(
                  "Data selecionada: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                  style: TextStyle(
                      color:
                      AppColors.mutedForeground(context)),
                ),
              ),

            const SizedBox(height: 16),

            /// SLOTS
            if (availableSlots.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount:
                  availableSlots.length,
                  itemBuilder:
                      (_, index) {

                    final slot =
                    availableSlots[index];

                    final isSelected =
                        selectedSlot ==
                            slot;

                    return Container(
                      margin:
                      const EdgeInsets
                          .only(
                          bottom:
                          10),
                      decoration:
                      BoxDecoration(
                        color: isSelected
                            ? AppColors.primary(context)
                            : AppColors.card(context),
                        borderRadius:
                        BorderRadius
                            .circular(
                            14),
                      ),
                      child: ListTile(
                        title: Text(
                          "${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(
                              color:
                              Theme.of(context).colorScheme.onPrimary),
                        ),
                        onTap: () {
                          setState(() {
                            selectedSlot =
                                slot;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),

            /// CONFIRMAR
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                loading
                    ? null
                    : _createAppointment,
                child: loading
                    ? CircularProgressIndicator(
                  color:
                  Theme.of(context).colorScheme.onPrimary,
                )
                    : const Text(
                    "Confirmar Agendamento"),
              ),
            ),
          ],
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
        backgroundColor: AppColors.card(context),
        elevation: 0,
        title: Text(
          "Novo Agendamento",
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6),
      decoration: BoxDecoration(
        color:
        AppColors.card(context),
        borderRadius:
        BorderRadius.circular(
            14),
      ),
      child: child,
    );
  }
}