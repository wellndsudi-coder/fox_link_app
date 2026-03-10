import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_timegrid_usecase.dart' show GetWeeklyTimeGridUseCase, TimeGridBlock;
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/manual_block.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/approve_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/cancel_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/reject_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/complete_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/request_reschedule_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_manual_blocks_by_period_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_monthly_agenda_stats_usecase.dart' show GetMonthlyAgendaStatsUseCase, DayAgendaStats;
import 'package:fox_link_app/modules/scheduling/domain/usecases/update_appointment_time_usecase.dart';
import 'package:fox_link_app/shared/widgets/app_button.dart';
import 'package:fox_link_app/modules/scheduling/presentation/widgets/appointment_block.dart';
import 'package:fox_link_app/modules/scheduling/presentation/pages/create_appointment_page.dart';
import 'package:fox_link_app/modules/professionals/presentation/pages/admin_team_list_page.dart';
import 'package:fox_link_app/modules/booking_intelligence/presentation/widgets/professional_waiting_list_section.dart';
import 'package:fox_link_app/modules/availability/domain/usecases/get_professional_availability.dart';
import 'package:fox_link_app/modules/availability/domain/entities/availability.dart';
import 'package:fox_link_app/modules/availability/domain/repositories/availability_repository.dart';
import 'package:fox_link_app/modules/tenant/domain/entities/tenant_config.dart';
import 'package:fox_link_app/modules/tenant/domain/usecases/get_tenant_config_usecase.dart';

class ProfessionalAgendaPage extends StatefulWidget {
  final bool isActive;
  /// When set (e.g. by admin viewing a professional's agenda), uses this instead of session.professionalId.
  final String? professionalIdOverride;

  const ProfessionalAgendaPage({
    super.key,
    required this.isActive,
    this.professionalIdOverride,
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
  final _availabilityRepo = GetIt.I<AvailabilityRepository>();
  final _getTenantConfig = GetIt.I<GetTenantConfigUseCase>();

  final _schedulingRepo = GetIt.I<SchedulingRepository>();
  final _approveUseCase = GetIt.I<ApproveAppointmentUseCase>();
  final _cancelUseCase = GetIt.I<CancelAppointmentUseCase>();
  final _rejectUseCase = GetIt.I<RejectAppointmentUseCase>();
  final _completeUseCase = GetIt.I<CompleteAppointmentUseCase>();
  final _rescheduleUseCase = GetIt.I<RequestRescheduleUseCase>();
  final _getManualBlocksUseCase = GetIt.I<GetManualBlocksByPeriodUseCase>();
  final _getMonthlyStatsUseCase = GetIt.I<GetMonthlyAgendaStatsUseCase>();
  final _updateTimeUseCase = GetIt.I<UpdateAppointmentTimeUseCase>();

  DateTime selectedDate = DateTime.now();
  Map<DateTime, DayAgendaStats>? _monthlyStats;
  final _agendaColumnKey = GlobalKey();
  final _scrollController = ScrollController();

  /// 0 = Dia, 1 = Semana, 2 = Mês
  int _viewMode = 0;

  @override
  void initState() {
    super.initState();
    _invalidateAgendaCache();
  }

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

  String? get _effectiveProfessionalId =>
      widget.professionalIdOverride ?? _session.professionalId;

  Future<Map<String, dynamic>> _loadAgendaData() async {
    final professionalId = _effectiveProfessionalId;
    if (professionalId == null) {
      return {
        'availability': null,
        'blocks': [],
        'manualBlocks': <ManualBlock>[],
      };
    }

    final daysSinceSunday = selectedDate.weekday == 7 ? 0 : selectedDate.weekday;
    final weekStart = selectedDate.subtract(Duration(days: daysSinceSunday));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final cacheKey = '$professionalId/${weekStart.toIso8601String().substring(0, 10)}';

    // Prioridade: DailyOverride (tela Horários) > disponibilidade semanal
    final dailyOverride = await _availabilityRepo.getDailyOverride(
      professionalId: professionalId,
      date: selectedDate,
    );

    Availability? todayAvailability;
    Map<int, Availability>? availabilityByWeekday;

    if (dailyOverride != null && dailyOverride.shifts.isNotEmpty) {
      todayAvailability = Availability(
        id: dailyOverride.id,
        professionalId: dailyOverride.professionalId,
        weekday: selectedDate.weekday,
        isActive: true,
        shifts: dailyOverride.shifts,
        slotIntervalMinutes: dailyOverride.slotIntervalMinutes,
        breakTimes: const [],
      );
    } else if (_agendaCacheKey == cacheKey && _agendaCache != null) {
      availabilityByWeekday = _agendaCache!['availabilityByWeekday'] as Map<int, Availability>?;
      todayAvailability = availabilityByWeekday?[selectedDate.weekday];
    }

    if (todayAvailability == null && (availabilityByWeekday == null || !availabilityByWeekday.containsKey(selectedDate.weekday))) {
      final availabilityList = await _availabilityUseCase(professionalId);
      availabilityByWeekday = <int, Availability>{};
      for (final a in availabilityList) {
        availabilityByWeekday[a.weekday] = a;
      }
      todayAvailability = availabilityByWeekday[selectedDate.weekday];
    }

    // Fallback para horários do salão quando o profissional não tem disponibilidade configurada
    final needsFallback = todayAvailability == null ||
        !todayAvailability.isActive ||
        todayAvailability.shifts.isEmpty;
    if (needsFallback) {
      final tenantId = _session.tenantId;
      if (tenantId != null) {
        final config = await _getTenantConfig(tenantId);
        final tenantAvail = _availabilityFromTenantConfig(config, selectedDate.weekday);
        if (tenantAvail != null) {
          todayAvailability = tenantAvail;
        }
      }
    }

    List blocks;
    List<ManualBlock> manualBlocks;

    if (_agendaCacheKey == cacheKey && _agendaCache != null) {
      blocks = _agendaCache!['blocks'] as List;
      manualBlocks = _agendaCache!['manualBlocks'] as List<ManualBlock>;
    } else {
      blocks = await _timeGridUseCase(
        professionalId: professionalId,
        referenceDate: selectedDate,
        tenantId: _session.tenantId,
      );
      manualBlocks = await _getManualBlocksUseCase(
        professionalId: professionalId,
        start: weekStart,
        end: weekEnd,
      );
      _agendaCacheKey = cacheKey;
      _agendaCache = {
        'availabilityByWeekday': availabilityByWeekday ?? {},
        'blocks': blocks,
        'manualBlocks': manualBlocks,
      };
    }

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

  /// Cria Availability a partir dos horários do salão quando o profissional não tem disponibilidade.
  static Availability? _availabilityFromTenantConfig(TenantConfig config, int weekday) {
    if (!config.isOpenOnWeekday(weekday)) return null;
    final ranges = config.getOpeningRangesMinutes(weekday);
    if (ranges.isEmpty) return null;
    final shifts = ranges
        .map((r) => TimeRange(startMinutes: r.start, endMinutes: r.end))
        .toList();
    return Availability(
      id: 'tenant-fallback',
      professionalId: '',
      weekday: weekday,
      isActive: true,
      shifts: shifts,
      slotIntervalMinutes: 30,
      breakTimes: const [],
    );
  }

  void _onDaySelected(DateTime day) {
    setState(() => selectedDate = day);
  }

  Future<void> _loadMonthlyStats() async {
    final professionalId = _session.professionalId;
    if (professionalId == null) return;
    try {
      final stats = await _getMonthlyStatsUseCase(
        professionalId: professionalId,
        year: selectedDate.year,
        month: selectedDate.month,
      );
      if (mounted) setState(() => _monthlyStats = stats);
    } catch (_) {}
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
    _loadMonthlyStats();
  }

  void _goToNextMonth() {
    setState(() {
      final d = selectedDate;
      selectedDate = DateTime(d.year, d.month + 1, d.day.clamp(1, 28));
    });
    _loadMonthlyStats();
  }

  /// Semana começa no domingo (para seletor de dias e calendário mensal)
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
                final dateOnly = DateTime(day.year, day.month, day.day);
                final stats = _monthlyStats?[dateOnly];

                return GestureDetector(
                  onTap: () => _onDaySelected(day),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary(context) : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday ? Border.all(color: AppColors.primary(context), width: 2) : null,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
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
                        if (stats != null && stats.capacityMinutes > 0)
                          Text(
                            '${stats.appointmentCount} • ${(stats.occupancyPct).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 9,
                              color: isSelected ? AppColors.card(context) : AppColors.mutedForeground(context),
                            ),
                          ),
                      ],
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
                  onTap: () {
                    setState(() => _viewMode = 2);
                    _loadMonthlyStats();
                  },
                ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.people),
                      tooltip: 'Gerenciar equipe',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminTeamListPage(),
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

            if (_effectiveProfessionalId != null)
              SliverToBoxAdapter(
                child: ProfessionalWaitingListSection(
                  professionalId: _effectiveProfessionalId!,
                  date: selectedDate,
                  tenantId: _session.tenantId,
                ),
              ),

            /// CORPO - hasScrollBody: false para dar altura limitada e evitar overflow
            SliverFillRemaining(
              hasScrollBody: false,
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

                  final shifts = availability.shifts;
                  int minStart = shifts.map((s) => s.startMinutes).reduce((a, b) => a < b ? a : b);
                  int maxEnd = shifts.map((s) => s.endMinutes).reduce((a, b) => a > b ? a : b);
                  final totalMinutes = maxEnd - minStart;
                  const int slotIntervalMinutes = 30;
                  const double slotHeight = 40;
                  final slotCount = (totalMinutes / slotIntervalMinutes).ceil();
                  final totalHeight = slotCount * slotHeight;
                  final breaks = availability.breakTimes;

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox(
                      height: totalHeight,
                      child: Row(
                        children: [

                          /// COLUNA HORÁRIOS
                          SizedBox(
                            width: 52,
                            child: Column(
                              children:
                              List.generate(
                                slotCount,
                                (index) {
                                  final minutes =
                                      minStart +
                                          (index *
                                              slotIntervalMinutes);
                                  final hour = minutes ~/ 60;
                                  final minute = minutes % 60;

                                  return SizedBox(
                                    height: slotHeight,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                AppColors.mutedForeground(context),
                                          ),
                                        ),
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
                                      final professionalId = _effectiveProfessionalId;
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
                                        PageRouteBuilder(
                                          pageBuilder: (_, __, ___) => CreateAppointmentPage(
                                            initialDate: selectedDate,
                                            initialSlot: slot,
                                            initialProfessionalId: professionalId,
                                          ),
                                          transitionsBuilder: (_, animation, __, child) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: SlideTransition(
                                                position: Tween<Offset>(
                                                  begin: const Offset(0, 0.04),
                                                  end: Offset.zero,
                                                ).animate(CurvedAnimation(
                                                  parent: animation,
                                                  curve: Curves.easeOutCubic,
                                                )),
                                                child: child,
                                              ),
                                            );
                                          },
                                          transitionDuration: const Duration(milliseconds: 300),
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
                                /// GRID - linhas apenas em hora cheia, alinhadas ao topo do slot
                                Column(
                                  children:
                                  List.generate(
                                    slotCount,
                                    (index) {
                                      final slotStartMinutes = minStart + index * slotIntervalMinutes;
                                      final isFullHour = slotStartMinutes % 60 == 0;
                                      return Container(
                                        height: slotHeight,
                                        decoration: BoxDecoration(
                                          border: isFullHour
                                              ? Border(
                                                  top: BorderSide(
                                                    color: AppColors.border(context),
                                                    width: 0.5,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      );
                                    },
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

                                /// AGENDAMENTOS - tamanho mínimo 1h, cresce se > 1h
                                ...blocks.map((block) {
                                  final top = ((block.startMinutes - minStart) / totalMinutes) * totalHeight;
                                  final proportionalHeight = (block.durationMinutes / totalMinutes) * totalHeight;
                                  const minHourHeight = slotHeight * 2; // 1h = 2 slots de 30min
                                  final blockHeight = proportionalHeight >= minHourHeight
                                      ? proportionalHeight
                                      : minHourHeight;
                                  return Positioned(
                                    top: top,
                                    left: 0,
                                    right: 0,
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

  void _showDetails(TimeGridBlock block) async {
    final appointment = await _schedulingRepo.getById(block.appointmentId);
    if (!mounted || appointment == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _AppointmentDetailSheet(
        block: block,
        appointment: appointment,
        onApprove: () async {
          try {
            await _approveUseCase(appointment);
            if (ctx.mounted) Navigator.pop(ctx);
            _invalidateAgendaCache();
            setState(() {});
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Agendamento aprovado!')),
              );
            }
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          }
        },
        onReject: () async {
          try {
            await _rejectUseCase(appointment);
            if (ctx.mounted) Navigator.pop(ctx);
            _invalidateAgendaCache();
            setState(() {});
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Agendamento rejeitado.')),
              );
            }
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          }
        },
        onReschedule: () async {
          if (!ctx.mounted) return;
          Navigator.pop(ctx);
          final message = await showDialog<String>(
            context: context,
            builder: (c) {
              final controller = TextEditingController();
              return AlertDialog(
                title: const Text('Solicitar reagendamento'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Digite uma mensagem para o cliente explicando o motivo (opcional):',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedForeground(c),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Preciso alterar o horário devido a um compromisso...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(c, controller.text.trim()),
                    child: const Text('Continuar'),
                  ),
                ],
              );
            },
          );
          if (!mounted) return;
          if (message == null) return;
          final date = await showDatePicker(
            context: context,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            initialDate: appointment.scheduledStart,
          );
          if (!mounted || date == null) return;
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(appointment.scheduledStart),
          );
          if (!mounted || time == null) return;
          final newStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          final newEnd = newStart.add(Duration(minutes: appointment.finalDuration));
          try {
            await _rescheduleUseCase(
              appointment: appointment,
              newStart: newStart,
              newEnd: newEnd,
              message: message.isEmpty ? null : message,
            );
            _invalidateAgendaCache();
            setState(() {});
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Reagendamento solicitado! O cliente será notificado e poderá aceitar ou recusar.',
                  ),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          }
        },
        onComplete: () async {
          try {
            await _completeUseCase(appointment);
            if (ctx.mounted) Navigator.pop(ctx);
            _invalidateAgendaCache();
            setState(() {});
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Serviço concluído!')),
              );
            }
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          }
        },
        onCancel: () async {
          final confirm = await showDialog<bool>(
            context: ctx,
            builder: (c) => AlertDialog(
              title: const Text('Cancelar agendamento?'),
              content: const Text('O horário ficará livre. Tem certeza?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Não'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: Text('Sim', style: TextStyle(color: AppColors.error(c))),
                ),
              ],
            ),
          );
          if (confirm != true) return;
          try {
            await _cancelUseCase(appointment.id);
            if (ctx.mounted) Navigator.pop(ctx);
            _invalidateAgendaCache();
            setState(() {});
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Agendamento cancelado. Horário liberado.')),
              );
            }
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          }
        },
      ),
    );
  }
}

class _AppointmentDetailSheet extends StatelessWidget {
  final TimeGridBlock block;
  final Appointment appointment;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onReschedule;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const _AppointmentDetailSheet({
    required this.block,
    required this.appointment,
    required this.onApprove,
    required this.onReject,
    required this.onReschedule,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = block.status.toString().split('.').last;
    final isPending = block.status == AppointmentStatus.pending;
    final isApproved = block.status == AppointmentStatus.approved;
    final isRescheduleRequested = block.status == AppointmentStatus.rescheduleRequested;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            block.clientLabel,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            block.serviceLabel,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.mutedForeground(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Status: $statusLabel',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedForeground(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          if (isPending) ...[
            AppButton(text: 'Aprovar', onPressed: onApprove),
            const SizedBox(height: 12),
            AppButton(text: 'Rejeitar', variant: AppButtonVariant.outline, onPressed: onReject),
            const SizedBox(height: 12),
            AppButton(text: 'Reagendar', variant: AppButtonVariant.outline, onPressed: onReschedule),
          ],
          if (isApproved || isRescheduleRequested) ...[
            AppButton(text: 'Concluir serviço', onPressed: onComplete),
            const SizedBox(height: 12),
            AppButton(
              text: 'Cancelar agendamento',
              variant: AppButtonVariant.outline,
              onPressed: onCancel,
            ),
          ],
          if (!isPending && !isApproved && !isRescheduleRequested)
            AppButton(
              text: 'Fechar',
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.pop(context),
            ),
        ],
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
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(
            color: selected ? AppColors.primary(context) : AppColors.border(context),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.primary(context) : AppColors.mutedForeground(context),
          ),
        ),
      ),
    );
  }
}