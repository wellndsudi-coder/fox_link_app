import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/session/tenant_session.dart';
import '../../../../core/database/tenant_firestore.dart';
import '../../domain/entities/availability.dart';
import '../../domain/usecases/save_availability.dart';
import '../../domain/usecases/get_professional_availability.dart';
import '../../domain/usecases/copy_week_availability_usecase.dart';
import '../widgets/working_hours_bar.dart';

class ProfessionalAvailabilityPage extends StatefulWidget {
  const ProfessionalAvailabilityPage({super.key});

  @override
  State<ProfessionalAvailabilityPage> createState() =>
      _ProfessionalAvailabilityPageState();
}

class _ProfessionalAvailabilityPageState
    extends State<ProfessionalAvailabilityPage> {

  final _session = GetIt.I<TenantSession>();
  final _firestore = GetIt.I<TenantFirestore>();
  final _saveUseCase = GetIt.I<SaveAvailability>();
  final _getUseCase = GetIt.I<GetProfessionalAvailability>();
  final _copyUseCase = GetIt.I<CopyWeekAvailabilityUseCase>();

  final List<String> weekLabels = [
    "SEG", "TER", "QUA", "QUI", "SEX", "SAB", "DOM"
  ];

  String? _professionalDocId;

  int selectedWeekday = 1;
  List<TimeRange> shifts = [];
  int slotIntervalMinutes = 0;

  Set<int> configuredDays = {};

  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _resolveProfessionalId();
    await _refreshConfiguredDays();
    await _loadAvailability();
  }

  Future<void> _resolveProfessionalId() async {
    final snapshot = await _firestore
        .collection('professionals')
        .where('email', isEqualTo: _session.email)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      _professionalDocId = snapshot.docs.first.id;
    }
  }

  Future<void> _refreshConfiguredDays() async {
    if (_professionalDocId == null) return;

    final all = await _getUseCase(_professionalDocId!);

    configuredDays = all
        .where((a) => a.isActive && a.shifts.isNotEmpty)
        .map((a) => a.weekday)
        .toSet();

    setState(() {});
  }

  Future<void> _loadAvailability() async {
    if (_professionalDocId == null) return;

    final all = await _getUseCase(_professionalDocId!);

    final existing =
    all.where((a) => a.weekday == selectedWeekday);

    if (existing.isNotEmpty) {
      final data = existing.first;

      setState(() {
        shifts = List.from(data.shifts);
        slotIntervalMinutes = data.slotIntervalMinutes;
      });
    } else {
      setState(() {
        shifts = [];
        slotIntervalMinutes = 0;
      });
    }
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();

    _autoSaveTimer = Timer(
      const Duration(milliseconds: 600),
          () async {
        if (_professionalDocId == null) return;

        final availability = Availability(
          id: '${_professionalDocId}_$selectedWeekday',
          professionalId: _professionalDocId!,
          weekday: selectedWeekday,
          isActive: shifts.isNotEmpty,
          shifts: shifts,
          slotIntervalMinutes: slotIntervalMinutes,
          breakTimes: const [],
        );

        await _saveUseCase(availability);
        await _refreshConfiguredDays();
      },
    );
  }

  Future<void> _changeDay(int weekday) async {
    setState(() => selectedWeekday = weekday);
    await _loadAvailability();
  }

  Future<void> _copyToWholeWeek() async {
    if (_professionalDocId == null) return;

    await _copyUseCase(
      professionalId: _professionalDocId!,
      sourceWeekday: selectedWeekday,
    );

    await _refreshConfiguredDays();
    await _loadAvailability();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copiado para toda a semana!")),
    );
  }

  // ===========================
  // LIMPAR DIAS
  // ===========================

  Future<void> _openClearDays() async {
    final selectedDays = <int>{};

    await showModalBottomSheet(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const Text(
                    "Selecionar dias para limpar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (index) {
                      final day = index + 1;

                      return FilterChip(
                        label: Text(weekLabels[index]),
                        selected: selectedDays.contains(day),
                        onSelected: (value) {
                          setModalState(() {
                            value
                                ? selectedDays.add(day)
                                : selectedDays.remove(day);
                          });
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red),
                    onPressed: () async {

                      for (final weekday in selectedDays) {

                        final availability = Availability(
                          id: '${_professionalDocId}_$weekday',
                          professionalId: _professionalDocId!,
                          weekday: weekday,
                          isActive: false,
                          shifts: const [],
                          slotIntervalMinutes: 0,
                          breakTimes: const [],
                        );

                        await _saveUseCase(availability);
                      }

                      Navigator.pop(context);
                      await _refreshConfiguredDays();
                      await _loadAvailability();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Dias limpos")),
                      );
                    },
                    child: const Text("Limpar selecionados"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================
  // MODO INTELIGENTE COMPLETO
  // ===========================

  Future<void> _openSmartMode() async {

    final selectedDays = <int>{};

    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);

    bool hasLunch = false;
    TimeOfDay lunchStart = const TimeOfDay(hour: 12, minute: 0);
    TimeOfDay lunchEnd = const TimeOfDay(hour: 13, minute: 0);

    int interval = slotIntervalMinutes;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [

                    const Text(
                      "Modo Inteligente",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 8,
                      children: List.generate(7, (index) {
                        final day = index + 1;

                        return FilterChip(
                          label: Text(weekLabels[index]),
                          selected: selectedDays.contains(day),
                          onSelected: (value) {
                            setModalState(() {
                              value
                                  ? selectedDays.add(day)
                                  : selectedDays.remove(day);
                            });
                          },
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    ListTile(
                      title: const Text("Início"),
                      trailing: Text(startTime.format(context)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (picked != null) {
                          setModalState(() => startTime = picked);
                        }
                      },
                    ),

                    ListTile(
                      title: const Text("Fim"),
                      trailing: Text(endTime.format(context)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (picked != null) {
                          setModalState(() => endTime = picked);
                        }
                      },
                    ),

                    SwitchListTile(
                      title: const Text("Ativar almoço"),
                      value: hasLunch,
                      onChanged: (value) {
                        setModalState(() => hasLunch = value);
                      },
                    ),

                    if (hasLunch) ...[
                      ListTile(
                        title: const Text("Almoço início"),
                        trailing: Text(lunchStart.format(context)),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: lunchStart,
                          );
                          if (picked != null) {
                            setModalState(() => lunchStart = picked);
                          }
                        },
                      ),
                      ListTile(
                        title: const Text("Almoço fim"),
                        trailing: Text(lunchEnd.format(context)),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: lunchEnd,
                          );
                          if (picked != null) {
                            setModalState(() => lunchEnd = picked);
                          }
                        },
                      ),
                    ],

                    const SizedBox(height: 10),

                    const Text("Intervalo entre clientes"),

                    Slider(
                      value: interval.toDouble(),
                      min: 0,
                      max: 30,
                      divisions: 30,
                      label: "$interval min",
                      onChanged: (value) {
                        setModalState(() {
                          interval = value.round();
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: () async {

                        if (selectedDays.isEmpty) return;

                        final all =
                        await _getUseCase(_professionalDocId!);

                        for (final weekday in selectedDays) {

                          final exists =
                          all.any((a) => a.weekday == weekday);

                          if (exists) {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Substituir dia?"),
                                content: Text(
                                    "O dia ${weekLabels[weekday - 1]} já possui configuração."),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Cancelar"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text("Substituir"),
                                  ),
                                ],
                              ),
                            );

                            if (confirm != true) continue;
                          }

                          final startMinutes =
                              startTime.hour * 60 + startTime.minute;
                          final endMinutes =
                              endTime.hour * 60 + endTime.minute;

                          final List<TimeRange> generated = [];

                          if (hasLunch) {
                            final lunchStartMin =
                                lunchStart.hour * 60 + lunchStart.minute;
                            final lunchEndMin =
                                lunchEnd.hour * 60 + lunchEnd.minute;

                            generated.add(TimeRange(
                                startMinutes: startMinutes,
                                endMinutes: lunchStartMin));

                            generated.add(TimeRange(
                                startMinutes: lunchEndMin,
                                endMinutes: endMinutes));
                          } else {
                            generated.add(TimeRange(
                                startMinutes: startMinutes,
                                endMinutes: endMinutes));
                          }

                          final availability = Availability(
                            id:
                            '${_professionalDocId}_$weekday',
                            professionalId:
                            _professionalDocId!,
                            weekday: weekday,
                            isActive: true,
                            shifts: generated,
                            slotIntervalMinutes: interval,
                            breakTimes: const [],
                          );

                          await _saveUseCase(availability);
                        }

                        Navigator.pop(context);
                        await _refreshConfiguredDays();
                        await _loadAvailability();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                              Text("Agenda gerada com sucesso")),
                        );
                      },
                      child: const Text("Gerar agenda"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: const Text("Horarios De Atendimento")),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(7, (index) {
                final weekday = index + 1;
                final isSelected =
                    weekday == selectedWeekday;
                final isConfigured =
                configuredDays.contains(weekday);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _changeDay(weekday),
                    child: Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue
                                : Colors.grey.shade200,
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              weekLabels[index],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        if (isConfigured)
                          const Positioned(
                            right: 4,
                            top: 4,
                            child: Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                          )
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  WorkingHoursBar(
                    shifts: shifts,
                    onChanged: (updated) {
                      setState(() => shifts = updated);
                      _scheduleAutoSave();
                    },
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [

                      Expanded(
                        child: _softBlueButton(
                          icon: Icons.copy_rounded,
                          label: "Copiar",
                          onTap: _copyToWholeWeek,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: _softBlueButton(
                          icon: Icons.flash_on_rounded,
                          label: "Inteligente",
                          onTap: _openSmartMode,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: _softBlueButton(
                          icon: Icons.delete_outline_rounded,
                          label: "Limpar",
                          onTap: _openClearDays,
                        ),
                      ),
                    ],
                  ),





                  const SizedBox(height: 30),

                  const Text(
                    "Intervalo entre clientes",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  Text(
                    "$slotIntervalMinutes min",
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),

                  Slider(
                    value: slotIntervalMinutes.toDouble(),
                    min: 0,
                    max: 30,
                    divisions: 30,
                    onChanged: (value) {
                      setState(
                              () => slotIntervalMinutes = value.round());
                      _scheduleAutoSave();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _softBlueButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.withOpacity(0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.blue),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}