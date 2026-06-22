import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../theme/app_constants.dart';

@Preview(name: "NotificationsScreen")
Widget previewNotificationsScreen() => NotificationsScreen();

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gray50,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications,
                size: 64,
                color: AppColors.blue600,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Notifications',
                style: AppTextStyles.studentTitle.copyWith(
                  color: AppColors.blue900,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'In Development',
                style: AppTextStyles.body.copyWith(color: AppColors.gray600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── ACHIEVEMENTS SCREEN ───────────────────────────

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gray50,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: AppColors.gray400,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Achievements',
                style: AppTextStyles.studentTitle.copyWith(
                  color: AppColors.gray700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'In Development',
                style: AppTextStyles.body.copyWith(color: AppColors.gray500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
