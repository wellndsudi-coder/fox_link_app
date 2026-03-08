import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/entities/client_history_item.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/get_client_history_usecase.dart';
import 'package:fox_link_app/shared/widgets/app_card.dart';

class ClientHistorySection extends StatefulWidget {
  final void Function(int pageIndex)? onNavigateToPage;

  const ClientHistorySection({this.onNavigateToPage});

  @override
  State<ClientHistorySection> createState() => _ClientHistorySectionState();
}

class _ClientHistorySectionState extends State<ClientHistorySection> {
  final _useCase = GetIt.I<GetClientHistoryUseCase>();
  final _session = GetIt.I<TenantSession>();

  List<ClientHistoryItem> _items = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final clientId = _session.uid;
    if (clientId == null) {
      setState(() => _loaded = true);
      return;
    }
    final list = await _useCase(clientId);
    setState(() {
      _items = list;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return AppCard(
      onTap: () => widget.onNavigateToPage?.call(3),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 12),
              Text(
                'Histórico',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_items.length} agendamentos anteriores',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedForeground(context),
            ),
          ),
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._items.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.serviceName} • ${item.professionalName}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              DateFormat('d/M/yyyy HH:mm', 'pt_BR')
                                  .format(item.scheduledStart),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.mutedForeground(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => widget.onNavigateToPage?.call(1),
                        child: const Text('Agendar novamente'),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => widget.onNavigateToPage?.call(3),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('Ver histórico completo →'),
          ),
        ],
      ),
    );
  }
}
