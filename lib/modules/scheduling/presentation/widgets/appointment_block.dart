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
  static const int _snapMinutes = 15;
  static const int _minDurationMinutes = 5;

  double _topDeltaPx = 0;
  double _bottomDeltaPx = 0;

  Color _colorForStatus(BuildContext context, AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.approved:
        return AppColors.success(context);
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

  int _snapToGrid(int minutes) {
    final m = (minutes / _snapMinutes).round() * _snapMinutes;
    return m.clamp(0, 24 * 60);
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
      padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(timeLabel, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            widget.block.clientLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            widget.block.serviceLabel,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
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
        child: content,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (details) {
            setState(() {
              _topDeltaPx += details.delta.dy;
            });
          },
          onVerticalDragEnd: (_) => _applyResize(isTop: true),
          child: SizedBox(
            height: 12,
            child: Center(
              child: Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        Expanded(
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
              child: content,
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (details) {
            setState(() {
              _bottomDeltaPx += details.delta.dy;
            });
          },
          onVerticalDragEnd: (_) => _applyResize(isTop: false),
          child: SizedBox(
            height: 12,
            child: Center(
              child: Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _applyResize({required bool isTop}) async {
    if (widget.onTimeChanged == null) return;
    final th = widget.totalHeight;
    final tm = widget.totalMinutes.toDouble();
    if (th <= 0 || tm <= 0) return;
    final minutesPerPx = tm / th;
    int newStartMinutes = widget.block.startMinutes;
    int newEndMinutes = widget.block.startMinutes + widget.block.durationMinutes;
    if (isTop) {
      final deltaM = (_topDeltaPx * minutesPerPx).round();
      newStartMinutes = (widget.block.startMinutes + deltaM)
          .clamp(widget.minStartMinutes, newEndMinutes - _minDurationMinutes);
      newStartMinutes = _snapToGrid(newStartMinutes);
      newEndMinutes = (widget.block.startMinutes + widget.block.durationMinutes)
          .clamp(newStartMinutes + _minDurationMinutes, 24 * 60);
    } else {
      final deltaM = (_bottomDeltaPx * minutesPerPx).round();
      newEndMinutes = (widget.block.startMinutes + widget.block.durationMinutes + deltaM)
          .clamp(newStartMinutes + _minDurationMinutes, 24 * 60);
      newEndMinutes = _snapToGrid(newEndMinutes);
      newStartMinutes = widget.block.startMinutes
          .clamp(widget.minStartMinutes, newEndMinutes - _minDurationMinutes);
    }
    setState(() {
      _topDeltaPx = 0;
      _bottomDeltaPx = 0;
    });
    final newStart = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      newStartMinutes ~/ 60,
      newStartMinutes % 60,
    );
    final newEnd = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      newEndMinutes ~/ 60,
      newEndMinutes % 60,
    );
    await widget.onTimeChanged!(newStart, newEnd);
  }
}
