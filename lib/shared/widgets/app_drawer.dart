import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../../../core/services/supabase_service.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/planner/models/note_model.dart';
import '../../features/planner/controllers/planner_controller.dart';
import '../../features/planner/widgets/daily_reminder_settings_sheet.dart';
import '../../../core/services/local_storage_service.dart';
import 'language_selector.dart';

enum MainModule {
  planner,
  pomodoro,
}

class AppDrawer extends StatelessWidget {
  final MainModule currentModule;
  final Function(MainModule) onSelectModule;
  final PeriodType? activePeriod;
  final Function(PeriodType?) onSelectPeriod;
  final int totalTasks;
  final int Function(PeriodType) getPeriodCount;
  final bool isPomodoroRunning;
  final bool isCloudOnline;
  final SyncStatus? syncStatus;
  final VoidCallback? onAuthChanged;
  final VoidCallback? onSignOut;
  final VoidCallback? onSyncNow;
  final VoidCallback? onOpenDashboard;
  final LocalStorageService? localStorage;

  const AppDrawer({
    super.key,
    required this.currentModule,
    required this.onSelectModule,
    required this.activePeriod,
    required this.onSelectPeriod,
    required this.totalTasks,
    required this.getPeriodCount,
    required this.isPomodoroRunning,
    required this.isCloudOnline,
    this.syncStatus,
    this.onAuthChanged,
    this.onSignOut,
    this.onSyncNow,
    this.onOpenDashboard,
    this.localStorage,
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
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Close drawer
              onSignOut?.call();
              await SupabaseService.signOut();
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
                                  .withValues(alpha: 0.3),
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

                  // Auth Action & Sync Buttons
                  if (isLoggedIn)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmSignOut(context),
                            icon: const Icon(Icons.logout_rounded, size: 15),
                            label: Text(
                              LocaleKeys.signOut.tr(),
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accentRed,
                              side: BorderSide(color: AppColors.accentRed.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        if (onSyncNow != null) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onSyncNow!();
                            },
                            icon: const Icon(Icons.sync_rounded, size: 15),
                            label: Text(
                              LocaleKeys.syncNow.tr(),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryCyan,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ],
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

            // Navigation Modules & Tree List
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Expandable Tree Node: "Mening Rejalarim" (My Plans)
                  _buildPlannerTreeNode(context),

                  // Module: Pomodoro
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

                  // Analytics Dashboard
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

                  // Daily Reminder Settings Button
                  _buildDailyReminderTile(context),

                  const Divider(color: AppColors.glassBorder, height: 24),

                  // Language Selector Section
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
                        isCloudOnline ? 'Supabase' : LocaleKeys.syncStatusOffline.tr(),
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

  Widget _buildDailyReminderTile(BuildContext context) {
    final storage = localStorage;
    final isEnabled = storage?.isDailyReminderEnabled() ?? false;
    final reminderTime = storage?.getDailyReminderTime() ?? '09:00';
    final interval = storage?.getReminderIntervalHours() ?? 2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(
          Icons.notifications_active_outlined,
          color: isEnabled ? AppColors.primaryCyan : AppColors.textSecondary,
          size: 22,
        ),
        title: Text(
          LocaleKeys.dailyReminderTitle.tr(),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isEnabled
                ? AppColors.primaryCyan.withValues(alpha: 0.15)
                : AppColors.glassSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isEnabled
                  ? AppColors.primaryCyan.withValues(alpha: 0.4)
                  : AppColors.glassBorder,
              width: 0.8,
            ),
          ),
          child: Text(
            isEnabled
                ? '$reminderTime (${interval == 1 ? LocaleKeys.reminderEvery1Hour.tr() : LocaleKeys.reminderEvery2Hours.tr()})'
                : LocaleKeys.taskPending.tr(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isEnabled ? AppColors.primaryCyan : AppColors.textMuted,
            ),
          ),
        ),
        onTap: () async {
          Navigator.of(context).pop(); // close drawer
          final storageService = storage ?? await LocalStorageService.create();
          if (context.mounted) {
            DailyReminderSettingsSheet.show(context, storageService);
          }
        },
      ),
    );
  }

  /// Expandable Tree Node with Visual Branch Lines
  Widget _buildPlannerTreeNode(BuildContext context) {
    final isPlannerSelected = currentModule == MainModule.planner;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isPlannerSelected
            ? AppColors.glassSurfaceLight.withValues(alpha: 0.4)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPlannerSelected
              ? AppColors.primaryCyan.withValues(alpha: 0.25)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          maintainState: true,
          leading: Icon(
            Icons.folder_special_rounded,
            color: isPlannerSelected ? AppColors.primaryCyan : AppColors.textSecondary,
            size: 22,
          ),
          title: Text(
            LocaleKeys.navPlanner.tr(), // Plural: "Mening Rejalarim" / "My Plans"
            style: TextStyle(
              fontSize: 15,
              fontWeight: isPlannerSelected ? FontWeight.bold : FontWeight.w600,
              color: isPlannerSelected ? AppColors.primaryCyan : AppColors.textPrimary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (totalTasks > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$totalTasks',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryCyan,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded, color: AppColors.textSecondary, size: 20),
            ],
          ),
          children: [
            // "All Plans" root overview option
            _buildTreeBranchItem(
              context: context,
              title: LocaleKeys.allPlans.tr(),
              icon: Icons.dashboard_outlined,
              isSelected: isPlannerSelected && activePeriod == null,
              count: totalTasks,
              isLast: false,
              onTap: () {
                onSelectModule(MainModule.planner);
                onSelectPeriod(null); // Show all plans overview
                Navigator.of(context).pop();
              },
            ),

            // 4 Time-Horizon Sub-Items with Tree Branch Line
            ...PeriodType.values.map((period) {
              final isLast = period == PeriodType.values.last;
              final isSelected = isPlannerSelected && activePeriod == period;
              final count = getPeriodCount(period);

              return _buildTreeBranchItem(
                context: context,
                title: period.labelKey.tr(),
                icon: _getPeriodIcon(period),
                isSelected: isSelected,
                count: count,
                isLast: isLast,
                onTap: () {
                  onSelectModule(MainModule.planner);
                  onSelectPeriod(period);
                  Navigator.of(context).pop();
                },
              );
            }),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  IconData _getPeriodIcon(PeriodType period) {
    switch (period) {
      case PeriodType.daily:
        return Icons.today_rounded;
      case PeriodType.weekly:
        return Icons.date_range_rounded;
      case PeriodType.monthly:
        return Icons.calendar_month_rounded;
      case PeriodType.yearly:
        return Icons.event_note_rounded;
    }
  }

  /// Single Tree Branch Item with visual branch guides
  Widget _buildTreeBranchItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required int count,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 18, right: 8, bottom: 2),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Visual tree branch line: Vertical line + horizontal elbow
            SizedBox(
              width: 24,
              child: CustomPaint(
                painter: _TreeBranchPainter(
                  isLast: isLast,
                  lineColor: AppColors.glassBorder.withValues(alpha: 0.8),
                ),
              ),
            ),

            // Branch Item Content
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryCyan.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.5), width: 1)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primaryCyan : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (count > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryCyan.withValues(alpha: 0.25)
                                : AppColors.glassSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppColors.primaryCyan : AppColors.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
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
            ? Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.5), width: 1)
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
                  color: (badgeColor ?? AppColors.primaryCyan).withValues(alpha: 0.2),
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

/// Custom Painter for Tree Branch Lines
class _TreeBranchPainter extends CustomPainter {
  final bool isLast;
  final Color lineColor;

  _TreeBranchPainter({required this.isLast, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final startX = size.width / 2;
    final midY = size.height / 2;

    // Vertical line (half if last item, full height otherwise)
    canvas.drawLine(
      Offset(startX, 0),
      Offset(startX, isLast ? midY : size.height),
      paint,
    );

    // Horizontal elbow to item
    canvas.drawLine(
      Offset(startX, midY),
      Offset(size.width, midY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TreeBranchPainter oldDelegate) {
    return oldDelegate.isLast != isLast || oldDelegate.lineColor != lineColor;
  }
}
