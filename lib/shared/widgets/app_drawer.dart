import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../../../core/services/supabase_service.dart';
import '../../features/auth/screens/auth_screen.dart';
import 'language_selector.dart';

enum MainModule {
  planner,
  pomodoro,
}

class AppDrawer extends StatelessWidget {
  final MainModule currentModule;
  final Function(MainModule) onSelectModule;
  final int totalTasks;
  final bool isPomodoroRunning;
  final bool isCloudOnline;
  final VoidCallback? onAuthChanged;
  final VoidCallback? onOpenDashboard;

  const AppDrawer({
    super.key,
    required this.currentModule,
    required this.onSelectModule,
    required this.totalTasks,
    required this.isPomodoroRunning,
    required this.isCloudOnline,
    this.onAuthChanged,
    this.onOpenDashboard,
  });

  void _openAuthScreen(BuildContext context) async {
    Navigator.of(context).pop(); // Close drawer
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(onAuthSuccess: onAuthChanged),
      ),
    );
    if (result == true) {
      onAuthChanged?.call();
    }
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBgSecondary,
        title: Text(
          LocaleKeys.signOut.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(LocaleKeys.signOutConfirm.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.signOut();
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Close drawer
              onAuthChanged?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
            ),
            child: Text(LocaleKeys.signOut.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = SupabaseService.isAuthenticated;
    final displayName = SupabaseService.currentUserDisplayName;

    return Drawer(
      backgroundColor: AppColors.darkBgSecondary,
      child: SafeArea(
        child: Column(
          children: [
            // Header with Account / Sync info
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.glassBorder, width: 0.8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isLoggedIn
                                ? [AppColors.primaryGreen, AppColors.primaryCyan]
                                : [AppColors.primaryCyan, AppColors.accentIndigo],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isLoggedIn ? AppColors.primaryGreen : AppColors.primaryCyan)
                                  .withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          isLoggedIn ? Icons.person_rounded : Icons.person_outline_rounded,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLoggedIn
                                  ? (displayName ?? LocaleKeys.appName.tr())
                                  : LocaleKeys.guestUser.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isLoggedIn
                                  ? LocaleKeys.navSyncOnline.tr()
                                  : LocaleKeys.navSyncOffline.tr(),
                              style: TextStyle(
                                fontSize: 11,
                                color: isLoggedIn
                                    ? AppColors.primaryGreen
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Auth Action Button
                  if (isLoggedIn)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmSignOut(context),
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        label: Text(
                          LocaleKeys.signOut.tr(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentRed,
                          side: BorderSide(color: AppColors.accentRed.withOpacity(0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openAuthScreen(context),
                        icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                        label: Text(
                          '${LocaleKeys.signIn.tr()} / ${LocaleKeys.signUp.tr()}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Main Modules Navigation
            _buildNavItem(
              context: context,
              icon: Icons.calendar_today_rounded,
              title: LocaleKeys.navPlanner.tr(),
              isSelected: currentModule == MainModule.planner,
              badge: totalTasks > 0 ? '$totalTasks' : null,
              onTap: () {
                onSelectModule(MainModule.planner);
                Navigator.of(context).pop();
              },
            ),

            _buildNavItem(
              context: context,
              icon: Icons.timer_outlined,
              title: LocaleKeys.navPomodoro.tr(),
              isSelected: currentModule == MainModule.pomodoro,
              badge: isPomodoroRunning ? '●' : null,
              badgeColor: AppColors.primaryGreen,
              onTap: () {
                onSelectModule(MainModule.pomodoro);
                Navigator.of(context).pop();
              },
            ),

            if (onOpenDashboard != null)
              _buildNavItem(
                context: context,
                icon: Icons.insights_rounded,
                title: LocaleKeys.analytics.tr(),
                isSelected: false,
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenDashboard!();
                },
              ),

            const Divider(color: AppColors.glassBorder, height: 20),

            // Language Selector Section
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.translate_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            LocaleKeys.navLanguage.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const DrawerLanguageList(),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.glassBorder, width: 0.8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LocaleKeys.navAppVersion.tr(),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCloudOnline
                              ? AppColors.primaryGreen
                              : AppColors.accentAmber,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCloudOnline ? 'Supabase' : 'Offline Mode',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isSelected,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.glassSurfaceLight : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isSelected
            ? Border.all(color: AppColors.primaryCyan.withOpacity(0.5), width: 1)
            : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primaryCyan : AppColors.textPrimary,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? AppColors.primaryCyan).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor ?? AppColors.primaryCyan,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
