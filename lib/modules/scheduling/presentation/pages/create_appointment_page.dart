import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';

import '../../../professionals/infra/datasources/professional_remote_datasource.dart';
import '../../../services/domain/usecases/get_services.dart';
import '../../../services/domain/entities/service.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/create_appointment_usecase.dart';
import '../../domain/usecases/get_available_slots_usecase.dart';

class CreateAppointmentPage extends StatefulWidget {
  const CreateAppointmentPage({super.key});

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

      if (list.length == 1) {
        selectedProfessionalId =
        list.first['id'];
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

      if (slots.isEmpty) {
        throw Exception(
            "Nenhum horário disponível.");
      }

      setState(() {
        availableSlots = slots;
        selectedSlot = null;
      });

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(content: Text(e.toString())),
      );

      setState(() {
        availableSlots = [];
      });
    }
  }

  Future<void> _createAppointment() async {

    if (selectedSlot == null ||
        selectedProfessionalId == null ||
        selectedService == null) return;

    setState(() => loading = true);

    final appointment = Appointment(
      id: const Uuid().v4(),
      tenantId:
      _tenantSession.tenantId!,
      serviceId:
      selectedService!.id,
      clientId:
      _tenantSession.uid!,
      professionalId:
      selectedProfessionalId!,
      scheduledStart:
      selectedSlot!,
      scheduledEnd:
      selectedSlot!.add(
        Duration(
          minutes:
          selectedService!
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

        Navigator.pop(context);
      }

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
      const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor:
        const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          "Novo Agendamento",
          style:
          TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding:
        const EdgeInsets.all(20),
        child: Column(
          children: [

            _card(
              DropdownButton<Service>(
                dropdownColor:
                const Color(0xFF1E293B),
                value: selectedService,
                hint: const Text(
                  "Selecione o serviço",
                  style: TextStyle(
                      color:
                      Colors.white70),
                ),
                isExpanded: true,
                style: const TextStyle(
                    color: Colors.white),
                items:
                services.map((service) {
                  return DropdownMenuItem<Service>(
                    value: service,
                    child: Text(
                      "${service.name.value} - ${service.baseDuration.minutes}min",
                      style: const TextStyle(
                          color:
                          Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedService =
                        value;
                    availableSlots = [];
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            if (professionals.length > 1)
              _card(
                DropdownButton<String>(
                  dropdownColor:
                  const Color(
                      0xFF1E293B),
                  value:
                  selectedProfessionalId,
                  hint: const Text(
                    "Selecione o profissional",
                    style: TextStyle(
                        color:
                        Colors.white70),
                  ),
                  isExpanded: true,
                  style: const TextStyle(
                      color: Colors.white),
                  items:
                  professionals.map((prof) {
                    return DropdownMenuItem<String>(
                      value: prof['id'],
                      child: Text(
                        prof['name'],
                        style: const TextStyle(
                            color:
                            Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedProfessionalId =
                          value;
                      availableSlots = [];
                    });
                  },
                ),
              ),

            const SizedBox(height: 16),

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

            const SizedBox(height: 16),

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
                            ? const Color(
                            0xFF3B82F6)
                            : const Color(
                            0xFF1E293B),
                        borderRadius:
                        BorderRadius
                            .circular(
                            14),
                      ),
                      child: ListTile(
                        title: Text(
                          "${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(
                              color:
                              Colors
                                  .white),
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

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                loading
                    ? null
                    : _createAppointment,
                child: loading
                    ? const CircularProgressIndicator(
                  color:
                  Colors.white,
                )
                    : const Text(
                    "Confirmar Agendamento"),
              ),
            ),
          ],
        ),
      ),
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
        const Color(0xFF1E293B),
        borderRadius:
        BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}