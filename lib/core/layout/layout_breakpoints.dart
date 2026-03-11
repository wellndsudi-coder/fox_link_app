import 'package:flutter/material.dart';

/// Breakpoints de layout para responsividade.
class LayoutBreakpoints {
  LayoutBreakpoints._();

  static const double tablet = 600;
  static const double maxContentWidth = 1200;

  static bool useDrawer(BuildContext context) =>
      MediaQuery.of(context).size.width < tablet;

  static double sidebarWidth(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet ? 240 : 280;

  static EdgeInsets pagePadding(BuildContext context) =>
      const EdgeInsets.all(16);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < tablet;

  static double gridSpacing(BuildContext context) => 16;
}
