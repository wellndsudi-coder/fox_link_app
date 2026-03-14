import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';

/// Tabela reutilizável para o painel Master.
class MasterTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final bool isLoading;

  const MasterTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          AppColors.fillColor(context).withValues(alpha: 0.5),
        ),
        columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
        rows: rows.asMap().entries.map((e) {
          return DataRow(cells: e.value.asMap().entries.map((c) {
            return DataCell(c.value);
          }).toList());
        }).toList(),
      ),
    );
  }
}
