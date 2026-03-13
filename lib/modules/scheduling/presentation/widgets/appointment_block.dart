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

  /// Texto do corpo deve ser sempre legível (contraste); status noShow/waitingList usam fundo cinza
  Color _bodyTextColor(BuildContext context) => AppColors.textPrimary(context);

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
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: color.withValues(alpha: 0.25),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.access_time_rounded, size: 12, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: RichText(
                    softWrap: true,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${widget.block.statusLabel} • ',
                          style: TextStyle(
                            fontSize: 10,
                            color: color.withValues(alpha: 0.9),
                          ),
                        ),
                        TextSpan(
                          text: timeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.person_outline_rounded, size: 12, color: _bodyTextColor(context)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.block.clientLabel.isNotEmpty
                                ? widget.block.clientLabel
                                : 'Cliente',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: _bodyTextColor(context),
                            ),
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.settings_outlined, size: 12, color: _bodyTextColor(context)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.block.serviceLabel.isNotEmpty
                                ? widget.block.serviceLabel
                                : 'Serviço',
                            style: TextStyle(
                              fontSize: 11,
                              color: _bodyTextColor(context),
                            ),
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    if (widget.block.notes != null && widget.block.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.note_outlined, size: 11, color: AppColors.mutedForeground(context)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.block.notes!,
                              style: TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: AppColors.mutedForeground(context),
                              ),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
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
