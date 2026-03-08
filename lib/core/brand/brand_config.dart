import 'package:flutter/material.dart';

import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/modules/tenant/domain/entities/white_label_config.dart';

/// Facade for brand/white-label configuration used across the app.
/// Reads from [WhiteLabelConfig] with fallbacks to [AppTheme].
class BrandConfig {
  final String appName;
  final Color primaryColor;
  final Color secondaryColor;
  final String? logo;
  final String? fontFamily;

  const BrandConfig({
    required this.appName,
    required this.primaryColor,
    required this.secondaryColor,
    this.logo,
    this.fontFamily,
  });

  /// Builds [BrandConfig] from [WhiteLabelConfig] with fallbacks to [AppTheme].
  factory BrandConfig.fromWhiteLabel(WhiteLabelConfig config) {
    return BrandConfig(
      appName: config.name,
      primaryColor: config.primaryColor ?? AppTheme.primaryColor,
      secondaryColor: config.secondaryColor ?? config.primaryColor ?? AppTheme.primaryColor,
      logo: config.logoUrl,
      fontFamily: config.fontFamily,
    );
  }
}
