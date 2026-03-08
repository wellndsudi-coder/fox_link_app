import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/get_first_available_slot_usecase.dart';
import 'package:fox_link_app/modules/services/domain/usecases/get_services.dart';
import 'package:fox_link_app/shared/widgets/app_button.dart';
import 'package:fox_link_app/shared/widgets/app_card.dart';

class FirstAvailableSlotCard extends StatefulWidget {
  final void Function(int pageIndex)? onNavigateToPage;

  const FirstAvailableSlotCard({this.onNavigateToPage});

  @override
  State<FirstAvailableSlotCard> createState() => _FirstAvailableSlotCardState();
}

class _FirstAvailableSlotCardState extends State<FirstAvailableSlotCard> {
  final _getFirstSlot = GetIt.I<GetFirstAvailableSlotUseCase>();
  final _getServices = GetIt.I<GetServices>();
  final _session = GetIt.I<TenantSession>();

  String? _selectedServiceId;
  List<({String id, String name})> _services = [];
  Map<String, dynamic>? _slotResult;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final tenantId = _session.tenantId;
    if (tenantId == null) return;
    final list = await _getServices(tenantId);
    setState(() {
      _services = list
          .where((s) => s.isActive)
          .map((s) => (id: s.id, name: s.name.value))
          .toList();
      if (_services.isNotEmpty && _selectedServiceId == null) {
        _selectedServiceId = _services.first.id;
      }
    });
  }

  Future<void> _fetchFirstSlot() async {
    if (_selectedServiceId == null) return;
    setState(() {
      _loading = true;
      _slotResult = null;
    });
    try {
      final result = await _getFirstSlot(
        serviceId: _selectedServiceId!,
        clientId: _session.uid,
      );
      setState(() {
        _slotResult = result != null
            ? {
                'slot': result.slot,
                'professionalName': result.professionalName,
                'serviceId': result.serviceId,
              }
            : {'empty': true};
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _slotResult = {'error': true};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_services.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Primeiro horário disponível',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedServiceId,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(),
            ),
            items: _services
                .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedServiceId = v),
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Ver primeiro horário livre',
            onPressed: _loading ? null : _fetchFirstSlot,
            isLoading: _loading,
          ),
          if (_slotResult != null) ...[
            const SizedBox(height: 12),
            _slotResult!['empty'] == true
                ? Text(
                    'Nenhum horário disponível nos próximos dias.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedForeground(context),
                    ),
                  )
                : _slotResult!['error'] == true
                    ? Text(
                        'Erro ao buscar horários.',
                        style: TextStyle(color: theme.colorScheme.error),
                      )
                    : Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${DateFormat('EEEE, d/MM', 'pt_BR').format(_slotResult!['slot'])} às ${DateFormat('HH:mm').format(_slotResult!['slot'])}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Com ${_slotResult!['professionalName']}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.mutedForeground(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => widget.onNavigateToPage?.call(1),
                              child: const Text('Agendar neste horário'),
                            ),
                          ],
                        ),
                      ),
          ],
        ],
      ),
    );
  }
}
