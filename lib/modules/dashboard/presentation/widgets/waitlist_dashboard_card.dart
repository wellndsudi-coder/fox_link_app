import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/entities/waiting_list_entry.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/repositories/waiting_list_repository.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_available_slots_usecase.dart';
import 'package:fox_link_app/modules/services/domain/repositories/service_repository.dart';
import 'package:fox_link_app/modules/users/domain/repositories/user_repository.dart';

class WaitlistDashboardCard extends StatefulWidget {
  final String? professionalId;
  final void Function()? onViewFullList;

  const WaitlistDashboardCard({
    super.key,
    this.professionalId,
    this.onViewFullList,
  });

  @override
  State<WaitlistDashboardCard> createState() => _WaitlistDashboardCardState();
}

class _WaitlistDashboardCardState extends State<WaitlistDashboardCard> {
  final _pageController = PageController();

  String? _effectiveProfessionalId() {
    final id = widget.professionalId;
    if (id != null && id.isNotEmpty) return id;
    return GetIt.I<TenantSession>().professionalId;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profId = _effectiveProfessionalId();
    if (profId == null) return const SizedBox.shrink();

    final repo = GetIt.I<WaitingListRepository>();

    return StreamBuilder<List<WaitingListEntry>>(
      stream: repo.streamWeeklyPending(),
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        final displayList = list.take(10).toList();
        final hasMore = list.length > 10;
        final isEmpty = list.isEmpty;
        final hasMultiple = displayList.length > 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 40,
                  child: hasMultiple
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 20),
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        )
                      : null,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Lista de espera',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasMultiple)
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 20),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    if (hasMore && widget.onViewFullList != null)
                      TextButton(
                        onPressed: widget.onViewFullList,
                        child: const Text('Ver lista completa'),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: isEmpty
                  ? _EmptyWaitlistCard()
                  : PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.horizontal,
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        return _WaitlistItemCard(
                          entry: displayList[index],
                          professionalId: profId,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _WaitlistItemCard extends StatefulWidget {
  final WaitingListEntry entry;
  final String professionalId;

  const _WaitlistItemCard({
    required this.entry,
    required this.professionalId,
  });

  @override
  State<_WaitlistItemCard> createState() => _WaitlistItemCardState();
}

class _WaitlistItemCardState extends State<_WaitlistItemCard> {
  bool _offering = false;
  String? _clientName;
  String? _serviceName;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    final userRepo = GetIt.I<UserRepository>();
    final serviceRepo = GetIt.I<ServiceRepository>();
    final session = GetIt.I<TenantSession>();
    final tenantId = session.tenantId;
    if (tenantId == null) return;

    try {
      final user = await userRepo.getUser(widget.entry.clientId);
      _clientName = (user['name'] ?? user['displayName'] ?? user['email'] ?? 'Cliente') as String?;
    } catch (_) {
      _clientName = 'Cliente';
    }

    try {
      final services = await serviceRepo.getAll(tenantId);
      final svc = services.where((s) => s.id == widget.entry.serviceId).firstOrNull;
      _serviceName = svc?.name.value ?? 'Serviço';
    } catch (_) {
      _serviceName = 'Serviço';
    }

    if (mounted) setState(() {});
  }

  Future<void> _offerSlot() async {
    setState(() => _offering = true);
    final repo = GetIt.I<WaitingListRepository>();
    final slotsUseCase = GetIt.I<GetAvailableSlotsUseCase>();
    final serviceRepo = GetIt.I<ServiceRepository>();
    final session = GetIt.I<TenantSession>();
    final tenantId = session.tenantId;

    try {
      if (tenantId == null) throw Exception('Sessão não definida.');
      final services = await serviceRepo.getAll(tenantId);
      final service = services
          .where((s) => s.id == widget.entry.serviceId)
          .firstOrNull;
      if (service == null) throw Exception('Serviço não encontrado.');

      final slots = await slotsUseCase(
        professionalId: widget.professionalId,
        date: widget.entry.desiredDate,
        durationMinutes: service.baseDuration.minutes,
      );

      if (!mounted) return;
      if (slots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum horário disponível')),
        );
        setState(() => _offering = false);
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
                  style: Theme.of(ctx).textTheme.titleMedium,
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
                      subtitle: Text(DateFormat('dd/MM').format(slot)),
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
        await repo.offerSlot(
          entryId: widget.entry.id,
          slotStart: chosen,
          slotEnd: chosen.add(Duration(minutes: service.baseDuration.minutes)),
          professionalId: widget.professionalId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Horário ofertado ao cliente')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _offering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final theme = Theme.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final clientName = _clientName ?? 'Cliente';
    final serviceName = _serviceName ?? 'Serviço';
    final dateStr = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(e.desiredDate);

    return Container(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline, color: primary, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      clientName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                serviceName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedForeground(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 0.75,
                    alignment: Alignment.center,
                    child: _WaitlistChipButton(
                      label: _offering ? '...' : 'Ofertar horário',
                      onTap: _offering ? null : _offerSlot,
                      primary: primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyWaitlistCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 32, color: AppColors.mutedForeground(context)),
            const SizedBox(height: 8),
            Text(
              'Nenhum cliente na lista de espera esta semana.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitlistChipButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color primary;

  const _WaitlistChipButton({
    required this.label,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? primary : AppColors.mutedForeground(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: color, width: enabled ? 2 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: enabled ? FontWeight.w600 : FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }
}
