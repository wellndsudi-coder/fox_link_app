import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';

import '../../domain/usecases/get_weekly_timegrid_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';

class WeeklyTimeGrid extends StatelessWidget {
  final List<TimeGridBlock> blocks;

  const WeeklyTimeGrid({
    super.key,
    required this.blocks,
  });

  static const double startHour = 7;
  static const double endHour = 20;
  static const double hourHeight = 80;

  @override
  Widget build(BuildContext context) {
    final totalHours = endHour - startHour;
    final baseGridHeight = totalHours * hourHeight;
    double scale = 1.0;
    for (final block in blocks) {
      final blockHeight = baseGridHeight * block.heightFactor;
      final notesLen = block.notes?.length ?? 0;
      const baseContent = 58.0;
      final notesContent = notesLen > 0 ? (22.0 + ((notesLen / 16).ceil() * 14.0)) : 0.0;
      final minContentHeight = baseContent + notesContent;
      if (minContentHeight > blockHeight) {
        final s = minContentHeight / blockHeight;
        if (s > scale) scale = s;
      }
    }
    final effectiveHourHeight = hourHeight * scale;
    final gridHeight = totalHours * effectiveHourHeight;

    return SingleChildScrollView(
      child: Container(
      color: AppColors.background(context),
      child: Row(
        children: List.generate(7, (index) {
          final weekday = index + 1;

          final dayBlocks = blocks
              .where((b) => b.weekday == weekday)
              .toList();

          return Expanded(
            child: Stack(
              children: [

                /// 🔹 Fundo da coluna
                Container(
                  height: gridHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: AppColors.border(context),
                      ),
                    ),
                  ),
                ),

                /// 🔹 Linhas horizontais
                Column(
                  children: List.generate(
                    totalHours.toInt(),
                        (i) => Container(
                      height: effectiveHourHeight,
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

                /// 🔹 Blocos de agendamento
                ...dayBlocks.map((block) {
                  final top = gridHeight * block.topFactor;
                  final height = gridHeight * block.heightFactor;
                  Color color = AppColors.mutedForeground(context);
                  switch (block.status) {
                    case AppointmentStatus.approved:
                      color = AppColors.success(context);
                      break;
                    case AppointmentStatus.pending:
                      color = AppColors.primary(context);
                      break;
                    case AppointmentStatus.completed:
                      color = AppColors.success(context);
                      break;
                    case AppointmentStatus.cancelled:
                      color = AppColors.error(context);
                      break;
                    default:
                      break;
                  }
                  final startH = block.startMinutes ~/ 60;
                  final startM = block.startMinutes % 60;
                  final endM = block.startMinutes + block.durationMinutes;
                  final endH = endM ~/ 60;
                  final endMin = endM % 60;
                  final timeStr = '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')} - ${endH.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}';
                  return Positioned(
                    top: top,
                    left: 4,
                    right: 4,
                    height: height,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${block.statusLabel} • $timeStr', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color), softWrap: true),
                          const SizedBox(height: 4),
                          Text(block.clientLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)), softWrap: true),
                          Text(block.serviceLabel, style: TextStyle(fontSize: 10, color: AppColors.mutedForeground(context)), softWrap: true),
                          if (block.notes != null && block.notes!.isNotEmpty)
                            Text(block.notes!, style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.mutedForeground(context)), softWrap: true),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ),
    ),
    );
  }
}