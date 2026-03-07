import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_timegrid_usecase.dart';
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/manual_block.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_manual_blocks_by_period_usecase.dart';
import 'package:fox_link_app/modules/availability/domain/usecases/get_professional_availability.dart';
import 'package:fox_link_app/modules/availability/domain/entities/availability.dart';

class MultiProfessionalAgendaPage extends StatefulWidget {
  const MultiProfessionalAgendaPage({super.key});

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

  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> professionals = [];
  Map<String, List<dynamic>> blocksByProfessional = {};
  Map<String, List<ManualBlock>> manualBlocksByProfessional = {};
  Map<String, Availability?> availabilityByProfessional = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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
        avail[id] = a;
      }

      if (mounted) {
        setState(() {
          professionals = pros;
          blocksByProfessional = blocks;
          manualBlocksByProfessional = manual;
          availabilityByProfessional = avail;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Linha do mês: setas + mês/ano (separada dos dias)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: AppColors.card(context),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        final d = selectedDate;
                        selectedDate = DateTime(d.year, d.month - 1, d.day.clamp(1, 28));
                      });
                      _load();
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
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
                        DateFormat('MMMM yyyy', 'pt_BR').format(selectedDate),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        final d = selectedDate;
                        selectedDate = DateTime(d.year, d.month + 1, d.day.clamp(1, 28));
                      });
                      _load();
                    },
                  ),
                ],
              ),
            ),
            // Linha dos dias da semana (abaixo do mês)
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.card(context),
                border: Border(
                  top: BorderSide(color: AppColors.border(context), width: 1),
                ),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: _buildDaySelector(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: _buildGrid(),
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () {
              // TODO: abrir tela de novo agendamento
            },
            backgroundColor: AppColors.primary(context),
            child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
      ],
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () {
            setState(() => selectedDate = d);
            _load();
          },
          child: Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent(context) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: isToday
                  ? Border.all(color: AppColors.primary(context), width: 1)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayNames[i],
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedForeground(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${d.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.accentForeground(context) : AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildGrid() {
    if (professionals.isEmpty) {
      return const Center(child: Text('Nenhum profissional no tenant.'));
    }

    const int minStart = 7 * 60;
    const int maxEnd = 20 * 60;
    const int totalMinutes = maxEnd - minStart;
    const double hourHeight = 56;
    final double totalHeight = (totalMinutes / 60) * hourHeight;
    const double columnWidth = 140;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Column(
            children: List.generate(
              (totalMinutes / 60).ceil(),
              (i) {
                final m = minStart + i * 60;
                return SizedBox(
                  height: hourHeight,
                  child: Text(
                    '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 11, color: AppColors.mutedForeground(context)),
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: totalHeight + 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: professionals.length,
              itemBuilder: (context, index) {
              final p = professionals[index];
              final id = p['id'] as String? ?? '';
              final name = p['name'] as String? ?? 'Sem nome';
              final blocks = blocksByProfessional[id] ?? [];
              final manualBlocks = manualBlocksByProfessional[id] ?? [];
              final availability = availabilityByProfessional[id];
              final noWork = availability == null || !availability.isActive;
              return SizedBox(
                width: columnWidth,
                child: Column(
                  children: [
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
                          Column(
                            children: List.generate(
                              (totalMinutes / 60).ceil(),
                              (_) => Container(
                                height: hourHeight,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppColors.border(context),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ..._manualBlocksForDay(
                            manualBlocks,
                            selectedDate,
                            minStart,
                            totalMinutes,
                            totalHeight,
                            columnWidth,
                          ),
                          ...blocks.map((block) {
                            final top = ((block.startMinutes - minStart) /
                                    totalMinutes) *
                                totalHeight;
                            final height = (block.durationMinutes /
                                    totalMinutes) *
                                totalHeight;
                            return Positioned(
                              top: top,
                              left: 4,
                              right: 4,
                              height: height.clamp(28.0, double.infinity),
                              child: _blockChip(block),
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
            },
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _manualBlocksForDay(
    List<ManualBlock> manualBlocks,
    DateTime day,
    int minStart,
    int totalMinutes,
    double totalHeight,
    double columnWidth,
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

  Widget _blockChip(block) {
    Color color;
    switch (block.status) {
      case AppointmentStatus.approved:
        color = AppColors.success(context);
        break;
      case AppointmentStatus.pending:
        color = AppColors.primary(context);
        break;
      case AppointmentStatus.cancelled:
        color = AppColors.error(context);
        break;
      default:
        color = AppColors.mutedForeground(context);
    }
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            block.clientLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            block.serviceLabel,
            style: const TextStyle(fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
