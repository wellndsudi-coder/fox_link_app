import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/modules/tenant/domain/entities/white_label_config.dart';
import 'package:fox_link_app/modules/tenant/domain/usecases/get_white_label_config_usecase.dart';

/// Serviço que aplica configurações de white label (tema, logo, cores) ao app.
class WhiteLabelService extends ChangeNotifier {
  final GetWhiteLabelConfigUseCase _getConfig;

  WhiteLabelConfig _config = const WhiteLabelConfig(name: 'FOX LINK');

  WhiteLabelService(this._getConfig);

  WhiteLabelConfig get config => _config;

  ThemeData get theme {
    final base = AppTheme.lightTheme;
    final primary = _config.primaryColor ?? AppTheme.primaryColor;
    final secondary = _config.secondaryColor ?? primary;
    final accent = _config.accentColor ?? AppTheme.accentColor;

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
      ),
      primaryColor: primary,
    );
  }

  Future<void> load(String tenantId) async {
    _config = await _getConfig(tenantId);
    notifyListeners();
  }

  void clear() {
    _config = const WhiteLabelConfig(name: 'FOX LINK');
    notifyListeners();
  }
}
