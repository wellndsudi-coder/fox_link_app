import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import '../../domain/entities/availability.dart';
import '../../domain/usecases/save_availability.dart';

class ProfessionalAvailabilityPage extends StatefulWidget {
  const ProfessionalAvailabilityPage({super.key});

  @override
  State<ProfessionalAvailabilityPage> createState() =>
      _ProfessionalAvailabilityPageState();
}

class _ProfessionalAvailabilityPageState
    extends State<ProfessionalAvailabilityPage> {

  final _saveUseCase =
  GetIt.I<SaveAvailability>();

  final _session =
  GetIt.I<TenantSession>();

  int selectedWeekday = 1;

  TimeOfDay startTime =
  const TimeOfDay(hour: 8, minute: 0);

  TimeOfDay endTime =
  const TimeOfDay(hour: 18, minute: 0);

  TimeOfDay? breakStart;
  TimeOfDay? breakEnd;

  bool loading = false;

  int _toMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  Future<void> _save() async {
    setState(() => loading = true);

    final availability = Availability(
      id: const Uuid().v4(),
      professionalId: _session.uid!,
      weekday: selectedWeekday,
      startMinutes: _toMinutes(startTime),
      endMinutes: _toMinutes(endTime),
      breakStartMinutes:
      breakStart != null
          ? _toMinutes(breakStart!)
          : null,
      breakEndMinutes:
      breakEnd != null
          ? _toMinutes(breakEnd!)
          : null,
    );

    try {
      await _saveUseCase(availability);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text("Disponibilidade salva!"),
          ),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title:
        const Text("Minha Agenda de Trabalho"),
      ),
      body: Padding(
        padding:
        const EdgeInsets.all(16),
        child: ListView(
          children: [

            const Text(
              "Dia da Semana",
              style: TextStyle(
                  fontWeight:
                  FontWeight.bold),
            ),

            DropdownButton<int>(
              value: selectedWeekday,
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
              onChanged: (value) {
                setState(() =>
                selectedWeekday = value!);
              },
            ),

            const SizedBox(height: 20),

            _timePicker(
              "Horário Início",
              startTime,
                  (time) => setState(
                      () => startTime = time),
            ),

            _timePicker(
              "Horário Fim",
              endTime,
                  (time) =>
                  setState(() => endTime = time),
            ),

            const SizedBox(height: 20),

            const Text(
              "Intervalo (opcional)",
              style: TextStyle(
                  fontWeight:
                  FontWeight.bold),
            ),

            _timePicker(
              "Início Intervalo",
              breakStart,
                  (time) => setState(
                      () => breakStart = time),
            ),

            _timePicker(
              "Fim Intervalo",
              breakEnd,
                  (time) =>
                  setState(() => breakEnd = time),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed:
              loading ? null : _save,
              child: loading
                  ? const CircularProgressIndicator(
                color: Colors.white,
              )
                  : const Text(
                  "Salvar Disponibilidade"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timePicker(
      String label,
      TimeOfDay? value,
      Function(TimeOfDay) onChanged,
      ) {
    return ListTile(
      title: Text(label),
      subtitle:
      Text(value?.format(context) ??
          "Selecionar"),
      trailing:
      const Icon(Icons.access_time),
      onTap: () async {
        final time =
        await showTimePicker(
          context: context,
          initialTime:
          value ?? TimeOfDay.now(),
        );

        if (time != null) {
          onChanged(time);
        }
      },
    );
  }
}