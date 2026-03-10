import 'package:flutter/material.dart';
import 'package:fox_link_app/core/layout/layout_breakpoints.dart';

/// Layout central: Scaffold + Drawer (AppSidebar) + AppBar padronizada.
/// Em tablet (>= 600px), sidebar fica persistente. Em web, conteúdo limitado a maxContentWidth.
class AppLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;
  final Widget Function(bool isTablet) sidebarBuilder;
  final String? userInitials;

  const AppLayout({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.appBar,
    required this.sidebarBuilder,
    this.userInitials,
  });

  @override
  Widget build(BuildContext context) {
    final useDrawer = LayoutBreakpoints.useDrawer(context);
    final sidebar = sidebarBuilder(!useDrawer);
    final theme = Theme.of(context);
    final contentArea = useDrawer
        ? body
        : LayoutBuilder(
            builder: (_, constraints) {
              final w = MediaQuery.of(context).size.width;
              final mainContent = w >= LayoutBreakpoints.tablet
                  ? Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxWidth: LayoutBreakpoints.maxContentWidth),
                        child: body,
                      ),
                    )
                  : body;
              return mainContent;
            },
          );

    final scaffoldBg = theme.scaffoldBackgroundColor;

    if (!useDrawer) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: appBar ?? _buildAppBar(context, title, actions, theme, hasDrawer: false),
        body: Row(
          children: [
            sidebar,
            Expanded(child: contentArea),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      drawer: sidebar,
      appBar: appBar ?? _buildAppBar(context, title, actions, theme, hasDrawer: true),
      body: contentArea,
      floatingActionButton: floatingActionButton,
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String title,
    List<Widget>? actions,
    ThemeData theme, {
    bool hasDrawer = false,
  }) {
    final initials = userInitials ?? '?';

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      foregroundColor: theme.colorScheme.onSurface,
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
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      actions: [
        ...?actions,
        IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_outlined, color: theme.colorScheme.onSurfaceVariant),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
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
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              initials.toUpperCase().length >= 2 ? initials.toUpperCase().substring(0, 2) : initials,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
