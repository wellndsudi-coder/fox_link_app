import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_timegrid_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/manual_block.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/approve_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/cancel_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_manual_blocks_by_period_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/update_appointment_time_usecase.dart';
import 'package:fox_link_app/modules/scheduling/presentation/widgets/appointment_block.dart';
import 'package:fox_link_app/modules/scheduling/presentation/pages/create_appointment_page.dart';
import 'package:fox_link_app/modules/scheduling/presentation/pages/multi_professional_agenda_page.dart';
import 'package:fox_link_app/modules/availability/domain/usecases/get_professional_availability.dart';
import 'package:fox_link_app/modules/availability/domain/entities/availability.dart';

class ProfessionalAgendaPage extends StatefulWidget {
  final bool isActive;

  const ProfessionalAgendaPage({
    super.key,
    required this.isActive,
  });

  @override
  State<ProfessionalAgendaPage> createState() =>
      _ProfessionalAgendaPageState();
}

class _ProfessionalAgendaPageState
    extends State<ProfessionalAgendaPage> {

  final _session = GetIt.I<TenantSession>();
  final _timeGridUseCase =
  GetIt.I<GetWeeklyTimeGridUseCase>();
  final _availabilityUseCase =
  GetIt.I<GetProfessionalAvailability>();

  final _approveUseCase = GetIt.I<ApproveAppointmentUseCase>();
  final _cancelUseCase = GetIt.I<CancelAppointmentUseCase>();
  final _getManualBlocksUseCase = GetIt.I<GetManualBlocksByPeriodUseCase>();
  final _updateTimeUseCase = GetIt.I<UpdateAppointmentTimeUseCase>();

  DateTime selectedDate = DateTime.now();
  final _agendaColumnKey = GlobalKey();
  final _scrollController = ScrollController();

  /// 0 = Dia, 1 = Semana, 2 = Mês
  int _viewMode = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Cache by (professionalId, weekStart) to avoid refetch when switching days in same week.
  Map<String, dynamic>? _agendaCache;
  String? _agendaCacheKey;

  @override
  void didUpdateWidget(
      covariant ProfessionalAgendaPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive && !oldWidget.isActive) {
      _invalidateAgendaCache();
      setState(() {});
    }
  }

  Future<Map<String, dynamic>> _loadAgendaData() async {
    final professionalId = _session.professionalId;
    if (professionalId == null) {
      return {
        'availability': null,
        'blocks': [],
        'manualBlocks': <ManualBlock>[],
      };
    }

    // Semana começa no domingo (weekday 7 = domingo, 1 = segunda)
    final daysSinceSunday = selectedDate.weekday == 7 ? 0 : selectedDate.weekday;
    final weekStart = selectedDate.subtract(Duration(days: daysSinceSunday));
    final cacheKey = '$professionalId/${weekStart.toIso8601String().substring(0, 10)}';
    if (_agendaCacheKey == cacheKey && _agendaCache != null) {
      final cached = _agendaCache!;
      final availabilityByWeekday = cached['availabilityByWeekday'] as Map<int, Availability>?;
      final allBlocks = cached['blocks'] as List;
      final manualBlocks = cached['manualBlocks'] as List<ManualBlock>;
      final todayAvailability = availabilityByWeekday?[selectedDate.weekday];
      return {
        'availability': todayAvailability,
        'blocks': allBlocks.where((b) => b.weekday == selectedDate.weekday).toList(),
        'manualBlocks': manualBlocks,
      };
    }

    // Mesma fonte da tela Horários: disponibilidade semanal configurada pelo profissional.
    final availabilityList = await _availabilityUseCase(professionalId);
    final availabilityByWeekday = <int, Availability>{};
    for (final a in availabilityList) {
      availabilityByWeekday[a.weekday] = a;
    }
    final todayAvailability = availabilityByWeekday[selectedDate.weekday];

    final weekEnd = weekStart.add(const Duration(days: 7));
    final blocks = await _timeGridUseCase(
      professionalId: professionalId,
      referenceDate: selectedDate,
      tenantId: _session.tenantId,
    );
    final manualBlocks = await _getManualBlocksUseCase(
      professionalId: professionalId,
      start: weekStart,
      end: weekEnd,
    );

    _agendaCacheKey = cacheKey;
    _agendaCache = {
      'availabilityByWeekday': availabilityByWeekday,
      'blocks': blocks,
      'manualBlocks': manualBlocks,
    };

    return {
      'availability': todayAvailability,
      'blocks': blocks.where((b) => b.weekday == selectedDate.weekday).toList(),
      'manualBlocks': manualBlocks,
    };
  }

  void _invalidateAgendaCache() {
    _agendaCache = null;
    _agendaCacheKey = null;
  }

  void _onDaySelected(DateTime day) {
    setState(() => selectedDate = day);
  }

  void _goToPreviousWeek() {
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 7));
    });
  }

  void _goToNextWeek() {
    setState(() {
      selectedDate = selectedDate.add(const Duration(days: 7));
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      final d = selectedDate;
      selectedDate = DateTime(d.year, d.month - 1, d.day.clamp(1, 28));
    });
  }

  void _goToNextMonth() {
    setState(() {
      final d = selectedDate;
      selectedDate = DateTime(d.year, d.month + 1, d.day.clamp(1, 28));
    });
  }

  /// Semana começa no domingo
  DateTime _weekStart(DateTime date) {
    final daysSinceSunday = date.weekday == 7 ? 0 : date.weekday;
    return date.subtract(Duration(days: daysSinceSunday));
  }

  static const _dayLabels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  Widget _buildMonthCalendar(DateTime weekStart) {
    final monthStart = DateTime(selectedDate.year, selectedDate.month, 1);
    final calendarStart = _weekStart(monthStart);
    final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final weeks = ((lastDay.difference(calendarStart).inDays + 1) / 7).ceil().clamp(4, 6);

    const colWidth = FlexColumnWidth(1);

    return Container(
      color: AppColors.card(context),
      padding: const EdgeInsets.all(12),
      child: Table(
        columnWidths: {for (var i = 0; i < 7; i++) i: colWidth},
        children: [
          TableRow(
            children: List.generate(7, (i) => Padding(
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
            )),
          ),
          ...List.generate(weeks, (weekIndex) {
            return TableRow(
              children: List.generate(7, (dayIndex) {
                final day = calendarStart.add(
                  Duration(days: weekIndex * 7 + dayIndex),
                );
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
                      border: isToday ? Border.all(color: AppColors.primary(context), width: 2) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      day.day.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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

  List<Widget> _manualBlocksForDay(
    List<ManualBlock> manualBlocks,
    DateTime day,
    int minStart,
    int totalMinutes,
    double totalHeight,
  ) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final int maxEnd = minStart + totalMinutes;
    final list = <Widget>[];
    for (final b in manualBlocks) {
      if (b.end.isBefore(dayStart) || b.start.isAfter(dayEnd)) continue;
      final blockStart = b.start.isBefore(dayStart) ? dayStart : b.start;
      final blockEnd = b.end.isAfter(dayEnd) ? dayEnd : b.end;
      final startMinutes = blockStart.hour * 60 + blockStart.minute;
      final endMinutes = blockEnd.hour * 60 + blockEnd.minute;
      if (endMinutes <= minStart || startMinutes >= maxEnd) continue;
      final top = ((startMinutes - minStart) / totalMinutes) * totalHeight;
      final height = ((endMinutes - startMinutes) / totalMinutes) * totalHeight;
      list.add(
        Positioned(
          top: top,
          left: 8,
          right: 8,
          height: height.clamp(24.0, double.infinity),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning(context).withOpacity(0.25),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
              border: Border.all(color: AppColors.warning(context)),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              b.label,
              style: TextStyle(fontSize: 11, color: AppColors.textPrimary(context)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = _weekStart(selectedDate);

    return Container(
      color: AppColors.background(context),
      child: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            /// Seletor Dia / Semana / Mês
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _ViewChip(
                      label: 'Hoje',
                      selected: DateUtils.isSameDay(selectedDate, DateTime.now()),
                      onTap: () => setState(() => selectedDate = DateTime.now()),
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
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.people),
                      tooltip: 'Ver equipe',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MultiProfessionalAgendaPage(),
                          ),
                        ).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            /// Navegação mês + seta
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: AppColors.card(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _viewMode == 2 ? _goToPreviousMonth : _goToPreviousWeek,
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
                      onPressed: _viewMode == 2 ? _goToNextMonth : _goToNextWeek,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ],
                ),
              ),
            ),
            /// Semana: 7 dias fixos (Dom–Sáb) | Dia: scroll de dias | Mês: calendário
            if (_viewMode == 2) ...[
              SliverToBoxAdapter(
                child: _buildMonthCalendar(weekStart),
              ),
            ] else if (_viewMode == 1) ...[
              SliverToBoxAdapter(
                child: Container(
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
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? AppColors.primary(context) : AppColors.mutedForeground(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary(context) : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  day.day.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? AppColors.card(context) : AppColors.textPrimary(context),
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
              ),
            ] else ...[
              SliverToBoxAdapter(
                child: Container(
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
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? AppColors.primary(context) : AppColors.mutedForeground(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary(context) : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  day.day.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? AppColors.card(context) : AppColors.textPrimary(context),
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
              ),
            ],

            /// CORPO
            SliverFillRemaining(
              child: FutureBuilder(
                future: _loadAgendaData(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final data = snapshot.data!;
                  final Availability? availability = data['availability'];
                  final List blocks = data['blocks'];
                  final List<ManualBlock> manualBlocks =
                      data['manualBlocks'] as List<ManualBlock>? ?? [];

                  if (availability == null ||
                      !availability.isActive ||
                      availability.shifts.isEmpty) {
                    return const Center(
                      child: Text(
                        "Você não atende neste dia.",
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  final shifts =
                      availability.shifts;
                  final breaks =
                      availability.breakTimes;

                  int minStart = shifts
                      .map((s) => s.startMinutes)
                      .reduce((a, b) =>
                  a < b ? a : b);

                  int maxEnd = shifts
                      .map((s) => s.endMinutes)
                      .reduce((a, b) =>
                  a > b ? a : b);

                  final totalMinutes =
                      maxEnd - minStart;

                  const double hourHeight = 80;

                  final totalHeight =
                      (totalMinutes / 60) *
                          hourHeight;

                  return SingleChildScrollView(
                    child: SizedBox(
                      height: totalHeight,
                      child: Row(
                        children: [

                          /// COLUNA HORÁRIOS
                          SizedBox(
                            width: 60,
                            child: Column(
                              children:
                              List.generate(
                                (totalMinutes /
                                    60)
                                    .ceil(),
                                    (index) {
                                  final minutes =
                                      minStart +
                                          (index *
                                              60);

                                  final hour =
                                      minutes ~/ 60;
                                  final minute =
                                      minutes % 60;

                                  return Container(
                                    height:
                                    hourHeight,
                                    alignment:
                                    Alignment
                                        .topCenter,
                                    child: Text(
                                      "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}",
                                      style:
                                      TextStyle(
                                        fontSize:
                                        12,
                                        color:
                                        AppColors.mutedForeground(context),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          /// ÁREA AGENDA
                          Expanded(
                            child: DragTarget<AppointmentDragPayload>(
                              onAcceptWithDetails: (details) async {
                                final payload = details.data;
                                final box = _agendaColumnKey.currentContext?.findRenderObject() as RenderBox?;
                                if (box == null) return;
                                final local = box.globalToLocal(details.offset);
                                final dy = local.dy;
                                final totalMinutesD = totalMinutes.toDouble();
                                if (totalHeight <= 0 || totalMinutesD <= 0) return;
                                final minutesPerPx = totalMinutesD / totalHeight;
                                int newStartMinutes = (minStart + (dy * minutesPerPx).round())
                                    .clamp(minStart, 24 * 60 - payload.durationMinutes).toInt();
                                const snap = 15;
                                newStartMinutes = (newStartMinutes / snap).round() * snap;
                                final newStart = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  newStartMinutes ~/ 60,
                                  newStartMinutes % 60,
                                );
                                final newEnd = newStart.add(Duration(minutes: payload.durationMinutes));
                                try {
                                  await _updateTimeUseCase(
                                    appointmentId: payload.appointmentId,
                                    newStart: newStart,
                                    newEnd: newEnd,
                                  );
                                  if (mounted) {
                                    _invalidateAgendaCache();
                                    setState(() {});
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                }
                              },
                              builder: (context, candidateData, rejectedData) {
                                return Stack(
                                  key: _agendaColumnKey,
                                  children: [
                                /// Tap on empty area to create appointment
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTapUp: (details) {
                                      final professionalId = _session.professionalId;
                                      if (professionalId == null) return;
                                      final dy = details.localPosition.dy;
                                      if (dy < 0 || dy > totalHeight) return;
                                      final totalMinutesD = totalMinutes.toDouble();
                                      if (totalMinutesD <= 0) return;
                                      final startMinutes = (minStart + (dy / totalHeight) * totalMinutesD).round();
                                      const snap = 15;
                                      final snapped = (startMinutes / snap).round() * snap;
                                      final slot = DateTime(
                                        selectedDate.year,
                                        selectedDate.month,
                                        selectedDate.day,
                                        snapped ~/ 60,
                                        snapped % 60,
                                      );
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => CreateAppointmentPage(
                                            initialDate: selectedDate,
                                            initialSlot: slot,
                                            initialProfessionalId: professionalId,
                                          ),
                                        ),
                                      ).then((_) {
                                        if (mounted) {
                                          _invalidateAgendaCache();
                                          setState(() {});
                                        }
                                      });
                                    },
                                  ),
                                ),
                                /// GRID
                                Column(
                                  children:
                                  List.generate(
                                    (totalMinutes /
                                        60)
                                        .ceil(),
                                        (_) =>
                                        Container(
                                          height:
                                          hourHeight,
                                          decoration:
                                          BoxDecoration(
                                            border:
                                            Border(
                                              bottom:
                                              BorderSide(
                                                color:
                                                AppColors.border(context),
                                              ),
                                            ),
                                          ),
                                        ),
                                  ),
                                ),

                                /// BREAKS
                                ...breaks.map((b) {
                                  final top = ((b.startMinutes - minStart) / totalMinutes) * totalHeight;
                                  final height = ((b.endMinutes - b.startMinutes) / totalMinutes) * totalHeight;
                                  return Positioned(
                                    top: top,
                                    left: 0,
                                    right: 0,
                                    height: height,
                                    child: Container(
                                      color: AppColors.mutedForeground(context).withOpacity(0.2),
                                    ),
                                  );
                                }),

                                /// BLOQUEIOS MANUAIS (dia selecionado)
                                ..._manualBlocksForDay(manualBlocks, selectedDate, minStart, totalMinutes, totalHeight),

                                /// AGENDAMENTOS
                                ...blocks.map((block) {
                                  final top = ((block.startMinutes - minStart) / totalMinutes) * totalHeight;
                                  final height = (block.durationMinutes / totalMinutes) * totalHeight;
                                  final blockHeight = height < 40 ? 40.0 : height;
                                  return Positioned(
                                    top: top,
                                    left: 8,
                                    right: 8,
                                    height: blockHeight,
                                    child: AppointmentBlock(
                                      block: block,
                                      date: selectedDate,
                                      minStartMinutes: minStart,
                                      totalMinutes: totalMinutes,
                                      totalHeight: totalHeight,
                                      onTap: () => _showDetails(block),
                                      onTimeChanged: (newStart, newEnd) async {
                                        try {
                                          await _updateTimeUseCase(
                                            appointmentId: block.appointmentId,
                                            newStart: newStart,
                                            newEnd: newEnd,
                                          );
                                          if (mounted) {
                                            _invalidateAgendaCache();
                                            setState(() {});
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(e.toString())),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  );
                                }),
                                  ],
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
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(block) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding:
          const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                block.clientLabel,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(block.serviceLabel),
              const SizedBox(height: 8),
              Text(
                  "Status: ${block.status.toString().split('.').last}"),
              const SizedBox(height: 16),

              if (block.status ==
                  AppointmentStatus.pending)
                ElevatedButton(
                  onPressed: () async {
                    await _approveUseCase(
                        block.appointmentId);
                    Navigator.pop(context);
                    _invalidateAgendaCache();
                    setState(() {});
                  },
                  child:
                  const Text("Aprovar"),
                ),

              if (block.status ==
                  AppointmentStatus.approved)
                ElevatedButton(
                  onPressed: () async {
                    await _cancelUseCase(
                        block.appointmentId);
                    Navigator.pop(context);
                    _invalidateAgendaCache();
                    setState(() {});
                  },
                  child:
                  const Text("Cancelar"),
                ),
            ],
          ),
        );
      },
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