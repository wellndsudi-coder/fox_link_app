import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/session/tenant_session.dart';
import '../../domain/entities/availability.dart';
import '../../domain/entities/daily_override.dart';
import '../../domain/entities/blocked_date.dart';
import '../../domain/repositories/availability_repository.dart';

class DailyAvailabilityPage extends StatefulWidget {
  final DateTime date;

  const DailyAvailabilityPage({
    super.key,
    required this.date,
  });

  @override
  State<DailyAvailabilityPage> createState() =>
      _DailyAvailabilityPageState();
}

class _DailyAvailabilityPageState
    extends State<DailyAvailabilityPage> {

  final _session = GetIt.I<TenantSession>();
  final _repository =
  GetIt.I<AvailabilityRepository>();

  bool isBlocked = false;
  List<TimeRange> shifts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {

    final professionalId = _session.uid!;
    final weekday = widget.date.weekday;

    final weekly =
    await _repository.getWeeklyAvailabilityByWeekday(
      professionalId: professionalId,
      weekday: weekday,
    );

    final override =
    await _repository.getDailyOverride(
      professionalId: professionalId,
      date: widget.date,
    );

    final blocked =
    await _repository.getBlockedDate(
      professionalId: professionalId,
      date: widget.date,
    );

    if (blocked != null) {
      isBlocked = true;
      shifts = [];
    } else if (override != null) {
      shifts = [
        TimeRange(
          startMinutes: override.startMinutes,
          endMinutes: override.endMinutes,
        )
      ];
    } else if (weekly != null && weekly.isActive) {
      shifts = weekly.shifts;
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> _saveOverride() async {

    final professionalId = _session.uid!;

    if (isBlocked) {
      await _repository.saveBlockedDate(
        BlockedDate(
          id: '${professionalId}_${widget.date.toIso8601String()}',
          professionalId: professionalId,
          date: widget.date,
        ),
      );
      Navigator.pop(context);
      return;
    }

    if (shifts.isNotEmpty) {
      final shift = shifts.first;

      await _repository.saveDailyOverride(
        DailyOverride(
          id: '${professionalId}_${widget.date.toIso8601String()}',
          professionalId: professionalId,
          date: widget.date,
          shifts: [shift],
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.date.day}/${widget.date.month}/${widget.date.year}",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            SwitchListTile(
              title: const Text("Bloquear dia"),
              value: isBlocked,
              onChanged: (v) {
                setState(() {
                  isBlocked = v;
                  if (v) shifts = [];
                });
              },
            ),

            const SizedBox(height: 16),

            if (!isBlocked)
              shifts.isEmpty
                  ? const Text(
                "Sem turnos configurados",
              )
                  : Column(
                children: shifts.map((shift) {
                  return Text(
                    "${shift.startMinutes ~/ 60}:00 - ${shift.endMinutes ~/ 60}:00",
                  );
                }).toList(),
              ),

            const Spacer(),

            ElevatedButton(
              onPressed: _saveOverride,
              child: const Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }
}