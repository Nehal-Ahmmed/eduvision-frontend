import 'package:academic_project/presentation/auth/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_constants.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../friends/screens/friends_screen.dart';
import '../messages/screens/messages_screen.dart';
import '../events/screens/events_screen.dart';
import '../flutter_screens/placeholder_screens.dart';
import '../library/screens/library_screen.dart';
import '../smart notes/screens/smart_notes_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../settings/provider/settings_provider.dart';
import '../auth/screen/login_page.dart';
import '../auth/screen/sign_up.dart';
import '../auth/screen/landing_page.dart';
import '../courses/screens/courses_screen.dart';

final isMainSidebarOpenProvider = StateProvider<bool>((ref) => true);

// GoRouter configuration
final routerProvider2 = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LandingPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/smartnotes',
            builder: (context, state) => const SmartNotes(),
          ),
          GoRoute(
            path: '/courses',
            builder: (context, state) => const CoursesScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/friends',
            builder: (context, state) => const FriendsScreen(),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/events',
            builder: (context, state) => const EventsScreen(),
          ),
          GoRoute(
            path: '/library',
            builder: (context, state) => const LibraryScreen(),
          ),
          GoRoute(
            path: '/achievements',
            builder: (context, state) => const AchievementsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],

    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/';

      if (!isLoggedIn && !isLoggingIn) return '/';
      if (isLoggedIn && (state.matchedLocation == '/login' || state.matchedLocation == '/signup' || state.matchedLocation == '/')) {
        return '/dashboard';
      }

      return null;
    },
  );
});

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
        final showSidebar = isDesktop || isTablet;

        return Scaffold(
          body: Row(
            children: [
              if (showSidebar) const DesktopNavigation(),
              Expanded(child: child),
            ],
          ),
          bottomNavigationBar: showSidebar ? null : const MobileNavigation(),
        );
      },
    );
  }
}

class DesktopNavigation extends ConsumerWidget {
  const DesktopNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isOpen = isTablet ? false : ref.watch(isMainSidebarOpenProvider);

    final settingsAsync = ref.watch(settingsProvider);
    final isDark = settingsAsync.maybeWhen(
      data: (s) => s.theme == 'dark',
      orElse: () => false,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isOpen ? 256 : 80,
      decoration: BoxDecoration(
        color: isDark ? AppColors.gray900 : null,
        gradient: isDark
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.gradientStart,
                  AppColors.gradientMiddle,
                  AppColors.gradientEnd,
                ],
              ),
        border: Border(right: BorderSide(color: isDark ? AppColors.gray800 : AppColors.blue200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
            child: Row(
              mainAxisAlignment: isOpen ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                if (isOpen) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.indigo600,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.menu_book,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'EduVision',
                      style: AppTextStyles.sectionHeading.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.gray900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(isOpen ? Icons.chevron_left : Icons.menu, color: isDark ? AppColors.gray400 : AppColors.gray700),
                  onPressed: () => ref.read(isMainSidebarOpenProvider.notifier).state = !isOpen,
                  tooltip: 'Toggle Navigation',
                  splashRadius: 24,
                ),
              ],
            ),
          ),

          // Search Bar
          if (isOpen)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 2,
                ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.gray800 : AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: isDark ? AppColors.gray500 : AppColors.gray400, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: isDark ? Colors.white : AppColors.gray900),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        border: InputBorder.none,
                        hintStyle: AppTextStyles.body.copyWith(
                          color: isDark ? AppColors.gray500 : AppColors.gray400,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  route: '/dashboard',
                  isActive: currentRoute == '/dashboard',
                  isOpen: isOpen,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.note_alt_outlined,
                  label: 'Smart Notes',
                  route: '/smartnotes',
                  isActive: currentRoute == '/smartnotes',
                  isOpen: isOpen,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.book_outlined,
                  label: 'Courses',
                  route: '/courses',
                  isActive: currentRoute == '/courses',
                  isOpen: isOpen,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.person_outline,
                  label: 'Profile',
                  route: '/profile',
                  isActive: currentRoute == '/profile',
                  isOpen: isOpen,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.calendar_today,
                  label: 'Events',
                  route: '/events',
                  isActive: currentRoute == '/events',
                  isOpen: isOpen,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.library_books,
                  label: 'My Library',
                  route: '/library',
                  isActive: currentRoute == '/library',
                  isOpen: isOpen,
                ),
              ],
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _buildNavItem(
              context,
              icon: Icons.settings_outlined,
              label: 'Settings',
              route: '/settings',
              isActive: currentRoute == '/settings',
              isOpen: isOpen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
    bool isOpen = true,
    int? badgeCount,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark ? AppColors.indigo600 : AppColors.gray900)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? AppColors.white
                      : (isDark ? AppColors.gray400 : AppColors.gray700),
                ),
                if (isOpen) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isActive
                            ? AppColors.white
                            : (isDark ? AppColors.gray400 : AppColors.gray800),
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (badgeCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.red600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MobileNavigation extends StatelessWidget {
  const MobileNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.blue200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(
            context,
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            route: '/dashboard',
            isActive: currentRoute == '/dashboard',
          ),
          _buildBottomNavItem(
            context,
            icon: Icons.note_alt_outlined,
            label: 'Notes',
            route: '/smartnotes',
            isActive: currentRoute == '/smartnotes',
          ),
          _buildBottomNavItem(
            context,
            icon: Icons.book_outlined,
            label: 'Courses',
            route: '/courses',
            isActive: currentRoute == '/courses',
          ),
          _buildBottomNavItem(
            context,
            icon: Icons.person_outline,
            label: 'Profile',
            route: '/profile',
            isActive: currentRoute == '/profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
  }) {
    return InkWell(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppColors.blue600 : AppColors.gray500,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.extraSmall.copyWith(
                color: isActive ? AppColors.blue600 : AppColors.gray500,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
