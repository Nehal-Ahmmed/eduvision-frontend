import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primaryColor, theme.colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_stories_rounded, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    'EduVision',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _DrawerTile(
            icon: Icons.dashboard_rounded,
            title: 'Notes',
            isSelected: currentRoute == '/',
            onTap: () => context.go('/'),
          ),
          _DrawerTile(
            icon: Icons.library_books_rounded,
            title: 'Resources',
            isSelected: currentRoute == '/resources',
            onTap: () => context.go('/resources'),
          ),
          _DrawerTile(
            icon: Icons.auto_awesome_rounded,
            title: 'AI Assistant',
            isSelected: currentRoute == '/ai',
            onTap: () => context.go('/ai'),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Opacity(
              opacity: 0.3,
              child: Text('EduVision AI v1.0', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isSelected;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon, 
          color: isSelected ? activeColor : Colors.white54,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
      ),
    );
  }
}
