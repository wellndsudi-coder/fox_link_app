import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/get_queue_status_usecase.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/join_queue_usecase.dart';
import 'package:fox_link_app/shared/widgets/app_button.dart';
import 'package:fox_link_app/shared/widgets/app_card.dart';

class QueueStatusCard extends StatefulWidget {
  final void Function(int pageIndex)? onNavigateToPage;

  const QueueStatusCard({this.onNavigateToPage});

  @override
  State<QueueStatusCard> createState() => _QueueStatusCardState();
}

class _QueueStatusCardState extends State<QueueStatusCard> {
  final _getStatus = GetIt.I<GetQueueStatusUseCase>();
  final _joinQueue = GetIt.I<JoinQueueUseCase>();
  final _session = GetIt.I<TenantSession>();

  bool _loaded = false;
  int? _position;
  DateTime? _estimatedTime;
  bool _joining = false;

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
    final entry = await _getStatus(clientId);
    setState(() {
      _loaded = true;
      _position = entry?.position;
      _estimatedTime = entry?.estimatedTime;
    });
  }

  Future<void> _join() async {
    final clientId = _session.uid;
    if (clientId == null) return;
    setState(() => _joining = true);
    try {
      final entry = await _joinQueue(clientId);
      setState(() {
        _position = entry.position;
        _estimatedTime = entry.estimatedTime;
        _joining = false;
      });
    } catch (_) {
      setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Fila virtual',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _position != null
                ? 'Você está na posição $_position na fila.'
                : 'Entre na fila para ser atendido mais rápido.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedForeground(context),
            ),
          ),
          if (_estimatedTime != null) ...[
            const SizedBox(height: 4),
            Text(
              'Tempo estimado: ${_estimatedTime!.hour.toString().padLeft(2, '0')}:${_estimatedTime!.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_position == null)
            AppButton(
              text: 'Entrar na fila',
              onPressed: _joining ? null : _join,
              isLoading: _joining,
            )
          else
            AppButton(
              text: 'Ver agenda',
              onPressed: () => widget.onNavigateToPage?.call(2),
              variant: AppButtonVariant.secondary,
            ),
        ],
      ),
    );
  }
}
