import 'package:flutter/material.dart';
import 'package:fox_link_app/core/white_label/white_label_service.dart';

/// Delegates to WhiteLabelService for theme.
/// Use WhiteLabelService directly; this class can be extended for tenant-specific overrides.
class TenantThemeService extends ChangeNotifier {
  final WhiteLabelService _whiteLabel;

  TenantThemeService(this._whiteLabel) {
    _whiteLabel.addListener(_onConfigChanged);
  }

  void _onConfigChanged() {
    notifyListeners();
  }

  ThemeData get theme => _whiteLabel.theme;
}
