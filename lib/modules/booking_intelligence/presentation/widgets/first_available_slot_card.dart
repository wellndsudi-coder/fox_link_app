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
  final void Function({
    required DateTime slot,
    required String professionalId,
    required String professionalName,
    required String serviceId,
  })? onAgendarWithSlot;

  const FirstAvailableSlotCard({
    this.onNavigateToPage,
    this.onAgendarWithSlot,
  });

  @override
  State<FirstAvailableSlotCard> createState() => _FirstAvailableSlotCardState();
}

class _FirstAvailableSlotCardState extends State<FirstAvailableSlotCard> {
  final _getFirstSlot = GetIt.I<GetFirstAvailableSlotUseCase>();
  final _getServices = GetIt.I<GetServices>();
  final _session = GetIt.I<TenantSession>();

  String? _selectedServiceId;
  List<({String id, String name})> _services = [];
  List<({DateTime slot, String professionalName, String professionalId, String serviceId})>? _slotList;
  bool _loading = false;
  bool _slotError = false;

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

  Future<void> _fetchFirstSlots() async {
    if (_selectedServiceId == null) return;
    setState(() {
      _loading = true;
      _slotList = null;
      _slotError = false;
    });
    try {
      final list = await _getFirstSlot.getFirstAvailableSlots(
        serviceId: _selectedServiceId!,
        clientId: _session.uid,
        limit: 4,
      );
      setState(() {
        _slotList = list
            .map((s) => (
                  slot: s.slot,
                  professionalName: s.professionalName,
                  professionalId: s.professionalId,
                  serviceId: s.serviceId,
                ))
            .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _slotError = true;
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
            onPressed: _loading ? null : _fetchFirstSlots,
            isLoading: _loading,
          ),
          if (_slotError)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Erro ao buscar horários.',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          if (_slotList != null) ...[
            const SizedBox(height: 12),
            if (_slotList!.isEmpty)
              Text(
                'Nenhum horário disponível nos próximos dias.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedForeground(context),
                ),
              )
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2 / 1.4,
                children: _slotList!.map((s) {
                  const dayAbbr = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
                  final dayName = dayAbbr[s.slot.weekday == 7 ? 0 : s.slot.weekday];
                  return Material(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () {
                        if (widget.onAgendarWithSlot != null) {
                          widget.onAgendarWithSlot!(
                            slot: s.slot,
                            professionalId: s.professionalId,
                            professionalName: s.professionalName,
                            serviceId: s.serviceId,
                          );
                        } else {
                          widget.onNavigateToPage?.call(1);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today, size: 12, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  '$dayName ${DateFormat('d/MM', 'pt_BR').format(s.slot)}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule, size: 12, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('HH:mm', 'pt_BR').format(s.slot),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_outline, size: 12, color: AppColors.mutedForeground(context)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    s.professionalName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.mutedForeground(context),
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                'Agendar',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }
}
