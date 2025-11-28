import 'package:flutter/material.dart';
import '../../core/routing.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildNavigationBar(context, currentRoute),
        ),
      ),
      body: body,
    );
  }

  Widget _buildNavigationBar(BuildContext context, String currentRoute) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavButton(
            context,
            icon: Icons.home,
            label: 'Home',
            route: AppRoutes.home,
            currentRoute: currentRoute,
          ),
          _buildNavButton(
            context,
            icon: Icons.description,
            label: 'Client Info',
            route: AppRoutes.sampleInfo,
            currentRoute: currentRoute,
          ),
          _buildNavButton(
            context,
            icon: Icons.list,
            label: 'Sample List',
            route: AppRoutes.sampleList,
            currentRoute: currentRoute,
          ),
          _buildNavButton(
            context,
            icon: Icons.assignment,
            label: 'Registration',
            route: AppRoutes.registration,
            currentRoute: currentRoute,
          ),
          _buildNavButton(
            context,
            icon: Icons.file_download,
            label: 'Export',
            route: AppRoutes.export,
            currentRoute: currentRoute,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required String currentRoute,
  }) {
    final isActive = currentRoute == route;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.6),
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
