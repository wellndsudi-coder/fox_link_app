import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/repeat_last_appointment_usecase.dart';
import 'package:fox_link_app/shared/widgets/app_button.dart';
import 'package:fox_link_app/shared/widgets/app_card.dart';

class RepeatAppointmentCard extends StatefulWidget {
  final void Function(int pageIndex)? onNavigateToPage;

  const RepeatAppointmentCard({this.onNavigateToPage});

  @override
  State<RepeatAppointmentCard> createState() => _RepeatAppointmentCardState();
}

class _RepeatAppointmentCardState extends State<RepeatAppointmentCard> {
  final _useCase = GetIt.I<RepeatLastAppointmentUseCase>();
  final _session = GetIt.I<TenantSession>();

  bool _loaded = false;
  bool _hasLast = false;
  String _lastServiceName = '';
  String? _slotLabel;

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
    final result = await _useCase(clientId);
    setState(() {
      _loaded = true;
      _hasLast = result.lastAppointment != null;
      if (result.lastAppointment != null) {
        _lastServiceName = ' último agendamento';
        if (result.firstAvailableSlot != null) {
          final slot = result.firstAvailableSlot!.slot;
          _slotLabel = '${DateFormat('d/MM', 'pt_BR').format(slot)} às ${DateFormat('HH:mm').format(slot)}';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || !_hasLast) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.replay, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Agendar novamente',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Repetir$_lastServiceName',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedForeground(context),
            ),
          ),
          if (_slotLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              'Próximo disponível: $_slotLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppButton(
            text: 'Agendar novamente',
            onPressed: () => widget.onNavigateToPage?.call(1),
          ),
        ],
      ),
    );
  }
}
