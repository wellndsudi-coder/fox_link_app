import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/join_waiting_list_usecase.dart';
import 'package:fox_link_app/modules/services/domain/usecases/get_services.dart';
import 'package:fox_link_app/shared/widgets/app_button.dart';
import 'package:fox_link_app/shared/widgets/app_card.dart';

class WaitingListCard extends StatefulWidget {
  final void Function(int pageIndex)? onNavigateToPage;

  const WaitingListCard({this.onNavigateToPage});

  @override
  State<WaitingListCard> createState() => _WaitingListCardState();
}

class _WaitingListCardState extends State<WaitingListCard> {
  final _joinUseCase = GetIt.I<JoinWaitingListUseCase>();
  final _getServices = GetIt.I<GetServices>();
  final _session = GetIt.I<TenantSession>();

  String? _selectedServiceId;
  DateTime _desiredDate = DateTime.now();
  List<({String id, String name})> _services = [];
  bool _loading = false;
  bool _success = false;

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
          .where((s) => s.isBase && s.isActive)
          .map((s) => (id: s.id, name: s.name.value))
          .toList();
      if (_services.isNotEmpty && _selectedServiceId == null) {
        _selectedServiceId = _services.first.id;
      }
    });
  }

  Future<void> _join() async {
    final clientId = _session.uid;
    if (clientId == null || _selectedServiceId == null) return;
    setState(() {
      _loading = true;
      _success = false;
    });
    try {
      await _joinUseCase(
        clientId: clientId,
        serviceId: _selectedServiceId!,
        desiredDate: _desiredDate,
      );
      setState(() {
        _loading = false;
        _success = true;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _success = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_services.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_empty, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Lista de espera',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Entre na lista para ser avisado quando houver vaga.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedForeground(context),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _success ? null : () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _desiredDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) setState(() => _desiredDate = date);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Data desejada',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
              ),
              child: Text(
                '${_desiredDate.day.toString().padLeft(2, '0')}/${_desiredDate.month.toString().padLeft(2, '0')}/${_desiredDate.year}',
              ),
            ),
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
            onChanged: _success ? null : (v) => setState(() => _selectedServiceId = v),
          ),
          const SizedBox(height: 12),
          if (_success)
            Text(
              'Você entrou na lista! Será avisado quando houver vaga.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.success(context),
              ),
            )
          else
            AppButton(
              text: 'Entrar na lista de espera',
              onPressed: _loading ? null : _join,
              isLoading: _loading,
            ),
        ],
      ),
    );
  }
}
