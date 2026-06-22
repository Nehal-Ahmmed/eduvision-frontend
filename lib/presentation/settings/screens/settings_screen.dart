import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../theme/app_constants.dart';
import '../provider/settings_provider.dart';
import '../../auth/provider/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.gray900 : AppColors.gray50,
      body: Container(
        color: isDark ? AppColors.gray900 : AppColors.gray50,
        child: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading settings: $e', style: TextStyle(color: isDark ? Colors.white : AppColors.gray900))),
          data: (settings) => _SettingsContent(settings: settings),
        ),
      ),
    );
  }
}

class _SettingsContent extends ConsumerStatefulWidget {
  final dynamic settings;

  const _SettingsContent({required this.settings});

  @override
  ConsumerState<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<_SettingsContent> {
  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(settingsProvider.notifier);
    final isDark = widget.settings.theme == 'dark';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.indigo600,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.settings, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: AppTextStyles.sectionHeading.copyWith(
                          color: isDark ? Colors.white : AppColors.gray900,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        'Manage your preferences',
                        style: AppTextStyles.small.copyWith(
                          color: isDark ? AppColors.gray400 : AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Appearance Section
              _buildSectionLabel('Appearance'),
              _buildCard([
                _buildSwitchTile(
                  icon: isDark ? Icons.dark_mode : Icons.light_mode,
                  iconColor: isDark ? const Color(0xFF7C3AED) : const Color(0xFFD97706),
                  title: 'Dark Mode',
                  subtitle: isDark ? 'Currently using dark theme' : 'Currently using light theme',
                  value: isDark,
                  onChanged: (val) => notifier.updateTheme(val ? 'dark' : 'light'),
                ),
              ]),

              const SizedBox(height: AppSpacing.xl),

              // Account Section
              _buildSectionLabel('Account'),
              _buildCard([
                _buildNavTile(
                  icon: Icons.lock_outline,
                  iconColor: isDark ? AppColors.gray400 : AppColors.gray600,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  hasDivider: true,
                  onTap: () => _showChangePasswordDialog(context),
                ),
                _buildNavTile(
                  icon: Icons.person_outline,
                  iconColor: isDark ? AppColors.gray400 : AppColors.gray600,
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  hasDivider: true,
                  onTap: () => context.go('/profile'),
                ),
                _buildNavTile(
                  icon: Icons.logout,
                  iconColor: AppColors.red600,
                  title: 'Log Out',
                  subtitle: 'Sign out of your EduVision account',
                  titleColor: AppColors.red600,
                  onTap: () => _confirmLogout(context),
                ),
              ]),

              const SizedBox(height: AppSpacing.xl),

              // About Section
              _buildSectionLabel('About'),
              _buildCard([
                _buildNavTile(
                  icon: Icons.info_outline,
                  iconColor: AppColors.indigo600,
                  title: 'About EduVision',
                  subtitle: 'Learn more about this application',
                  hasDivider: true,
                  onTap: () => _showAboutDialog(context),
                ),
                _buildNavTile(
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.indigo600,
                  title: 'Privacy Policy',
                  subtitle: 'Read our data handling practices',
                  hasDivider: true,
                  onTap: () => _showPrivacyDialog(context),
                ),
                _buildNavTile(
                  icon: Icons.article_outlined,
                  iconColor: AppColors.indigo600,
                  title: 'Terms of Service',
                  subtitle: 'Review your usage agreement',
                  onTap: () => _showTermsDialog(context),
                ),
              ]),

              const SizedBox(height: AppSpacing.xl),

              // Version info
              Center(
                child: Column(
                  children: [
                    Text(
                      'EduVision',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppColors.gray500 : AppColors.gray400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0  •  Academic Project 2026',
                      style: AppTextStyles.small.copyWith(
                        color: isDark ? AppColors.gray500 : AppColors.gray400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    final isDark = widget.settings.theme == 'dark';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.gray400 : AppColors.gray500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    final isDark = widget.settings.theme == 'dark';
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.gray800 : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool hasDivider = false,
  }) {
    final isDark = widget.settings.theme == 'dark';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.gray900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.small.copyWith(
                        color: isDark ? AppColors.gray400 : AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.indigo600,
              ),
            ],
          ),
        ),
        if (hasDivider)
          Padding(
            padding: const EdgeInsets.only(left: 68),
            child: Divider(height: 1, color: isDark ? AppColors.gray700 : AppColors.gray100),
          ),
      ],
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool hasDivider = false,
    Color? titleColor,
  }) {
    final isDark = widget.settings.theme == 'dark';
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: hasDivider ? BorderRadius.zero : BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: titleColor ?? (isDark ? Colors.white : AppColors.gray900),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTextStyles.small.copyWith(
                          color: isDark ? AppColors.gray400 : AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: isDark ? AppColors.gray500 : AppColors.gray400, size: 20),
              ],
            ),
          ),
        ),
        if (hasDivider)
          Padding(
            padding: const EdgeInsets.only(left: 68),
            child: Divider(height: 1, color: isDark ? AppColors.gray700 : AppColors.gray100),
          ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    final isDark = widget.settings.theme == 'dark';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.gray800 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.red900.withOpacity(0.2) : AppColors.red50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: AppColors.red600, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Log Out',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.gray900,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of your EduVision account?',
          style: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray500),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red600,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/');
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final isDark = widget.settings.theme == 'dark';
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.gray800 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(
          'Change Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.gray900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : AppColors.gray900),
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray500),
                prefixIcon: Icon(Icons.lock_outline, color: isDark ? AppColors.gray400 : AppColors.gray500),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : AppColors.gray900),
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray500),
                prefixIcon: Icon(Icons.lock_reset, color: isDark ? AppColors.gray400 : AppColors.gray500),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : AppColors.gray900),
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                labelStyle: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray500),
                prefixIcon: Icon(Icons.check_circle_outline, color: isDark ? AppColors.gray400 : AppColors.gray500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final cur = currentCtrl.text.trim();
              final n = newCtrl.text.trim();
              final c = confirmCtrl.text.trim();
              _changePassword(ctx, cur, n, c);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(
      BuildContext context,
      String currentPassword,
      String newPassword,
      String confirmPassword) async {
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match!'), backgroundColor: AppColors.red500),
      );
      return;
    }

    if (currentPassword.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password fields cannot be empty!'), backgroundColor: AppColors.red500),
      );
      return;
    }

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'jwt');
      if (token == null) throw Exception("Not authenticated");

      final dio = Dio(BaseOptions(baseUrl: '${AppConfig.apiBaseUrl}/api/profile'));
      await dio.post(
        '/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Pop loading spinner
      Navigator.pop(context);
      
      // Close original change password dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully!'), backgroundColor: AppColors.green600),
      );
    } catch (e) {
      // Pop loading spinner
      Navigator.pop(context);

      String errorMsg = 'Failed to change password. Make sure current password is correct.';
      if (e is DioException && e.response?.data != null) {
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          errorMsg = e.response?.data['message'];
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: AppColors.red500),
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    final isDark = widget.settings.theme == 'dark';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.gray800 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.indigo900.withOpacity(0.2) : AppColors.indigo50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu_book, color: AppColors.indigo600, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'About EduVision',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.gray900,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EduVision is a comprehensive academic management platform designed to empower students with smart note-taking, progress tracking, and AI-powered learning tools.',
              style: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray600, height: 1.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Version: 1.0.0',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.gray700,
              ),
            ),
            Text('Platform: Flutter (Web)', style: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray500, fontSize: 13)),
            Text('Backend: Spring Boot 3.2', style: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray500, fontSize: 13)),
            Text('Database: PostgreSQL (Supabase)', style: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray500, fontSize: 13)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    final isDark = widget.settings.theme == 'dark';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.gray800 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.gray900,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            'EduVision collects and processes only the data necessary to provide its academic services. Your notes, profile information, and academic records are stored securely and are never shared with third parties without your explicit consent.\n\nAll data is encrypted in transit (TLS) and at rest. You may request deletion of your data at any time by contacting support.',
            style: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray600, height: 1.6),
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    final isDark = widget.settings.theme == 'dark';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.gray800 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(
          'Terms of Service',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.gray900,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            'By using EduVision, you agree to use it solely for legitimate academic purposes. Misuse of AI tools, sharing of another student\'s data, or any form of academic misconduct is strictly prohibited.\n\nThe platform is provided as an academic project and comes without warranty of any kind. Usage is at your own discretion.',
            style: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray600, height: 1.6),
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
