import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';

/// Layout central conforme design FoxLink Studio.
/// Fornece Scaffold + Drawer (AppSidebar) + AppBar padronizada.
/// Em tablet (largura >= 600), sidebar fica persistente.
class AppLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;
  final Widget Function(bool isTablet) sidebarBuilder;

  const AppLayout({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.appBar,
    required this.sidebarBuilder,
  });

  static const _tabletBreakpoint = 600.0;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= _tabletBreakpoint;
    final sidebar = sidebarBuilder(isTablet);

    if (isTablet) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: appBar ?? _buildAppBar(context, title, actions),
        body: Row(
          children: [
            sidebar,
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: sidebar,
      appBar: appBar ?? _buildAppBar(context, title, actions, hasDrawer: true),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String title,
    List<Widget>? actions, {
    bool hasDrawer = false,
  }) {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      foregroundColor: AppTheme.foregroundColor,
      elevation: 0,
      centerTitle: false,
      leading: hasDrawer
          ? Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.foregroundColor,
        ),
      ),
      actions: [
        ...?actions,
        IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_outlined,
                  color: AppTheme.mutedForeground),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primaryColor,
            child: const Text(
              'JD',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
