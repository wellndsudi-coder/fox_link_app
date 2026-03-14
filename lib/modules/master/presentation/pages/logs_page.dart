import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/modules/master/presentation/controllers/master_controller.dart';

class MasterLogsPage extends StatefulWidget {
  final MasterController controller;

  const MasterLogsPage({super.key, required this.controller});

  @override
  State<MasterLogsPage> createState() => _MasterLogsPageState();
}

class _MasterLogsPageState extends State<MasterLogsPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.loading && widget.controller.logs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = widget.controller.logs;
        return RefreshIndicator(
          onRefresh: () => widget.controller.loadLogs(),
          child: logs.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: const SizedBox(
                    height: 200,
                    child: Center(child: Text('Nenhum log registrado')),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, i) {
                    final log = logs[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          _iconForType(log.type),
                          color: AppColors.mutedForeground(context),
                        ),
                        title: Text(log.message),
                        subtitle: Text(
                          '${log.type} · ${_fmt(log.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedForeground(context),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  IconData _iconForType(String t) {
    switch (t.toLowerCase()) {
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
