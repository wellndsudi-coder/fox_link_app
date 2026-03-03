import 'package:flutter/material.dart';
import '../../domain/entities/availability.dart';

enum DragType { left, right, move }

class WorkingHoursBar extends StatefulWidget {
  final List<TimeRange> shifts;
  final ValueChanged<List<TimeRange>> onChanged;

  const WorkingHoursBar({
    super.key,
    required this.shifts,
    required this.onChanged,
  });

  @override
  State<WorkingHoursBar> createState() => _WorkingHoursBarState();
}

class _WorkingHoursBarState extends State<WorkingHoursBar> {
  static const int visibleStart = 360;  // 06:00
  static const int visibleEnd = 1380;   // 23:00
  static const int snap = 10;
  static const int defaultDuration = 60;
  static const double handleZone = 18;

  int? _draggingIndex;
  DragType? _dragType;
  late List<TimeRange> _tempShifts;

  double _pxPerMinute = 1;

  @override
  void initState() {
    super.initState();
    _tempShifts = [...widget.shifts];
  }

  @override
  void didUpdateWidget(covariant WorkingHoursBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shifts != widget.shifts) {
      _tempShifts = [...widget.shifts];
    }
  }

  bool _conflicts(int index, int start, int end) {
    for (int i = 0; i < _tempShifts.length; i++) {
      if (i == index) continue;
      final s = _tempShifts[i];
      if (start < s.endMinutes && end > s.startMinutes) {
        return true;
      }
    }
    return false;
  }

  String _format(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return "$h:$m";
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {

        final width = constraints.maxWidth;
        final totalMinutes = visibleEnd - visibleStart;
        _pxPerMinute = width / totalMinutes;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔥 Horários laterais
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: const [
                Text("06:00",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey)),
                Text("23:00",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey)),
              ],
            ),

            const SizedBox(height: 6),

            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {

                if (_draggingIndex != null) return;

                final minute =
                    visibleStart +
                        (details.localPosition.dx /
                            _pxPerMinute)
                            .round();

                final snapped =
                    (minute / snap).round() * snap;

                int end = snapped + defaultDuration;
                if (end > visibleEnd) end = visibleEnd;

                for (final s in _tempShifts) {
                  if (snapped < s.endMinutes &&
                      end > s.startMinutes) {
                    return;
                  }
                }

                final updated = [
                  ..._tempShifts,
                  TimeRange(
                    startMinutes: snapped,
                    endMinutes: end,
                  )
                ];

                updated.sort((a, b) =>
                    a.startMinutes
                        .compareTo(b.startMinutes));

                widget.onChanged(updated);
              },
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius:
                  BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [

                    // 🔥 Trilho pontilhado
                    CustomPaint(
                      size: Size(width, 70),
                      painter:
                      _DottedLinePainter(),
                    ),

                    for (int i = 0;
                    i < _tempShifts.length;
                    i++)
                      _buildShift(i),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShift(int index) {
    final shift = _tempShifts[index];

    final left =
        (shift.startMinutes - visibleStart) *
            _pxPerMinute;

    final width =
        (shift.endMinutes -
            shift.startMinutes) *
            _pxPerMinute;

    return Positioned(
      left: left,
      width: width,
      top: 8,
      bottom: 8,
      child: GestureDetector(
        onPanStart: (details) {
          final localX = details.localPosition.dx;

          if (localX <= handleZone) {
            _dragType = DragType.left;
          } else if (localX >=
              width - handleZone) {
            _dragType = DragType.right;
          } else {
            _dragType = DragType.move;
          }

          _draggingIndex = index;
        },
        onPanUpdate: (details) {

          if (_draggingIndex == null) return;

          final deltaMinutes =
              details.delta.dx / _pxPerMinute;

          int newStart = shift.startMinutes;
          int newEnd = shift.endMinutes;

          if (_dragType == DragType.left) {
            newStart += deltaMinutes.round();
            if (newStart < visibleStart) return;
            if (newStart >= newEnd - 1) return;
            if (_conflicts(index, newStart, newEnd)) return;

            _tempShifts[index] = TimeRange(
              startMinutes: newStart,
              endMinutes: newEnd,
            );
          }

          if (_dragType == DragType.right) {
            newEnd += deltaMinutes.round();
            if (newEnd > visibleEnd) return;
            if (newEnd <= newStart + 1) return;
            if (_conflicts(index, newStart, newEnd)) return;

            _tempShifts[index] = TimeRange(
              startMinutes: newStart,
              endMinutes: newEnd,
            );
          }

          if (_dragType == DragType.move) {
            newStart += deltaMinutes.round();
            newEnd += deltaMinutes.round();

            if (newStart < visibleStart ||
                newEnd > visibleEnd) return;

            if (_conflicts(index, newStart, newEnd)) return;

            _tempShifts[index] = TimeRange(
              startMinutes: newStart,
              endMinutes: newEnd,
            );
          }

          setState(() {});
        },
        onPanEnd: (_) {

          final snappedStart =
              (_tempShifts[index]
                  .startMinutes /
                  snap)
                  .round() *
                  snap;

          final snappedEnd =
              (_tempShifts[index]
                  .endMinutes /
                  snap)
                  .round() *
                  snap;

          _tempShifts[index] =
              TimeRange(
                startMinutes: snappedStart,
                endMinutes: snappedEnd,
              );

          widget.onChanged(_tempShifts);

          _draggingIndex = null;
          _dragType = null;
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [

            Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius:
                BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                "${_format(shift.startMinutes)} - ${_format(shift.endMinutes)}",
                style:
                const TextStyle(
                  color: Colors.white,
                  fontWeight:
                  FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),

            if (_draggingIndex ==
                index)
              Positioned(
                top: -32,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                        horizontal: 8,
                        vertical: 4),
                    decoration:
                    BoxDecoration(
                      color:
                      Colors.black87,
                      borderRadius:
                      BorderRadius
                          .circular(8),
                    ),
                    child: Text(
                      "${_format(shift.startMinutes)} - ${_format(shift.endMinutes)}",
                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DottedLinePainter
    extends CustomPainter {
  @override
  void paint(
      Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    const dashWidth = 4;
    const dashSpace = 6;

    double startX = 0;

    final y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(
          Offset(startX, y),
          Offset(startX + dashWidth, y),
          paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate) =>
      false;
}