import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String _channelId = 'task_reminders_channel';
  static const String _channelName = 'Task Reminders';
  static const String _channelDescription =
      'Notifications for scheduled daily task reminders and deadlines';

  static const int dailyReminderNotificationId = 999999;

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      // Local push notifications via flutter_local_notifications are not supported on Flutter Web
      _isInitialized = true;
      debugPrint('NotificationService: Web mode detected, local notifications disabled.');
      return;
    }

    try {
      // Initialize timezone database
      tz.initializeTimeZones();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      const initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Create Android Notification Channel
      const androidNotificationChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidNotificationChannel);

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully.');
    } catch (e) {
      debugPrint('NotificationService initialization failed: $e');
    }
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  int _getNotificationId(String taskId) {
    return taskId.hashCode.abs() % 2147483647;
  }

  /// Schedules a notification for a task at the designated reminderTime
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    String description = '',
    required DateTime reminderTime,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) {
      await initialize();
    }

    if (reminderTime.isBefore(DateTime.now())) {
      // Past time, do not schedule
      return;
    }

    final id = _getNotificationId(taskId);

    try {
      final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: description.isNotEmpty
            ? BigTextStyleInformation(description)
            : null,
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          description.isNotEmpty ? description : null,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (scheduleError) {
        // Fallback to inexact schedule if exact alarm permission is denied
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          description.isNotEmpty ? description : null,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
      debugPrint('Scheduled notification $id for $title at $scheduledDate');
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  /// Schedules a recurring daily reminder at a specific hour and minute
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If already past today, schedule starting tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(body),
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      try {
        await _notificationsPlugin.zonedSchedule(
          dailyReminderNotificationId,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {
        // Fallback for inexact alarms
        await _notificationsPlugin.zonedSchedule(
          dailyReminderNotificationId,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
      debugPrint('Daily reminder scheduled recurring at $hour:$minute');
    } catch (e) {
      debugPrint('Failed to schedule daily reminder: $e');
    }
  }

  /// Cancels the recurring daily reminder
  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    try {
      await _notificationsPlugin.cancel(dailyReminderNotificationId);
      debugPrint('Cancelled daily recurring reminder');
    } catch (e) {
      debugPrint('Failed to cancel daily reminder: $e');
    }
  }

  /// Cancels a scheduled task notification
  Future<void> cancelTaskReminder(String taskId) async {
    if (kIsWeb) return;
    try {
      final id = _getNotificationId(taskId);
      await _notificationsPlugin.cancel(id);
      debugPrint('Cancelled notification $id for task $taskId');
    } catch (e) {
      debugPrint('Failed to cancel notification: $e');
    }
  }

  static const int hourlyReminderBaseId = 2000;

  /// Schedules dynamic hourly/2-hourly plan-specific reminders between 08:00 and 22:00 (10:00 PM).
  /// Stops automatically at 22:00 to avoid nighttime disturbance.
  Future<void> scheduleHourlyPlanReminders({
    required int intervalHours,
    required List<String> uncompletedPlanTitles,
    String? title,
    String? singlePlanBody,
    String? multiPlanBody,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) {
      await initialize();
    }

    // Cancel all previous hourly reminder slots first
    await cancelHourlyPlanReminders();

    // If no uncompleted plans, no need to schedule reminders
    if (uncompletedPlanTitles.isEmpty) {
      debugPrint('No uncompleted plans pending; hourly reminders stopped.');
      return;
    }

    final effectiveInterval = intervalHours == 1 ? 1 : 2;
    final notifTitle = title ?? 'Reja eslatmasi';

    final firstPlan = uncompletedPlanTitles.first;
    final otherCount = uncompletedPlanTitles.length - 1;

    String body;
    if (otherCount > 0) {
      body = multiPlanBody != null
          ? multiPlanBody.replaceAll('{}', firstPlan) // format with title & count
          : 'Eslatma: "$firstPlan" va yana $otherCount ta rejangiz kutilmoqda!';
    } else {
      body = singlePlanBody != null
          ? singlePlanBody.replaceAll('{}', firstPlan)
          : 'Eslatma: "$firstPlan" rejasini bajarish vaqti keldi!';
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    final now = tz.TZDateTime.now(tz.local);

    for (int hour = 8; hour <= 22; hour += effectiveInterval) {
      final notifId = hourlyReminderBaseId + hour;
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        0,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      try {
        await _notificationsPlugin.zonedSchedule(
          notifId,
          notifTitle,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {
        await _notificationsPlugin.zonedSchedule(
          notifId,
          notifTitle,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
    debugPrint(
        'Scheduled hourly plan reminders ($effectiveInterval hr step) between 08:00 and 22:00 for ${uncompletedPlanTitles.length} plan(s).');
  }

  /// Cancels all recurring hourly plan reminders
  Future<void> cancelHourlyPlanReminders() async {
    if (kIsWeb) return;
    for (int hour = 8; hour <= 22; hour++) {
      try {
        await _notificationsPlugin.cancel(hourlyReminderBaseId + hour);
      } catch (_) {}
    }
  }
}
