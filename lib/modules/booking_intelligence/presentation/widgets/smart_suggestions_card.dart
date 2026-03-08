import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/smart_booking_suggestion_usecase.dart';
import 'package:fox_link_app/shared/widgets/app_card.dart';

class SmartSuggestionsCard extends StatefulWidget {
  final void Function(int pageIndex)? onNavigateToPage;

  const SmartSuggestionsCard({this.onNavigateToPage});

  @override
  State<SmartSuggestionsCard> createState() => _SmartSuggestionsCardState();
}

class _SmartSuggestionsCardState extends State<SmartSuggestionsCard> {
  final _useCase = GetIt.I<SmartBookingSuggestionUseCase>();
  final _session = GetIt.I<TenantSession>();

  bool _loaded = false;
  List<String> _labels = [];

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
    final suggestions = await _useCase(clientId);
    setState(() {
      _loaded = true;
      _labels = suggestions.map((s) => s.label).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _labels.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Sugestões inteligentes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._labels.map((label) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 18, color: AppColors.mutedForeground(context)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
          TextButton(
            onPressed: () => widget.onNavigateToPage?.call(1),
            child: const Text('Ver horários disponíveis'),
          ),
        ],
      ),
    );
  }
}
