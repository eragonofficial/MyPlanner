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
      final androidNotificationChannel = AndroidNotificationChannel(
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
}
