import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../../core/session/tenant_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/tenant_firestore.dart';
import '../../domain/entities/availability.dart';
import '../../domain/entities/daily_override.dart';
import '../../domain/repositories/availability_repository.dart';
import '../../domain/usecases/get_professional_availability.dart';
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
  final _getUseCase = GetIt.I<GetProfessionalAvailability>();
  final _availabilityRepo = GetIt.I<AvailabilityRepository>();

  final List<String> weekLabels = [
    "SEG", "TER", "QUA", "QUI", "SEX", "SAB", "DOM"
  ];

  static const _dayLabels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  String? _professionalDocId;

  DateTime selectedDate = DateTime.now();
  /// 0 = Hoje visual, 1 = Semana, 2 = Mês
  int _viewMode = 1;
  List<TimeRange> shifts = [];
  int slotIntervalMinutes = 0;

  /// Sempre data específica (DailyOverride) - sem toggle
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
    // Usar o mesmo professionalId da sessão (usado pela Minha Agenda) para garantir que os horários programados aqui apareçam na agenda.
    if (_session.professionalId != null && _session.professionalId!.isNotEmpty) {
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

    final override = await _availabilityRepo.getDailyOverride(
      professionalId: _professionalDocId!,
      date: selectedDate,
    );

    if (override != null) {
      setState(() {
        shifts = List.from(override.shifts);
        slotIntervalMinutes = override.slotIntervalMinutes;
      });
      return;
    }

    setState(() {
      shifts = [];
      slotIntervalMinutes = 0;
    });
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();

    _autoSaveTimer = Timer(
      const Duration(milliseconds: 600),
      () async {
        if (_professionalDocId == null) return;

        final normDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        if (shifts.isEmpty) {
          await _availabilityRepo.removeDailyOverride(
            '${_professionalDocId}_${normDate.toIso8601String()}',
          );
        } else {
          await _availabilityRepo.saveDailyOverride(
            DailyOverride(
              id: '${_professionalDocId}_${normDate.toIso8601String()}',
              professionalId: _professionalDocId!,
              date: selectedDate,
              shifts: shifts,
              slotIntervalMinutes: slotIntervalMinutes,
            ),
          );
        }
        await _refreshConfiguredDays();
      },
    );
  }

  DateTime _weekStart(DateTime date) {
    final daysSinceSunday = date.weekday == 7 ? 0 : date.weekday;
    return date.subtract(Duration(days: daysSinceSunday));
  }

  void _onDaySelected(DateTime day) {
    setState(() => selectedDate = day);
    _loadAvailability();
  }

  void _goToPreviousWeek() {
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 7));
    });
    _loadAvailability();
  }

  void _goToNextWeek() {
    setState(() {
      selectedDate = selectedDate.add(const Duration(days: 7));
    });
    _loadAvailability();
  }

  void _goToPreviousMonth() {
    setState(() {
      final d = selectedDate;
      selectedDate = DateTime(d.year, d.month - 1, d.day.clamp(1, 28));
    });
    _loadAvailability();
  }

  void _goToNextMonth() {
    setState(() {
      final d = selectedDate;
      selectedDate = DateTime(d.year, d.month + 1, d.day.clamp(1, 28));
    });
    _loadAvailability();
  }

  Widget _buildMonthCalendar(DateTime weekStart) {
    final monthStart = DateTime(selectedDate.year, selectedDate.month, 1);
    final calendarStart = _weekStart(monthStart);
    final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final weeks =
        ((lastDay.difference(calendarStart).inDays + 1) / 7).ceil().clamp(4, 6);

    const colWidth = FlexColumnWidth(1);

    return Container(
      color: AppColors.card(context),
      padding: const EdgeInsets.all(12),
      child: Table(
        columnWidths: {for (var i = 0; i < 7; i++) i: colWidth},
        children: [
          TableRow(
            children: List.generate(
              7,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: Text(
                    _dayLabels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedForeground(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ...List.generate(weeks, (weekIndex) {
            return TableRow(
              children: List.generate(7, (dayIndex) {
                final day =
                    calendarStart.add(Duration(days: weekIndex * 7 + dayIndex));
                final isCurrentMonth = day.month == selectedDate.month;
                final isSelected = DateUtils.isSameDay(day, selectedDate);
                final isToday = DateUtils.isSameDay(day, DateTime.now());

                return GestureDetector(
                  onTap: () => _onDaySelected(day),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary(context) : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: AppColors.primary(context), width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      day.day.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
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
    );
  }

  Future<void> _openCopyOptions() async {
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Copiar horários para",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _softBlueButton(
                      icon: Icons.calendar_view_week_rounded,
                      label: "Semana",
                      onTap: () async {
                        Navigator.pop(context);
                        await _copyToWeek();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _softBlueButton(
                      icon: Icons.calendar_month_rounded,
                      label: "Mês",
                      onTap: () async {
                        Navigator.pop(context);
                        await _copyToMonth();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyToWeek() async {
    if (_professionalDocId == null) return;

    final weekStart = _weekStart(selectedDate);

    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final normDate = DateTime(day.year, day.month, day.day);
      final overrideId = '${_professionalDocId}_${normDate.toIso8601String()}';

      if (shifts.isEmpty) {
        await _availabilityRepo.removeDailyOverride(overrideId);
      } else {
        await _availabilityRepo.saveDailyOverride(
          DailyOverride(
            id: overrideId,
            professionalId: _professionalDocId!,
            date: normDate,
            shifts: List.from(shifts),
            slotIntervalMinutes: slotIntervalMinutes,
          ),
        );
      }
    }

    await _refreshConfiguredDays();
    await _loadAvailability();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shifts.isEmpty
                ? "Horários removidos da semana"
                : "Copiado para os 7 dias da semana!",
          ),
        ),
      );
    }
  }

  Future<void> _copyToMonth() async {
    if (_professionalDocId == null) return;

    final year = selectedDate.year;
    final month = selectedDate.month;
    final lastDay = DateTime(year, month + 1, 0).day;

    for (var day = 1; day <= lastDay; day++) {
      final normDate = DateTime(year, month, day);
      final overrideId = '${_professionalDocId}_${normDate.toIso8601String()}';

      if (shifts.isEmpty) {
        await _availabilityRepo.removeDailyOverride(overrideId);
      } else {
        await _availabilityRepo.saveDailyOverride(
          DailyOverride(
            id: overrideId,
            professionalId: _professionalDocId!,
            date: normDate,
            shifts: List.from(shifts),
            slotIntervalMinutes: slotIntervalMinutes,
          ),
        );
      }
    }

    await _refreshConfiguredDays();
    await _loadAvailability();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shifts.isEmpty
                ? "Horários removidos do mês"
                : "Copiado para os $lastDay dias do mês!",
          ),
        ),
      );
    }
  }

  // ===========================
  // LIMPAR (igual Copiar: barra com Semana e Mês)
  // ===========================

  Future<void> _openClearOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Limpar horários",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _softBlueButton(
                      icon: Icons.calendar_view_week_rounded,
                      label: "Limpar semana",
                      onTap: () async {
                        Navigator.pop(context);
                        await _clearWeek();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _softBlueButton(
                      icon: Icons.calendar_month_rounded,
                      label: "Limpar mês",
                      onTap: () async {
                        Navigator.pop(context);
                        await _clearMonth();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearWeek() async {
    if (_professionalDocId == null) return;

    final weekStart = _weekStart(selectedDate);

    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final normDate = DateTime(day.year, day.month, day.day);
      final overrideId = '${_professionalDocId}_${normDate.toIso8601String()}';
      await _availabilityRepo.removeDailyOverride(overrideId);
    }

    await _refreshConfiguredDays();
    if (mounted) await _loadAvailability();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semana limpa")),
      );
    }
  }

  Future<void> _clearMonth() async {
    if (_professionalDocId == null) return;

    final year = selectedDate.year;
    final month = selectedDate.month;
    final lastDay = DateTime(year, month + 1, 0).day;

    for (var day = 1; day <= lastDay; day++) {
      final normDate = DateTime(year, month, day);
      final overrideId = '${_professionalDocId}_${normDate.toIso8601String()}';
      await _availabilityRepo.removeDailyOverride(overrideId);
    }

    await _refreshConfiguredDays();
    if (mounted) await _loadAvailability();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Mês limpo ($lastDay dias)"),
        ),
      );
    }
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
      backgroundColor: AppColors.card(context),
      builder: (_) {
        final primary = AppColors.primary(context);
        final scheme = Theme.of(context).colorScheme;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: scheme.copyWith(
              primary: primary,
              surface: AppColors.card(context),
              onSurface: AppColors.textPrimary(context),
            ),
            scaffoldBackgroundColor: AppColors.card(context),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return primary;
                return null;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return primary.withValues(alpha: 0.5);
                }
                return null;
              }),
            ),
            sliderTheme: SliderThemeData(
              activeTrackColor: primary,
              inactiveTrackColor: AppColors.border(context),
              thumbColor: primary,
              overlayColor: primary.withValues(alpha: 0.2),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: AppColors.onPrimary(context),
              ),
            ),
            listTileTheme: ListTileThemeData(
              textColor: AppColors.textPrimary(context),
              iconColor: AppColors.mutedForeground(context),
            ),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    children: [

                      Text(
                        "Modo Inteligente",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),

                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 8,
                      children: List.generate(7, (index) {
                        final day = index + 1;

                        return FilterChip(
                          showCheckmark: false,
                          selectedColor: AppColors.primary(context),
                          backgroundColor: AppColors.fillColor(context),
                          side: BorderSide(
                            color: selectedDays.contains(day)
                                ? AppColors.primary(context)
                                : AppColors.border(context),
                          ),
                          label: Text(
                            weekLabels[index],
                            style: TextStyle(
                              color: selectedDays.contains(day)
                                  ? AppColors.card(context)
                                  : AppColors.textPrimary(context),
                            ),
                          ),
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
                      title: Text("Início", style: TextStyle(color: AppColors.textPrimary(context))),
                      trailing: Text(startTime.format(context), style: TextStyle(color: AppColors.mutedForeground(context))),
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
                      title: Text("Fim", style: TextStyle(color: AppColors.textPrimary(context))),
                      trailing: Text(endTime.format(context), style: TextStyle(color: AppColors.mutedForeground(context))),
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
                      title: Text("Ativar almoço", style: TextStyle(color: AppColors.textPrimary(context))),
                      value: hasLunch,
                      onChanged: (value) {
                        setModalState(() => hasLunch = value);
                      },
                    ),

                    if (hasLunch) ...[
                      ListTile(
                        title: Text("Almoço início", style: TextStyle(color: AppColors.textPrimary(context))),
                        trailing: Text(lunchStart.format(context), style: TextStyle(color: AppColors.mutedForeground(context))),
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
                        title: Text("Almoço fim", style: TextStyle(color: AppColors.textPrimary(context))),
                        trailing: Text(lunchEnd.format(context), style: TextStyle(color: AppColors.mutedForeground(context))),
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

                    Text(
                      "Intervalo entre clientes",
                      style: TextStyle(color: AppColors.textPrimary(context)),
                    ),

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

                        final year = selectedDate.year;
                        final month = selectedDate.month;
                        final lastDay = DateTime(year, month + 1, 0).day;

                        for (var day = 1; day <= lastDay; day++) {
                          final date = DateTime(year, month, day);
                          if (!selectedDays.contains(date.weekday)) continue;

                          final overrideId =
                              '${_professionalDocId}_${date.toIso8601String()}';
                          final existing = await _availabilityRepo
                              .getDailyOverride(
                                  professionalId: _professionalDocId!,
                                  date: date);

                          if (existing != null && existing.shifts.isNotEmpty) {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => Theme(
                                data: Theme.of(dialogContext).copyWith(
                                  colorScheme: Theme.of(dialogContext)
                                      .colorScheme
                                      .copyWith(
                                          primary: AppColors.primary(context)),
                                ),
                                child: AlertDialog(
                                  title: const Text("Substituir dia?"),
                                  content: Text(
                                    "O dia ${date.day}/${date.month} já possui configuração.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(
                                          dialogContext, false),
                                      child: Text(
                                        "Cancelar",
                                        style: TextStyle(
                                            color: AppColors.mutedForeground(
                                                context)),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: Text(
                                        "Substituir",
                                        style: TextStyle(
                                            color: AppColors.primary(context),
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            if (confirm != true) continue;
                          }

                          await _availabilityRepo.saveDailyOverride(
                            DailyOverride(
                              id: overrideId,
                              professionalId: _professionalDocId!,
                              date: date,
                              shifts: List.from(generated),
                              slotIntervalMinutes: interval,
                            ),
                          );
                        }

                        Navigator.pop(context);

                        // Atualização imediata da barra: se selectedDate foi gerado, exibir na hora
                        final selectedNorm = DateTime(
                            selectedDate.year, selectedDate.month, selectedDate.day);
                        final selectedWasGenerated = (selectedNorm.year == year &&
                            selectedNorm.month == month &&
                            selectedDays.contains(selectedDate.weekday));
                        if (mounted && selectedWasGenerated) {
                          setState(() {
                            shifts = List.from(generated);
                            slotIntervalMinutes = interval;
                          });
                        }

                        await _refreshConfiguredDays();
                        if (mounted) await _loadAvailability();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Agenda gerada com sucesso")),
                          );
                        }
                      },
                      child: const Text("Gerar agenda"),
                    ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ===========================

  @override
  Widget build(BuildContext context) {
    final weekStart = _weekStart(selectedDate);

    return Container(
      color: AppColors.background(context),
      child: Column(
        children: [
          /// Chips Hoje | Semana | Mês
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _ViewChip(
                  label: 'Hoje',
                  selected: DateUtils.isSameDay(selectedDate, DateTime.now()),
                  onTap: () {
                    setState(() => selectedDate = DateTime.now());
                    _loadAvailability();
                  },
                ),
                const SizedBox(width: 8),
                _ViewChip(
                  label: 'Semana',
                  selected: _viewMode == 1,
                  onTap: () => setState(() => _viewMode = 1),
                ),
                const SizedBox(width: 8),
                _ViewChip(
                  label: 'Mês',
                  selected: _viewMode == 2,
                  onTap: () => setState(() => _viewMode = 2),
                ),
              ],
            ),
          ),
          /// Navegação mês + setas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: AppColors.card(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _viewMode == 2
                      ? _goToPreviousMonth
                      : _goToPreviousWeek,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                Text(
                  DateFormat.yMMMM('pt_BR').format(selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed:
                      _viewMode == 2 ? _goToNextMonth : _goToNextWeek,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),
          /// Seletor de dias: Mês = calendário | Semana = 7 dias
          if (_viewMode == 2)
            _buildMonthCalendar(weekStart)
          else
            Container(
              color: AppColors.card(context),
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  final day = weekStart.add(Duration(days: index));
                  final isSelected = DateUtils.isSameDay(day, selectedDate);
                  final dayLabel = _dayLabels[index];
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _onDaySelected(day),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary(context)
                                  : AppColors.mutedForeground(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary(context)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              day.day.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.card(context)
                                    : AppColors.textPrimary(context),
                              ),
                            ),
                          ),
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
                          onTap: _openCopyOptions,
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
                          onTap: _openClearOptions,
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
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary(context)),
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
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary(context).withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(
            color: AppColors.primary(context).withOpacity(0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primary(context)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AppColors.primary(context),
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

class _ViewChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary(context) : AppColors.fillColor(context),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.card(context) : AppColors.mutedForeground(context),
          ),
        ),
      ),
    );
  }
}