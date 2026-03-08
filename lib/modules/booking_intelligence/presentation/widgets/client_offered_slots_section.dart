import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/entities/waiting_list_entry.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/repositories/waiting_list_repository.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/confirm_waiting_list_slot_usecase.dart';
import 'package:fox_link_app/modules/services/domain/repositories/service_repository.dart';
import 'package:fox_link_app/shared/widgets/app_button.dart';

/// Client UI: shows waiting list entries with offered slots that the client can confirm.
class ClientOfferedSlotsSection extends StatefulWidget {
  final void Function(int pageIndex)? onNavigateToPage;

  const ClientOfferedSlotsSection({super.key, this.onNavigateToPage});

  @override
  State<ClientOfferedSlotsSection> createState() =>
      _ClientOfferedSlotsSectionState();
}

class _ClientOfferedSlotsSectionState extends State<ClientOfferedSlotsSection> {
  final _repo = GetIt.I<WaitingListRepository>();
  final _confirmUseCase = GetIt.I<ConfirmWaitingListSlotUseCase>();
  final _serviceRepo = GetIt.I<ServiceRepository>();
  final _session = GetIt.I<TenantSession>();

  List<WaitingListEntry> _entries = [];
  bool _loading = true;
  String? _confirmingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final clientId = _session.uid;
    if (clientId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final list = await _repo.getByClient(clientId);
      setState(() {
        _entries = list
            .where((e) =>
                e.offeredSlotStart != null &&
                e.offeredSlotEnd != null &&
                (e.status == WaitingListStatus.slotOffered ||
                    e.status == WaitingListStatus.professionalConfirmed ||
                    e.status == WaitingListStatus.clientNotified))
            .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirm(WaitingListEntry entry) async {
    final tenantId = _session.tenantId;
    if (tenantId == null) return;

    setState(() => _confirmingId = entry.id);
    try {
      await _confirmUseCase(entry: entry, tenantId: tenantId);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento confirmado!')),
      );
      widget.onNavigateToPage?.call(2);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _confirmingId = null);
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Icon(Icons.event_available, color: AppColors.success(context)),
              const SizedBox(width: 8),
              Text(
                'Vaga disponível para você!',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._entries.map((entry) => _OfferedSlotTile(
                entry: entry,
                serviceRepo: _serviceRepo,
                tenantId: _session.tenantId ?? '',
                isConfirming: _confirmingId == entry.id,
                onConfirm: () => _confirm(entry),
              )),
        ],
      ),
    );
  }
}

class _OfferedSlotTile extends StatelessWidget {
  final WaitingListEntry entry;
  final ServiceRepository serviceRepo;
  final String tenantId;
  final bool isConfirming;
  final VoidCallback onConfirm;

  const _OfferedSlotTile({
    required this.entry,
    required this.serviceRepo,
    required this.tenantId,
    required this.isConfirming,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: serviceRepo.getAll(tenantId),
      builder: (context, snapshot) {
        final serviceName = snapshot.hasData
            ? (snapshot.data!
                    .where((s) => s.id == entry.serviceId)
                    .firstOrNull
                    ?.name
                    .value ??
                'Serviço')
            : 'Serviço';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.fillColor(context),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                serviceName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormat('EEEE, dd/MM', 'pt_BR').format(entry.offeredSlotStart!)} às ${DateFormat('HH:mm').format(entry.offeredSlotStart!)}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground(context),
                ),
              ),
              const SizedBox(height: 12),
              AppButton(
                text: isConfirming ? 'Confirmando...' : 'Confirmar agendamento',
                onPressed: isConfirming ? null : onConfirm,
              ),
            ],
          ),
        );
      },
    );
  }
}
