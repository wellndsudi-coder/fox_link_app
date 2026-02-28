import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/session/tenant_session.dart';
import '../../domain/entities/availability.dart';
import '../../domain/usecases/save_availability.dart';
import '../../domain/usecases/get_professional_availability.dart';
import '../../domain/usecases/copy_week_availability_usecase.dart';
import 'monthly_availability_page.dart';

class ProfessionalAvailabilityPage extends StatefulWidget {
  const ProfessionalAvailabilityPage({super.key});

  @override
  State<ProfessionalAvailabilityPage> createState() =>
      _ProfessionalAvailabilityPageState();
}

class _ProfessionalAvailabilityPageState
    extends State<ProfessionalAvailabilityPage> {

  final _session = GetIt.I<TenantSession>();
  final _saveUseCase = GetIt.I<SaveAvailability>();
  final _getUseCase = GetIt.I<GetProfessionalAvailability>();
  final _copyUseCase = GetIt.I<CopyWeekAvailabilityUseCase>();

  int selectedWeekday = 1;
  bool isActive = false;
  List<TimeRange> shifts = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final professionalId = _session.uid!;
    final all = await _getUseCase(professionalId);

    final existing =
    all.where((a) => a.weekday == selectedWeekday);

    if (existing.isNotEmpty) {
      final data = existing.first;
      setState(() {
        isActive = data.isActive;
        shifts = List.from(data.shifts);
      });
    } else {
      setState(() {
        isActive = false;
        shifts = [];
      });
    }
  }

  Future<void> _save() async {

    if (isActive && shifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Dia ativo precisa ter ao menos um turno."),
        ),
      );
      return;
    }

    setState(() => loading = true);

    final availability = Availability(
      id: '${_session.uid}_$selectedWeekday',
      professionalId: _session.uid!,
      weekday: selectedWeekday,
      isActive: isActive,
      shifts: shifts,
    );

    try {
      await _saveUseCase(availability);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Disponibilidade salva!"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => loading = false);
  }

  Future<void> _copyWeek() async {
    setState(() => loading = true);

    await _copyUseCase(
      professionalId: _session.uid!,
      sourceWeekday: selectedWeekday,
    );

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copiado para toda a semana!"),
      ),
    );
  }

  void _removeShift(int index) {
    setState(() {
      shifts.removeAt(index);
    });
  }

  String _weekdayLabel(int weekday) {
    const labels = [
      "Segunda",
      "Terça",
      "Quarta",
      "Quinta",
      "Sexta",
      "Sábado",
      "Domingo"
    ];
    return labels[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Disponibilidade"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const MonthlyAvailabilityPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [

          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _weekdayLabel(selectedWeekday),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch(
                      value: isActive,
                      onChanged: (v) {
                        setState(() => isActive = v);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                DropdownButton<int>(
                  value: selectedWeekday,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                        value: 1,
                        child: Text("Segunda")),
                    DropdownMenuItem(
                        value: 2,
                        child: Text("Terça")),
                    DropdownMenuItem(
                        value: 3,
                        child: Text("Quarta")),
                    DropdownMenuItem(
                        value: 4,
                        child: Text("Quinta")),
                    DropdownMenuItem(
                        value: 5,
                        child: Text("Sexta")),
                    DropdownMenuItem(
                        value: 6,
                        child: Text("Sábado")),
                    DropdownMenuItem(
                        value: 7,
                        child: Text("Domingo")),
                  ],
                  onChanged: (v) async {
                    setState(() => selectedWeekday = v!);
                    await _loadAvailability();
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: shifts.isEmpty
                ? const Center(
              child: Text(
                  "Nenhum turno configurado"),
            )
                : ListView.builder(
              itemCount: shifts.length,
              itemBuilder: (context, index) {
                final shift = shifts[index];

                return ListTile(
                  title: Text(
                    "${shift.startMinutes ~/ 60}:00 - ${shift.endMinutes ~/ 60}:00",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete,
                        color: Colors.red),
                    onPressed: () =>
                        _removeShift(index),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _save,
                  child: const Text(
                      "Salvar disponibilidade"),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _copyWeek,
                  child: const Text(
                      "Copiar para semana inteira"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}