import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/entities/favorite_professional.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/repositories/favorites_repository.dart';
import 'package:fox_link_app/shared/widgets/app_card.dart';

class FavoritesProfessionalsSection extends StatefulWidget {
  final void Function(int pageIndex)? onNavigateToPage;

  const FavoritesProfessionalsSection({this.onNavigateToPage});

  @override
  State<FavoritesProfessionalsSection> createState() =>
      _FavoritesProfessionalsSectionState();
}

class _FavoritesProfessionalsSectionState
    extends State<FavoritesProfessionalsSection> {
  final _favoritesRepo = GetIt.I<FavoritesRepository>();
  final _session = GetIt.I<TenantSession>();

  List<FavoriteProfessional> _favorites = [];
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
    final list = await _favoritesRepo.getByClient(clientId);
    setState(() {
      _favorites = list;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: () => widget.onNavigateToPage?.call(4),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(
              Icons.people,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profissionais favoritos',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loaded && _favorites.isNotEmpty
                      ? '${_favorites.length} favorito(s)'
                      : 'Adicione seus profissionais preferidos',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedForeground(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppColors.mutedForeground(context),
          ),
        ],
      ),
    );
  }
}
