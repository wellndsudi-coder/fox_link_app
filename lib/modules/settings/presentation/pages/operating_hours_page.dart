import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/tenant/domain/entities/tenant_config.dart';
import 'package:fox_link_app/modules/tenant/domain/usecases/get_tenant_config_usecase.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';

TimeOfDay _parseTime(String s) {
  final parts = s.split(':');
  final h = int.tryParse(parts[0]) ?? 9;
  final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
}

String _formatTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

class OperatingHoursPage extends StatefulWidget {
  const OperatingHoursPage({super.key});

  @override
  State<OperatingHoursPage> createState() => _OperatingHoursPageState();
}

class _OperatingHoursPageState extends State<OperatingHoursPage> {
  static const _weekdayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  final _tenantRemote = getIt<TenantRemoteDataSource>();
  final _session = getIt<TenantSession>();
  final _getTenantConfig = getIt<GetTenantConfigUseCase>();

  bool _loading = false;
  OpeningHoursMap _openingHours = {};

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    if (_session.tenantId == null) return;
    setState(() => _loading = true);
    try {
      final config = await _getTenantConfig(_session.tenantId!);
      if (!mounted) return;
      setState(() {
        _openingHours = Map.from(config.openingHours);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setDayHours(int weekday, List<TimeRangeConfig> ranges) {
    setState(() {
      if (ranges.isEmpty) {
        _openingHours.remove(weekday);
      } else {
        _openingHours[weekday] = List.from(ranges);
      }
    });
  }

  Future<void> _save() async {
    if (_session.tenantId == null) return;
    setState(() => _loading = true);
    try {
      await _tenantRemote.updateTenantConfig(
        tenantId: _session.tenantId!,
        openingHours: TenantConfig.openingHoursToMap(_openingHours),
      );
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horários salvos')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horário de funcionamento')),
      body: _loading && _openingHours.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Horário de funcionamento',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(7, (i) {
                          final weekday = i + 1;
                          final label = _weekdayLabels[i];
                          final ranges = _openingHours[weekday] ?? [];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _DayHoursRow(
                              label: label,
                              ranges: ranges,
                              onChanged: (r) => _setDayHours(weekday, r),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: _loading ? null : _save,
                            child: const Text('Salvar horários'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DayHoursRow extends StatefulWidget {
  final String label;
  final List<TimeRangeConfig> ranges;
  final void Function(List<TimeRangeConfig>) onChanged;

  const _DayHoursRow({
    required this.label,
    required this.ranges,
    required this.onChanged,
  });

  @override
  State<_DayHoursRow> createState() => _DayHoursRowState();
}

class _DayHoursRowState extends State<_DayHoursRow> {
  late TimeOfDay _start;
  late TimeOfDay _end;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _syncFromRanges();
  }

  @override
  void didUpdateWidget(_DayHoursRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ranges != widget.ranges) _syncFromRanges();
  }

  void _syncFromRanges() {
    final r = widget.ranges.isNotEmpty ? widget.ranges.first : null;
    _closed = widget.ranges.isEmpty;
    _start = _parseTime(r?.start ?? '09:00');
    _end = _parseTime(r?.end ?? '18:00');
  }

  void _apply() {
    if (_closed) {
      widget.onChanged([]);
    } else {
      widget.onChanged([
        TimeRangeConfig(start: _formatTime(_start), end: _formatTime(_end)),
      ]);
    }
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _start,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary(context),
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _start = picked;
        _apply();
      });
    }
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _end,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary(context),
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _end = picked;
        _apply();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            widget.label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        Switch(
          value: !_closed,
          onChanged: (v) {
            setState(() {
              _closed = !v;
              _apply();
            });
          },
        ),
        if (_closed)
          Text('Fechado', style: TextStyle(color: AppColors.mutedForeground(context)))
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TimeChip(
                label: _formatTime(_start),
                onTap: _pickStart,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('-'),
              ),
              _TimeChip(
                label: _formatTime(_end),
                onTap: _pickEnd,
              ),
            ],
          ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TimeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fillColor(context),
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border(context)),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, size: 18, color: AppColors.mutedForeground(context)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
