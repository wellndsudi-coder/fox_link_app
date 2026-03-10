import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_timegrid_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';

/// Payload for drag and drop
class AppointmentDragPayload {
  final String appointmentId;
  final int durationMinutes;

  const AppointmentDragPayload({
    required this.appointmentId,
    required this.durationMinutes,
  });
}

class AppointmentBlock extends StatefulWidget {
  final TimeGridBlock block;
  final DateTime date;
  final int minStartMinutes;
  final int totalMinutes;
  final double totalHeight;
  final VoidCallback onTap;
  final Future<void> Function(DateTime newStart, DateTime newEnd)? onTimeChanged;

  const AppointmentBlock({
    super.key,
    required this.block,
    required this.date,
    required this.minStartMinutes,
    required this.totalMinutes,
    required this.totalHeight,
    required this.onTap,
    this.onTimeChanged,
  });

  @override
  State<AppointmentBlock> createState() => _AppointmentBlockState();
}

class _AppointmentBlockState extends State<AppointmentBlock> {
  Color _colorForStatus(BuildContext context, AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.completed:
        return AppColors.success(context);
      case AppointmentStatus.approved:
        return AppColors.primary(context);
      case AppointmentStatus.pending:
        return AppColors.warning(context);
      case AppointmentStatus.cancelled:
        return AppColors.error(context);
      case AppointmentStatus.noShow:
        return AppColors.mutedForeground(context);
      default:
        return AppColors.mutedForeground(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForStatus(context, widget.block.status);
    final startHour = widget.block.startMinutes ~/ 60;
    final startMinute = widget.block.startMinutes % 60;
    final endMinutes = widget.block.startMinutes + widget.block.durationMinutes;
    final endHour = endMinutes ~/ 60;
    final endMinute = endMinutes % 60;
    final timeLabel =
        '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')} - '
        '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

    final content = Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: color.withValues(alpha: 0.25),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_rounded, size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  timeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline_rounded, size: 12, color: AppColors.textPrimary(context)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.block.clientLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.textPrimary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.settings_outlined, size: 12, color: AppColors.mutedForeground(context)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.block.serviceLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedForeground(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final canEdit = widget.onTimeChanged != null &&
        (widget.block.status == AppointmentStatus.approved ||
            widget.block.status == AppointmentStatus.pending);

    if (!canEdit) {
      return GestureDetector(
        onTap: widget.onTap,
        child: SizedBox.expand(child: content),
      );
    }

    return Expanded(
      child: LongPressDraggable<AppointmentDragPayload>(
            data: AppointmentDragPayload(
              appointmentId: widget.block.appointmentId,
              durationMinutes: widget.block.durationMinutes,
            ),
            feedback: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 140,
                child: Opacity(
                  opacity: 0.9,
                  child: content,
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.5,
              child: content,
            ),
            onDragStarted: () {},
            onDragEnd: (_) {},
            child: GestureDetector(
              onTap: widget.onTap,
              child: SizedBox.expand(child: content),
            ),
          ),
    );
  }
}
