import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_service.dart';

class DailyReminderSettingsSheet extends StatefulWidget {
  final LocalStorageService localStorage;

  const DailyReminderSettingsSheet({super.key, required this.localStorage});

  static Future<void> show(BuildContext context, LocalStorageService localStorage) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DailyReminderSettingsSheet(localStorage: localStorage),
    );
  }

  @override
  State<DailyReminderSettingsSheet> createState() => _DailyReminderSettingsSheetState();
}

class _DailyReminderSettingsSheetState extends State<DailyReminderSettingsSheet> {
  late bool _isEnabled;
  late TimeOfDay _reminderTime;
  late int _intervalHours;
  late TextEditingController _messageController;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.localStorage.isDailyReminderEnabled();
    _intervalHours = widget.localStorage.getReminderIntervalHours();
    final timeStr = widget.localStorage.getDailyReminderTime();
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts.first) ?? 9;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    _reminderTime = TimeOfDay(hour: hour, minute: minute);
    _messageController = TextEditingController(
      text: widget.localStorage.getDailyReminderMessage() ?? '',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hourStr = time.hour.toString().padLeft(2, '0');
    final minStr = time.minute.toString().padLeft(2, '0');
    return '$hourStr:$minStr';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.darkBgSecondary,
              hourMinuteTextColor: AppColors.primaryCyan,
              dialHandColor: AppColors.primaryCyan,
              dialBackgroundColor: AppColors.glassSurface,
              entryModeIconColor: AppColors.primaryCyan,
              dayPeriodTextColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.glassBorder),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
      if (_isEnabled) {
        await _applySchedule();
      }
    }
  }

  Future<void> _toggleEnabled(bool value) async {
    setState(() {
      _isEnabled = value;
    });

    if (value) {
      if (!kIsWeb) {
        await _notificationService.requestPermissions();
      }
      await _applySchedule();
    } else {
      await widget.localStorage.setDailyReminderEnabled(false);
      if (!kIsWeb) {
        await _notificationService.cancelDailyReminder();
        await _notificationService.cancelHourlyPlanReminders();
      }
      await SupabaseService.syncUserReminderPreferences(
        enabled: false,
        time: _formatTimeOfDay(_reminderTime),
        message: _messageController.text.trim(),
      );
    }
  }

  Future<void> _changeInterval(int hours) async {
    setState(() {
      _intervalHours = hours;
    });
    await widget.localStorage.setReminderIntervalHours(hours);
    if (_isEnabled) {
      await _applySchedule();
    }
  }

  Future<void> _applySchedule() async {
    final timeStr = _formatTimeOfDay(_reminderTime);
    final customMsg = _messageController.text.trim();

    await widget.localStorage.setDailyReminderEnabled(true);
    await widget.localStorage.setDailyReminderTime(timeStr);
    await widget.localStorage.setReminderIntervalHours(_intervalHours);
    if (customMsg.isNotEmpty) {
      await widget.localStorage.setDailyReminderMessage(customMsg);
    }

    if (!kIsWeb) {
      final title = LocaleKeys.dailyReminderTitle.tr();
      final body = customMsg.isNotEmpty
          ? customMsg
          : LocaleKeys.dailyReminderDefaultMsg.tr();

      await _notificationService.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
        title: title,
        body: body,
      );
    }

    await SupabaseService.syncUserReminderPreferences(
      enabled: true,
      time: timeStr,
      message: customMsg,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.darkBgSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            LocaleKeys.reminderEnabledFor.tr(args: [timeStr]),
            style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.glassBorder, width: 0.8),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: AppColors.primaryCyan, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.dailyReminderTitle.tr(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        LocaleKeys.dailyReminderSubtitle.tr(),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Toggle Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  _isEnabled
                      ? LocaleKeys.taskCompleted.tr()
                      : LocaleKeys.taskPending.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isEnabled ? AppColors.primaryCyan : AppColors.textSecondary,
                  ),
                ),
                subtitle: Text(
                  LocaleKeys.reminderEnabledFor.tr(args: [_formatTimeOfDay(_reminderTime)]),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                value: _isEnabled,
                activeColor: AppColors.primaryCyan,
                onChanged: _toggleEnabled,
              ),
            ),

            if (_isEnabled) ...[
              const SizedBox(height: 16),

              // Hourly / 2-Hourly Plan Reminder Frequency Selector
              Text(
                LocaleKeys.reminderIntervalTitle.tr(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _changeInterval(1),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _intervalHours == 1
                              ? AppColors.primaryCyan.withValues(alpha: 0.15)
                              : AppColors.glassSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _intervalHours == 1
                                ? AppColors.primaryCyan
                                : AppColors.glassBorder,
                            width: _intervalHours == 1 ? 1.4 : 0.8,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 20,
                              color: _intervalHours == 1
                                  ? AppColors.primaryCyan
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              LocaleKeys.reminderEvery1Hour.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _intervalHours == 1
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _intervalHours == 1
                                    ? AppColors.primaryCyan
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _changeInterval(2),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _intervalHours == 2
                              ? AppColors.primaryCyan.withValues(alpha: 0.15)
                              : AppColors.glassSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _intervalHours == 2
                                ? AppColors.primaryCyan
                                : AppColors.glassBorder,
                            width: _intervalHours == 2 ? 1.4 : 0.8,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.update_rounded,
                              size: 20,
                              color: _intervalHours == 2
                                  ? AppColors.primaryCyan
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              LocaleKeys.reminderEvery2Hours.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _intervalHours == 2
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _intervalHours == 2
                                    ? AppColors.primaryCyan
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Active Window (08:00 - 22:00) & Quiet Hours Note
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.wb_sunny_rounded, color: AppColors.primaryGreen, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            LocaleKeys.reminderActiveWindow.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.nights_stay_rounded, color: AppColors.textMuted, size: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            LocaleKeys.reminderQuietHours.tr(),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Preferred Daily Overview Time Picker Row
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.glassSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: AppColors.primaryCyan, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            LocaleKeys.dailyReminderTime.tr(),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          _formatTimeOfDay(_reminderTime),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryCyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Custom message input
              Text(
                LocaleKeys.customMessage.tr(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _messageController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: LocaleKeys.customMessageHint.tr(),
                  prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.textSecondary, size: 20),
                ),
                onChanged: (_) => _applySchedule(),
              ),
            ],

            if (kIsWeb) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primaryCyan, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        LocaleKeys.dailyReminderWebNotice.tr(),
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Save / Close Button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                LocaleKeys.save.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
