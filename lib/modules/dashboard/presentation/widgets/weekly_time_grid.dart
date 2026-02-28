import 'package:flutter/material.dart';
import '../../domain/usecases/get_weekly_timegrid_usecase.dart';

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
    final gridHeight = totalHours * hourHeight;

    return Container(
      color: const Color(0xFF0F172A),
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
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),

                /// 🔹 Linhas horizontais
                Column(
                  children: List.generate(
                    totalHours.toInt(),
                        (i) => Container(
                      height: hourHeight,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade800,
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

                  return Positioned(
                    top: top,
                    left: 4,
                    right: 4,
                    height: height,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Agendamento",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ),
    );
  }
}