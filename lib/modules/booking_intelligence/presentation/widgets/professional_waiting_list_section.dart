import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/entities/waiting_list_entry.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/repositories/waiting_list_repository.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_available_slots_usecase.dart';
import 'package:fox_link_app/modules/services/domain/repositories/service_repository.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';

/// Professional UI: list of waiting-list entries with "offer slot" / "confirm" actions.
class ProfessionalWaitingListSection extends StatefulWidget {
  final String professionalId;
  final DateTime date;
  final String? tenantId;

  const ProfessionalWaitingListSection({
    super.key,
    required this.professionalId,
    required this.date,
    this.tenantId,
  });

  @override
  State<ProfessionalWaitingListSection> createState() =>
      _ProfessionalWaitingListSectionState();
}

class _ProfessionalWaitingListSectionState
    extends State<ProfessionalWaitingListSection> {
  final _repo = GetIt.I<WaitingListRepository>();
  final _slotsUseCase = GetIt.I<GetAvailableSlotsUseCase>();
  final _serviceRepo = GetIt.I<ServiceRepository>();
  final _session = GetIt.I<TenantSession>();

  List<WaitingListEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ProfessionalWaitingListSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.professionalId != widget.professionalId ||
        oldWidget.date != widget.date) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getByProfessionalAndDate(
        professionalId: widget.professionalId,
        date: widget.date,
      );
      setState(() {
        _entries = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _offerSlot(WaitingListEntry entry) async {
    final tenantId = widget.tenantId ?? _session.tenantId;
    if (tenantId == null) return;
    final services = await _serviceRepo.getAll(tenantId);
    final service = services.where((s) => s.id == entry.serviceId).firstOrNull;
    if (service == null) return;
    final duration = service.baseDuration.minutes;

    final slots = await _slotsUseCase(
      professionalId: widget.professionalId,
      date: widget.date,
      durationMinutes: duration,
    );
    if (slots.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum horário disponível')),
        );
      }
      return;
    }

    final chosen = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Escolher horário para ofertar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: slots.length.clamp(0, 10),
                itemBuilder: (_, i) {
                  final slot = slots[i];
                  return ListTile(
                    title: Text(DateFormat('HH:mm').format(slot)),
                    onTap: () => Navigator.pop(ctx, slot),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen != null && mounted) {
      await _repo.offerSlot(
        entryId: entry.id,
        slotStart: chosen,
        slotEnd: chosen.add(Duration(minutes: duration)),
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horário ofertado ao cliente')),
        );
      }
    }
  }

  Future<void> _confirmSlot(WaitingListEntry entry) async {
    await _repo.updateStatus(entry.id, WaitingListStatus.professionalConfirmed);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirmado. Cliente será notificado.')),
      );
    }
  }

  String _statusLabel(WaitingListStatus s) {
    switch (s) {
      case WaitingListStatus.pending:
        return 'Pendente';
      case WaitingListStatus.slotOffered:
        return 'Horário ofertado';
      case WaitingListStatus.professionalConfirmed:
        return 'Confirmado';
      case WaitingListStatus.clientNotified:
        return 'Cliente notificado';
      case WaitingListStatus.cancelled:
        return 'Cancelado';
      case WaitingListStatus.notified:
        return 'Notificado';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_entries.isEmpty) return const SizedBox.shrink();

    final actionable = _entries
        .where((e) =>
            e.status == WaitingListStatus.pending ||
            e.status == WaitingListStatus.slotOffered)
        .toList();
    if (actionable.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_top, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Lista de espera (${actionable.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...actionable.map((entry) => _WaitingListTile(
                entry: entry,
                statusLabel: _statusLabel(entry.status),
                onOfferSlot: () => _offerSlot(entry),
                onConfirm: () => _confirmSlot(entry),
              )),
        ],
      ),
    );
  }
}

class _WaitingListTile extends StatelessWidget {
  final WaitingListEntry entry;
  final String statusLabel;
  final VoidCallback onOfferSlot;
  final VoidCallback onConfirm;

  const _WaitingListTile({
    required this.entry,
    required this.statusLabel,
    required this.onOfferSlot,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fillColor(context),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Serviço ${entry.serviceId}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent(context),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.accentForeground(context),
                  ),
                ),
              ),
            ],
          ),
          if (entry.offeredSlotStart != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Ofertado: ${DateFormat('dd/MM HH:mm').format(entry.offeredSlotStart!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedForeground(context),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (entry.status == WaitingListStatus.pending)
                TextButton.icon(
                  onPressed: onOfferSlot,
                  icon: const Icon(Icons.schedule, size: 18),
                  label: const Text('Ofertar horário'),
                ),
              if (entry.status == WaitingListStatus.slotOffered) ...[
                TextButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Confirmar'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
