import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_timegrid_usecase.dart'
    show GetWeeklyTimeGridUseCase, TimeGridBlock;
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/manual_block.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_manual_blocks_by_period_usecase.dart';
import 'package:fox_link_app/modules/scheduling/presentation/pages/create_appointment_page.dart';
import 'package:fox_link_app/modules/availability/domain/usecases/get_professional_availability.dart';
import 'package:fox_link_app/modules/availability/domain/entities/availability.dart';
import 'package:fox_link_app/modules/tenant/domain/entities/tenant_config.dart';
import 'package:fox_link_app/modules/tenant/domain/usecases/get_tenant_config_usecase.dart';

class MultiProfessionalAgendaPage extends StatefulWidget {
  final bool isActive;

  const MultiProfessionalAgendaPage({
    super.key,
    required this.isActive,
  });

  @override
  State<MultiProfessionalAgendaPage> createState() =>
      _MultiProfessionalAgendaPageState();
}

class _MultiProfessionalAgendaPageState extends State<MultiProfessionalAgendaPage> {
  final _session = GetIt.I<TenantSession>();
  final _timeGridUseCase = GetIt.I<GetWeeklyTimeGridUseCase>();
  final _getManualBlocksUseCase = GetIt.I<GetManualBlocksByPeriodUseCase>();
  final _availabilityUseCase = GetIt.I<GetProfessionalAvailability>();
  final _professionalRepo = GetIt.I<ProfessionalRemoteDataSource>();
  final _getTenantConfig = GetIt.I<GetTenantConfigUseCase>();
  final _schedulingRepo = GetIt.I<SchedulingRepository>();

  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> professionals = [];
  Map<String, List<dynamic>> blocksByProfessional = {};
  Map<String, List<ManualBlock>> manualBlocksByProfessional = {};
  Map<String, Availability?> availabilityByProfessional = {};
  bool loading = true;
  /// 0 = Dia, 1 = Semana, 2 = Mês (igual agenda profissional)
  int _viewMode = 0;
  /// null = Multiprofissional (todos), não-null = 1 profissional
  String? _selectedProfessionalId;
  /// Horário de funcionamento do salão para o dia selecionado
  int _gridMinStart = 7 * 60;
  int _gridMaxEnd = 20 * 60;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MultiProfessionalAgendaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final pros = await _professionalRepo.getProfessionals();
      final daysSinceSunday = selectedDate.weekday == 7 ? 0 : selectedDate.weekday;
      final weekStart = selectedDate.subtract(Duration(days: daysSinceSunday));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final tenantId = _session.tenantId;

      final Map<String, List<dynamic>> blocks = {};
      final Map<String, List<ManualBlock>> manual = {};
      final Map<String, Availability?> avail = {};

      for (final p in pros) {
        final id = p['id'] as String?;
        if (id == null) continue;
        final bl = await _timeGridUseCase(
          professionalId: id,
          referenceDate: selectedDate,
          tenantId: tenantId,
        );
        blocks[id] = bl.where((b) => b.weekday == selectedDate.weekday).toList();
        manual[id] = await _getManualBlocksUseCase(
          professionalId: id,
          start: weekStart,
          end: weekEnd,
        );
        final avList = await _availabilityUseCase(id);
        Availability? a;
        for (final x in avList) {
          if (x.weekday == selectedDate.weekday) {
            a = x;
            break;
          }
        }
        Availability? resolved = a;
        if (resolved == null || !resolved.isActive || resolved.shifts.isEmpty) {
          if (tenantId != null) {
            final config = await _getTenantConfig(tenantId);
            resolved = _availabilityFromTenantConfig(config, selectedDate.weekday);
          }
        }
        avail[id] = resolved;
      }

      int gridMinStart = 7 * 60;
      int gridMaxEnd = 20 * 60;
      if (tenantId != null) {
        final config = await _getTenantConfig(tenantId);
        final ranges = config.getOpeningRangesMinutes(selectedDate.weekday);
        if (ranges.isNotEmpty) {
          gridMinStart = ranges.map((r) => r.start).reduce((a, b) => a < b ? a : b);
          gridMaxEnd = ranges.map((r) => r.end).reduce((a, b) => a > b ? a : b);
        }
      }

      if (mounted) {
        setState(() {
          professionals = pros;
          blocksByProfessional = blocks;
          manualBlocksByProfessional = manual;
          availabilityByProfessional = avail;
          _gridMinStart = gridMinStart;
          _gridMaxEnd = gridMaxEnd;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  DateTime _weekStart(DateTime date) {
    final daysSinceSunday = date.weekday == 7 ? 0 : date.weekday;
    return date.subtract(Duration(days: daysSinceSunday));
  }

  void _goToPreviousWeek() {
    setState(() => selectedDate = selectedDate.subtract(const Duration(days: 7)));
    _load();
  }

  void _goToNextWeek() {
    setState(() => selectedDate = selectedDate.add(const Duration(days: 7)));
    _load();
  }

  void _goToPreviousMonth() {
    setState(() {
      final d = selectedDate;
      selectedDate = DateTime(d.year, d.month - 1, d.day.clamp(1, 28));
    });
    _load();
  }

  void _goToNextMonth() {
    setState(() {
      final d = selectedDate;
      selectedDate = DateTime(d.year, d.month + 1, d.day.clamp(1, 28));
    });
    _load();
  }

  List<Map<String, dynamic>> get _displayProfessionals {
    if (_selectedProfessionalId == null) return professionals;
    final p = professionals.where((x) => (x['id'] as String?) == _selectedProfessionalId).toList();
    return p;
  }

  void _openCreateAppointment([String? professionalId, DateTime? slot]) {
    final resolvedSlot = slot ?? DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateAppointmentPage(
          initialDate: selectedDate,
          initialSlot: resolvedSlot,
          initialProfessionalId: professionalId,
        ),
      ),
    ).then((_) {
      if (mounted) _load();
    });
  }

  void _showAppointmentNotesSheet(TimeGridBlock block) async {
    final appointment = await _schedulingRepo.getById(block.appointmentId);
    if (!mounted || appointment == null) return;

    final notesController = TextEditingController(text: appointment.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(ctx).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Agendamento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(ctx),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${block.clientLabel} • ${block.serviceLabel}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground(ctx),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Anotações',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(ctx),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ex: Larissa atender Cleid, observações internas...',
                filled: true,
                fillColor: AppColors.fillColor(ctx),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Fechar', style: TextStyle(color: AppColors.mutedForeground(ctx))),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _schedulingRepo.updateAppointmentNotes(
                        appointmentId: block.appointmentId,
                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        _load();
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Anotações salvas')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary(context),
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final weekStart = _weekStart(selectedDate);
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            /// Linha 1: Profissional | Multiprofissional (50% cada)
            /// 1 profissional só = fica só um; vários = seleciona no próprio chip (popup)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _OneProfessionalChip(
                        professionals: professionals,
                        selectedId: _selectedProfessionalId,
                        onSelected: (id) => setState(() => _selectedProfessionalId = id),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ViewChip(
                        label: 'Multiprofissional',
                        selected: _selectedProfessionalId == null,
                        onTap: () => setState(() => _selectedProfessionalId = null),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            /// Linha 2: Hoje | Semana | Mês (33% cada)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _ViewChip(
                        label: 'Hoje',
                        selected: _sameDay(selectedDate, DateTime.now()),
                        onTap: () {
                          setState(() => selectedDate = DateTime.now());
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ViewChip(
                        label: 'Semana',
                        selected: _viewMode == 1,
                        onTap: () => setState(() => _viewMode = 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ViewChip(
                        label: 'Mês',
                        selected: _viewMode == 2,
                        onTap: () => setState(() => _viewMode = 2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            /// Navegação mês + setas (igual agenda profissional)
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
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null && mounted) {
                          setState(() => selectedDate = picked);
                          _load();
                        }
                      },
                      child: Text(
                        DateFormat.yMMMM('pt_BR').format(selectedDate),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
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
            /// Calendário mensal quando Mês
            if (_viewMode == 2)
              SliverToBoxAdapter(
                child: _buildMonthCalendar(weekStart),
              )
            else
              SliverToBoxAdapter(
                child: Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    border: Border(top: BorderSide(color: AppColors.border(context), width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _buildDaySelector(),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: _buildGrid(),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _openCreateAppointment(_selectedProfessionalId),
            backgroundColor: AppColors.primary(context),
            child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthCalendar(DateTime weekStart) {
    const dayLabels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    final monthStart = DateTime(selectedDate.year, selectedDate.month, 1);
    final calendarStart = _weekStart(monthStart);
    final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final weeks = ((lastDay.difference(calendarStart).inDays + 1) / 7).ceil().clamp(4, 6);

    return Container(
      color: AppColors.card(context),
      padding: const EdgeInsets.all(12),
      child: Table(
        columnWidths: {for (var i = 0; i < 7; i++) i: const FlexColumnWidth(1)},
        children: [
          TableRow(
            children: dayLabels.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: Text(l, style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedForeground(context),
                )),
              ),
            )).toList(),
          ),
          ...List.generate(weeks, (wi) => TableRow(
            children: List.generate(7, (di) {
              final day = calendarStart.add(Duration(days: wi * 7 + di));
              final isCurrentMonth = day.month == selectedDate.month;
              final isSelected = _sameDay(day, selectedDate);
              final isToday = _sameDay(day, DateTime.now());
              return GestureDetector(
                onTap: () {
                  setState(() => selectedDate = day);
                  _load();
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  height: 48,
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
          )),
        ],
      ),
    );
  }

  List<Widget> _buildDaySelector() {
    final daysSinceSunday = selectedDate.weekday == 7 ? 0 : selectedDate.weekday;
    final weekStart = selectedDate.subtract(Duration(days: daysSinceSunday));
    const dayNames = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return List.generate(7, (i) {
      final d = weekStart.add(Duration(days: i));
      final isSelected = _sameDay(d, selectedDate);
      final isToday = _sameDay(d, DateTime.now());
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() => selectedDate = d);
            _load();
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayNames[i],
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
                  border: isToday
                      ? Border.all(color: AppColors.primary(context), width: 1)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${d.day}',
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
    });
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

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

  Widget _buildGrid() {
    final displayPros = _displayProfessionals;
    if (displayPros.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nenhum profissional no tenant.'),
        ),
      );
    }

    // Expandir grid para incluir agendamentos fora do expediente
    int blockMin = 24 * 60;
    int blockMax = 0;
    for (final id in blocksByProfessional.keys) {
      for (final block in blocksByProfessional[id] ?? []) {
        final start = block.startMinutes;
        final end = start + block.durationMinutes;
        if (start < blockMin) blockMin = start;
        if (end > blockMax) blockMax = end;
      }
    }
    final dayStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    for (final id in manualBlocksByProfessional.keys) {
      for (final b in manualBlocksByProfessional[id] ?? []) {
        if (b.end.isBefore(dayStart) || b.start.isAfter(dayEnd)) continue;
        final blockStart = b.start.isBefore(dayStart) ? dayStart : b.start;
        final blockEnd = b.end.isAfter(dayEnd) ? dayEnd : b.end;
        final startMin = blockStart.hour * 60 + blockStart.minute;
        final endMin = blockEnd.hour * 60 + blockEnd.minute;
        if (startMin < blockMin) blockMin = startMin;
        if (endMin > blockMax) blockMax = endMin;
      }
    }
    const margin = 60;
    int minStart = _gridMinStart;
    int maxEnd = _gridMaxEnd;
    if (blockMax > blockMin) {
      final rangeMin = (blockMin - margin).clamp(0, 24 * 60);
      final rangeMax = (blockMax + margin).clamp(0, 24 * 60);
      if (rangeMin < minStart) minStart = rangeMin;
      if (rangeMax > maxEnd) maxEnd = rangeMax;
    }
    if (maxEnd <= minStart) {
      minStart = 7 * 60;
      maxEnd = 20 * 60;
    }
    final int totalMinutes = (maxEnd - minStart).clamp(60, 24 * 60);
    const int slotIntervalMinutes = 30;
    const double slotHeight = 40;
    final int slotCount = (totalMinutes / slotIntervalMinutes).ceil();
    final double baseTotalHeight = slotCount * slotHeight;
    /// Escala para blocos com muito conteúdo (anotações longas)
    double scale = 1.0;
    for (final id in blocksByProfessional.keys) {
      for (final block in blocksByProfessional[id] ?? []) {
        final proportionalHeight = (block.durationMinutes / totalMinutes) * baseTotalHeight;
        const minHourHeight = slotHeight * 2;
        final blockHeight = proportionalHeight >= minHourHeight ? proportionalHeight : minHourHeight;
        final notesLen = block.notes?.length ?? 0;
        const baseContent = 58.0; // status + client + service
        final notesContent = notesLen > 0 ? (22.0 + (notesLen / 16).ceil() * 14.0) : 0.0;
        final minContentHeight = baseContent + notesContent;
        if (minContentHeight > blockHeight) {
          final s = minContentHeight / blockHeight;
          if (s > scale) scale = s;
        }
      }
    }
    final effectiveSlotHeight = slotHeight * scale;
    final totalHeight = baseTotalHeight * scale;
    final showNameHeader = displayPros.length > 1;
    const headerHeight = 48.0;
    /// 1 profissional = tela toda; 2 = divide 50/50; 3 = divide em 3; etc.
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        SizedBox(
          width: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showNameHeader) SizedBox(height: headerHeight),
              ...List.generate(
              slotCount,
              (index) {
                final minutes = minStart + index * slotIntervalMinutes;
                final hour = minutes ~/ 60;
                final minute = minutes % 60;
                return SizedBox(
                  height: effectiveSlotHeight,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: showNameHeader
                        ? Transform.translate(
                            offset: const Offset(0, -16),
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 11, color: AppColors.mutedForeground(context)),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 11, color: AppColors.mutedForeground(context)),
                            ),
                          ),
                  ),
                );
              },
            ),
            ],
          ),
        ),
        Expanded(
          child: SizedBox(
            height: totalHeight + (displayPros.length > 1 ? 48 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(displayPros.length, (index) {
              final p = displayPros[index];
              final id = p['id'] as String? ?? '';
              final name = p['name'] as String? ?? 'Sem nome';
              final blocks = blocksByProfessional[id] ?? [];
              final manualBlocks = manualBlocksByProfessional[id] ?? [];
              final availability = availabilityByProfessional[id];
              final noWork = availability == null || !availability.isActive;
              final showNameHeader = displayPros.length > 1;
              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showNameHeader)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.border(context)),
                          ),
                        ),
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: noWork ? AppColors.mutedForeground(context) : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    SizedBox(
                      height: totalHeight,
                      child: Stack(
                        children: [
                          /// Tap em área vazia para criar agendamento
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTapUp: (details) {
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
                                _openCreateAppointment(id, slot);
                              },
                            ),
                          ),
                          /// GRID - linhas apenas em hora cheia, alinhadas ao topo do slot (padrão agenda profissional)
                          Column(
                            children: List.generate(
                              slotCount,
                              (index) {
                                final slotStartMinutes = minStart + index * slotIntervalMinutes;
                                final isFullHour = slotStartMinutes % 60 == 0;
                                return Container(
                                  height: effectiveSlotHeight,
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
                          ..._manualBlocksForDay(
                            manualBlocks,
                            selectedDate,
                            minStart,
                            totalMinutes,
                            totalHeight,
                          ),
                          ...blocks.map((block) {
                            final top = ((block.startMinutes - minStart) /
                                    totalMinutes) *
                                totalHeight;
                            final proportionalHeight = (block.durationMinutes /
                                    totalMinutes) *
                                totalHeight;
                            final minHourHeight = effectiveSlotHeight * 2; // 1h padrão
                            final blockHeight = proportionalHeight >= minHourHeight
                                ? proportionalHeight
                                : minHourHeight;
                            return Positioned(
                              top: top,
                              left: 4,
                              right: 4,
                              height: blockHeight,
                              child: GestureDetector(
                                onTap: () => _showAppointmentNotesSheet(block),
                                child: _blockChip(block),
                              ),
                            );
                          }),
                          if (noWork)
                            Positioned.fill(
                              child: Container(
                                color: AppColors.mutedForeground(context).withValues(alpha: 0.15),
                                alignment: Alignment.center,
                                child: Text(
                                  'Não atende',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.mutedForeground(context),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
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
    final maxEnd = minStart + totalMinutes;
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
          left: 4,
          right: 4,
          height: height.clamp(20.0, double.infinity),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.warning(context).withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.warning(context)),
            ),
            alignment: Alignment.center,
            child: Text(
              b.label,
              style: TextStyle(fontSize: 10, color: AppColors.warning(context)),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return list;
  }

  Color _colorForBlockStatus(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.completed:
        return AppColors.success(context);
      case AppointmentStatus.approved:
        return AppColors.primary(context);
      case AppointmentStatus.pending:
      case AppointmentStatus.rescheduleRequested:
        return AppColors.warning(context);
      case AppointmentStatus.cancelled:
      case AppointmentStatus.rejected:
        return AppColors.error(context);
      case AppointmentStatus.noShow:
      case AppointmentStatus.waitingList:
        return AppColors.mutedForeground(context);
    }
  }

  Widget _blockChip(TimeGridBlock block) {
    final Color color = _colorForBlockStatus(block.status);
    final textColor = AppColors.textPrimary(context);
    final startH = block.startMinutes ~/ 60;
    final startM = block.startMinutes % 60;
    final endMinutes = block.startMinutes + block.durationMinutes;
    final endH = endMinutes ~/ 60;
    final endM = endMinutes % 60;
    final timeStr =
        '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')} - '
        '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.access_time_rounded, size: 10, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${block.statusLabel} • $timeStr',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.person_outline_rounded, size: 10, color: textColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  block.clientLabel.isNotEmpty ? block.clientLabel : 'Cliente',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: textColor),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.settings_outlined, size: 10, color: textColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  block.serviceLabel.isNotEmpty ? block.serviceLabel : 'Serviço',
                  style: TextStyle(fontSize: 10, color: textColor),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          if (block.notes != null && block.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note_outlined, size: 10, color: AppColors.mutedForeground(context)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    block.notes!,
                    style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.mutedForeground(context)),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ViewChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(
            color: selected ? AppColors.primary(context) : AppColors.border(context),
            width: selected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.primary(context) : AppColors.mutedForeground(context),
          ),
        ),
      ),
    );
  }
}

class _OneProfessionalChip extends StatelessWidget {
  final List<Map<String, dynamic>> professionals;
  final String? selectedId;
  final void Function(String?) onSelected;

  const _OneProfessionalChip({
    required this.professionals,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hasOne = professionals.length == 1;
    final isSelected = selectedId != null;
    final displayName = selectedId != null
        ? (professionals.where((p) => (p['id'] as String?) == selectedId).firstOrNull?['name'] as String? ?? 'Profissional')
        : 'Profissional';

    if (professionals.isEmpty) {
      return _ViewChip(label: 'Profissional', selected: false, onTap: () {});
    }

    if (hasOne) {
      return _ViewChip(
        label: displayName,
        selected: isSelected,
        onTap: () => onSelected(professionals.first['id'] as String?),
      );
    }

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(
            color: isSelected ? AppColors.primary(context) : AppColors.border(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                isSelected ? displayName : 'Profissional',
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary(context) : AppColors.mutedForeground(context),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: AppColors.mutedForeground(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Selecionar profissional',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(ctx),
                ),
              ),
            ),
            ...professionals.map((p) {
              final id = p['id'] as String?;
              final name = (p['name'] as String?) ?? 'Sem nome';
              final isSelected = id == selectedId;
              return ListTile(
                title: Text(name),
                trailing: isSelected ? Icon(Icons.check, color: AppColors.primary(ctx)) : null,
                onTap: () {
                  onSelected(id);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
