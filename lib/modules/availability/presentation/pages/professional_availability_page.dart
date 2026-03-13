import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/session/tenant_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/database/tenant_firestore.dart';
import '../../../professionals/infra/datasources/professional_remote_datasource.dart';
import '../../../tenant/domain/entities/tenant_config.dart';
import '../../../tenant/domain/usecases/get_tenant_config_usecase.dart';
import '../../../scheduling/domain/entities/manual_block.dart';
import '../../../scheduling/domain/usecases/save_manual_block_usecase.dart';
import '../../../scheduling/domain/usecases/delete_manual_block_usecase.dart';
import '../../../scheduling/domain/usecases/get_manual_blocks_by_period_usecase.dart';
import '../../domain/entities/blocked_date.dart';
import '../../domain/entities/daily_override.dart';
import '../../domain/entities/availability.dart';
import '../../domain/repositories/availability_repository.dart';

class ProfessionalAvailabilityPage extends StatefulWidget {
  final String? professionalIdOverride;

  const ProfessionalAvailabilityPage({super.key, this.professionalIdOverride});

  @override
  State<ProfessionalAvailabilityPage> createState() =>
      _ProfessionalAvailabilityPageState();
}

class _ProfessionalAvailabilityPageState
    extends State<ProfessionalAvailabilityPage> {
  final _session = GetIt.I<TenantSession>();
  final _firestore = GetIt.I<TenantFirestore>();
  final _professionalRemote = GetIt.I<ProfessionalRemoteDataSource>();
  final _getTenantConfig = GetIt.I<GetTenantConfigUseCase>();
  final _availabilityRepo = GetIt.I<AvailabilityRepository>();
  final _saveManualBlock = GetIt.I<SaveManualBlockUseCase>();
  final _deleteManualBlock = GetIt.I<DeleteManualBlockUseCase>();
  final _getManualBlocks = GetIt.I<GetManualBlocksByPeriodUseCase>();

  static const _dayLabelsFull = [
    'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'
  ];
  static const _dayLabelsShort = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  String? _professionalDocId;
  TenantConfig? _tenantConfig;
  DateTime _selectedDate = DateTime.now();

  BlockedDate? _blockedDate;
  List<ManualBlock> _manualBlocks = [];
  DailyOverride? _dailyOverride;

  bool _minLeadTimeEnabled = false;
  int _minLeadTimeMinutes = 30;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _resolveProfessionalId();
    await _loadTenantConfig();
    await _loadMinLeadTime();
    await _loadSelectedDateData();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMinLeadTime() async {
    if (_professionalDocId == null) return;
    final prof = await _professionalRemote.getProfessionalById(_professionalDocId!);
    if (prof == null) return;
    setState(() {
      _minLeadTimeEnabled = prof['minLeadTimeEnabled'] as bool? ?? false;
      _minLeadTimeMinutes = prof['minLeadTimeMinutes'] as int? ?? 30;
    });
  }

  Future<void> _saveMinLeadTime() async {
    if (_professionalDocId == null) return;
    await _professionalRemote.updateMinLeadTime(
      professionalId: _professionalDocId!,
      enabled: _minLeadTimeEnabled,
      minutes: _minLeadTimeMinutes,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tempo de antecedência salvo')),
      );
    }
  }

  Future<void> _resolveProfessionalId() async {
    if (widget.professionalIdOverride != null &&
        widget.professionalIdOverride!.isNotEmpty) {
      _professionalDocId = widget.professionalIdOverride;
      return;
    }
    if (_session.professionalId != null &&
        _session.professionalId!.isNotEmpty) {
      _professionalDocId = _session.professionalId;
      return;
    }
    final snapshot = await _firestore
        .collection('professionals')
        .where('email', isEqualTo: _session.email)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      _professionalDocId = snapshot.docs.first.id;
    }
  }

  Future<void> _loadTenantConfig() async {
    final tenantId = _session.tenantId;
    if (tenantId == null) return;
    _tenantConfig = await _getTenantConfig(tenantId);
  }

  Future<void> _loadSelectedDateData() async {
    if (_professionalDocId == null) return;

    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final end = start.add(const Duration(days: 1));

    _blockedDate = await _availabilityRepo.getBlockedDate(
      professionalId: _professionalDocId!,
      date: _selectedDate,
    );

    _manualBlocks = await _getManualBlocks(
      professionalId: _professionalDocId!,
      start: start,
      end: end,
    );

    _dailyOverride = await _availabilityRepo.getDailyOverride(
      professionalId: _professionalDocId!,
      date: _selectedDate,
    );
  }

  Future<void> _onDateSelected(DateTime day) async {
    setState(() {
      _selectedDate = day;
      _loading = true;
    });
    await _loadSelectedDateData();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _blockFullDay() async {
    if (_professionalDocId == null || _session.tenantId == null) return;

    final normDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final blockedId = '${_professionalDocId}_${normDate.toIso8601String()}';

    await _availabilityRepo.saveBlockedDate(
      BlockedDate(
        id: blockedId,
        professionalId: _professionalDocId!,
        date: normDate,
      ),
    );

    final overrideId = '${_professionalDocId}_${normDate.toIso8601String()}';
    await _availabilityRepo.removeDailyOverride(overrideId);

    await _loadSelectedDateData();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dia bloqueado')),
      );
    }
  }

  Future<void> _unblockFullDay() async {
    if (_blockedDate == null) return;

    await _availabilityRepo.removeBlockedDate(_blockedDate!.id);
    await _loadSelectedDateData();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bloqueio removido')),
      );
    }
  }

  Future<void> _openBlockTimeRangeModal() async {
    if (_professionalDocId == null || _session.tenantId == null) return;
    if (_blockedDate != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Desbloqueie o dia inteiro antes de bloquear horário')),
      );
      return;
    }

    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 12, minute: 0);

    final picked = await showDialog<(TimeOfDay, TimeOfDay)?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Bloquear horário'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Início'),
                trailing: Text(_formatTimeOfDay(startTime)),
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: startTime,
                  );
                  if (t != null) setModalState(() => startTime = t);
                },
              ),
              ListTile(
                title: const Text('Fim'),
                trailing: Text(_formatTimeOfDay(endTime)),
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: endTime,
                  );
                  if (t != null) setModalState(() => endTime = t);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (startTime.hour * 60 + startTime.minute >=
                    endTime.hour * 60 + endTime.minute) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Horário de fim deve ser após o início')),
                  );
                  return;
                }
                Navigator.pop(ctx, (startTime, endTime));
              },
              child: const Text('Bloquear'),
            ),
          ],
        ),
      ),
    );

    if (picked == null || !mounted) return;

    final normDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final start = DateTime(
      normDate.year,
      normDate.month,
      normDate.day,
      picked.$1.hour,
      picked.$1.minute,
    );
    final end = DateTime(
      normDate.year,
      normDate.month,
      normDate.day,
      picked.$2.hour,
      picked.$2.minute,
    );

    final block = ManualBlock(
      id: 'block_${const Uuid().v4()}',
      tenantId: _session.tenantId!,
      professionalId: _professionalDocId!,
      start: start,
      end: end,
      label: 'Bloqueio',
      type: ManualBlockType.custom,
    );

    await _saveManualBlock(block);
    await _loadSelectedDateData();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horário bloqueado')),
      );
    }
  }

  Future<void> _removeManualBlock(ManualBlock block) async {
    await _deleteManualBlock(block.id);
    await _loadSelectedDateData();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bloqueio removido')),
      );
    }
  }

  Future<void> _openAddExtraHoursModal() async {
    if (_professionalDocId == null || _tenantConfig == null) return;
    if (_blockedDate != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Desbloqueie o dia antes de adicionar horário extra')),
      );
      return;
    }

    final salonRanges = _tenantConfig!.getOpeningRangesMinutes(_selectedDate.weekday);
    final lastEnd = salonRanges.isEmpty
        ? 0
        : salonRanges.map((r) => r.end).reduce((a, b) => a > b ? a : b);
    final extraStartHour = lastEnd ~/ 60;
    final extraStartMin = lastEnd % 60;
    TimeOfDay startTime = TimeOfDay(hour: extraStartHour, minute: extraStartMin);
    TimeOfDay endTime = TimeOfDay(
      hour: (extraStartHour + 2).clamp(0, 23),
      minute: extraStartMin,
    );

    final picked = await showDialog<(TimeOfDay, TimeOfDay)?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Adicionar horário extra'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lastEnd > 0)
                Text(
                  'Horário além do funcionamento do salão (após ${_formatMinutes(lastEnd)}).',
                  style: Theme.of(ctx).textTheme.bodySmall,
                )
              else
                Text(
                  'Salão fechado neste dia. Adicione horário de atendimento.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Início'),
                trailing: Text(_formatTimeOfDay(startTime)),
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: startTime,
                  );
                  if (t != null) setModalState(() => startTime = t);
                },
              ),
              ListTile(
                title: const Text('Fim'),
                trailing: Text(_formatTimeOfDay(endTime)),
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: endTime,
                  );
                  if (t != null) setModalState(() => endTime = t);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (startTime.hour * 60 + startTime.minute >=
                    endTime.hour * 60 + endTime.minute) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Horário de fim deve ser após o início')),
                  );
                  return;
                }
                Navigator.pop(ctx, (startTime, endTime));
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );

    if (picked == null || !mounted) return;

    final normDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final extraStart = picked.$1.hour * 60 + picked.$1.minute;
    final extraEnd = picked.$2.hour * 60 + picked.$2.minute;

    final existingShifts = _dailyOverride?.shifts ??
        salonRanges
            .map((r) => TimeRange(startMinutes: r.start, endMinutes: r.end))
            .toList();

    final extraRange = TimeRange(startMinutes: extraStart, endMinutes: extraEnd);
    final allShifts = [...existingShifts, extraRange];
    allShifts.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    final overrideId = '${_professionalDocId}_${normDate.toIso8601String()}';
    await _availabilityRepo.saveDailyOverride(
      DailyOverride(
        id: overrideId,
        professionalId: _professionalDocId!,
        date: normDate,
        shifts: allShifts,
        slotIntervalMinutes: _dailyOverride?.slotIntervalMinutes ?? 30,
      ),
    );

    await _loadSelectedDateData();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horário extra adicionado')),
      );
    }
  }

  Future<void> _removeExtraShift(TimeRange? shiftToRemove) async {
    if (_dailyOverride == null || _professionalDocId == null) return;

    final salonRanges = _tenantConfig?.getOpeningRangesMinutes(_selectedDate.weekday) ?? [];
    final salonMax = salonRanges.isEmpty ? 0 : salonRanges.map((r) => r.end).reduce((a, b) => a > b ? a : b);
    final extraShifts = _dailyOverride!.shifts
        .where((s) => s.startMinutes >= salonMax || s.endMinutes > salonMax)
        .toList();

    List<TimeRange> newShifts;
    if (shiftToRemove != null && extraShifts.length > 1) {
      newShifts = _dailyOverride!.shifts
          .where((s) =>
              s.startMinutes != shiftToRemove.startMinutes ||
              s.endMinutes != shiftToRemove.endMinutes)
          .toList();
    } else {
      newShifts = salonRanges
          .map((r) => TimeRange(startMinutes: r.start, endMinutes: r.end))
          .toList();
    }

    final normDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final overrideId = '${_professionalDocId}_${normDate.toIso8601String()}';

    if (newShifts.isEmpty) {
      await _availabilityRepo.removeDailyOverride(overrideId);
    } else {
      await _availabilityRepo.saveDailyOverride(
        DailyOverride(
          id: overrideId,
          professionalId: _professionalDocId!,
          date: normDate,
          shifts: newShifts,
          slotIntervalMinutes: _dailyOverride!.slotIntervalMinutes,
        ),
      );
    }

    await _loadSelectedDateData();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horário removido')),
      );
    }
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatMinutes(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_professionalDocId == null) {
      return Center(
        child: Text(
          'Profissional não encontrado',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return Container(
      color: AppColors.background(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Horários de funcionamento',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            _buildSalonHoursCard(),
            const SizedBox(height: 12),
            _buildMinLeadTimeCard(),
            const SizedBox(height: 12),
            _buildCalendar(),
            const SizedBox(height: 12),
            _buildDayConfigurationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSalonHoursCard() {
    if (_tenantConfig == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          'Carregando horários do salão...',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
        ),
      );
    }

    final hours = _tenantConfig!.openingHours;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Horário fixo do salão',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedForeground(context),
                ),
          ),
          const SizedBox(height: 6),
          ...List.generate(7, (i) {
            final weekday = i + 1;
            final label = _dayLabelsShort[i];
            final ranges = hours[weekday] ?? [];
            final text = ranges.isEmpty
                ? 'Fechado'
                : ranges.map((r) => '${r.start}–${r.end}').join(', ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ranges.isEmpty
                              ? AppColors.mutedForeground(context)
                              : null,
                        ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMinLeadTimeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tempo de antecedência mínimo',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedForeground(context),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Impede cliente de agendar dentro desse tempo (ex: 30 min)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedForeground(context),
                          ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _minLeadTimeEnabled,
                onChanged: (v) async {
                  setState(() => _minLeadTimeEnabled = v);
                  await _saveMinLeadTime();
                },
              ),
            ],
          ),
          if (_minLeadTimeEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MinLeadTimeField(
                    label: 'Horas',
                    value: _minLeadTimeMinutes ~/ 60,
                    max: 24,
                    onChanged: (h) {
                      final m = _minLeadTimeMinutes % 60;
                      setState(() => _minLeadTimeMinutes = (h * 60 + m).clamp(0, 1440));
                      _saveMinLeadTime();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MinLeadTimeField(
                    label: 'Minutos',
                    value: _minLeadTimeMinutes % 60,
                    max: 59,
                    onChanged: (m) {
                      final h = _minLeadTimeMinutes ~/ 60;
                      setState(() => _minLeadTimeMinutes = (h * 60 + m).clamp(0, 1440));
                      _saveMinLeadTime();
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final monthStart = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final calendarStart = monthStart.subtract(
      Duration(days: (monthStart.weekday == 7 ? 0 : monthStart.weekday)),
    );
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final totalDays = lastDay.difference(calendarStart).inDays + 1;
    final weeks = (totalDays / 7).ceil().clamp(4, 6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () {
                  final d = _selectedDate;
                  _onDateSelected(DateTime(d.year, d.month - 1, d.day.clamp(1, 28)));
                },
              ),
              Text(
                DateFormat.yMMM('pt_BR').format(_selectedDate),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () {
                  final d = _selectedDate;
                  _onDateSelected(DateTime(d.year, d.month + 1, d.day.clamp(1, 28)));
                },
              ),
            ],
          ),
          Table(
            columnWidths: {for (var i = 0; i < 7; i++) i: const FlexColumnWidth(1)},
            children: [
              TableRow(
                children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Center(
                            child: Text(
                              c,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.mutedForeground(context),
                                    fontSize: 11,
                                  ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              ...List.generate(weeks, (wi) {
                return TableRow(
                  children: List.generate(7, (di) {
                    final day = calendarStart.add(
                      Duration(days: wi * 7 + di),
                    );
                    final isCurrentMonth = day.month == _selectedDate.month;
                    final isSelected = DateUtils.isSameDay(day, _selectedDate);
                    final isToday = DateUtils.isSameDay(day, DateTime.now());

                    return GestureDetector(
                      onTap: () => _onDateSelected(day),
                      child: Container(
                        margin: const EdgeInsets.all(1),
                        height: 30,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary(context)
                              : isToday
                                  ? AppColors.primary(context).withValues(alpha: 0.12)
                                  : null,
                          borderRadius: BorderRadius.circular(6),
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.primary(context),
                                  width: 2,
                                )
                              : isToday
                                  ? Border.all(
                                      color: AppColors.primary(context),
                                      width: 1.5,
                                    )
                                  : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          day.day.toString(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected || isToday ? FontWeight.w600 : null,
                            color: isSelected
                                ? AppColors.card(context)
                                : isCurrentMonth
                                    ? AppColors.textPrimary(context)
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
        ],
      ),
    );
  }

  Widget _buildDayConfigurationSection() {
    final weekdayLabel = _dayLabelsFull[_selectedDate.weekday == 7 ? 6 : _selectedDate.weekday - 1];
    final dateStr = '$weekdayLabel • ${DateFormat('d MMM', 'pt_BR').format(_selectedDate)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Configuração do dia',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedForeground(context),
                ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                dateStr,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (_loading) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary(context),
                  ),
                ),
              ] else if (_blockedDate != null) ...[
                const SizedBox(width: 8),
                Text(
                  'Dia bloqueado',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.error(context),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _compactActionButton(
                icon: Icons.add,
                label: 'Adicionar horário extra',
                onPressed: _blockedDate != null ? null : _openAddExtraHoursModal,
              ),
              _compactActionButton(
                icon: Icons.block,
                label: 'Bloquear horário',
                onPressed: _blockedDate != null ? null : _openBlockBlockModal,
              ),
            ],
          ),
          if (!_loading) ...[
            const SizedBox(height: 10),
            _buildCompactBlocksAndExtrasList(),
          ],
        ],
      ),
    );
  }

  Widget _compactActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: onPressed != null
          ? AppColors.primary(context).withValues(alpha: 0.1)
          : AppColors.fillColor(context),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: onPressed != null
                    ? AppColors.primary(context)
                    : AppColors.mutedForeground(context),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: onPressed != null
                          ? AppColors.primary(context)
                          : AppColors.mutedForeground(context),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openBlockBlockModal() async {
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
                'Bloquear dia ou horário',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.event_busy),
                title: const Text('Bloquear dia inteiro'),
                subtitle: const Text('Não atenderei neste dia'),
                onTap: () => Navigator.pop(ctx, 'day'),
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Bloquear horário'),
                subtitle: const Text('Bloquear um período específico'),
                onTap: () => Navigator.pop(ctx, 'range'),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == 'day') {
      await _blockFullDay();
    } else if (choice == 'range') {
      await _openBlockTimeRangeModal();
    }
  }

  Widget _buildCompactBlocksAndExtrasList() {
    final items = <Widget>[];

    if (_blockedDate != null) {
      items.add(
        _blockExtraBar(
          label: 'Dia inteiro bloqueado',
          onRemove: _unblockFullDay,
        ),
      );
    }

    for (final b in _manualBlocks) {
      final range = '${_formatTimeOfDay(TimeOfDay(hour: b.start.hour, minute: b.start.minute))}–${_formatTimeOfDay(TimeOfDay(hour: b.end.hour, minute: b.end.minute))}';
      items.add(
        _blockExtraBar(
          label: 'Horário bloqueado — $range',
          onRemove: () => _removeManualBlock(b),
        ),
      );
    }

    if (_dailyOverride != null && _dailyOverride!.shifts.isNotEmpty) {
      final salonRanges = _tenantConfig?.getOpeningRangesMinutes(_selectedDate.weekday) ?? [];
      final salonMax = salonRanges.isEmpty ? 0 : salonRanges.map((r) => r.end).reduce((a, b) => a > b ? a : b);
      final extraShifts = _dailyOverride!.shifts
          .where((s) => s.startMinutes >= salonMax || s.endMinutes > salonMax)
          .toList();

      for (final s in extraShifts) {
        final range = '${_formatMinutes(s.startMinutes)}–${_formatMinutes(s.endMinutes)}';
        items.add(
          _blockExtraBar(
            label: 'Horário extra — $range',
            onRemove: () => _removeExtraShift(s),
          ),
        );
      }
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Nenhum bloqueio ou horário extra',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: items,
    );
  }

  Widget _blockExtraBar({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Material(
      color: AppColors.primary(context).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary(context),
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.error(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MinLeadTimeField extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _MinLeadTimeField({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: value.clamp(0, max),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: List.generate(max + 1, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
          onChanged: (v) => onChanged(v ?? 0),
        ),
      ],
    );
  }
}
