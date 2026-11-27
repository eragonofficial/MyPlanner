import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keyNotesPrefix = 'cached_notes_user_';
  static const String _keyPendingMutationsPrefix = 'pending_mutations_';
  static const String _keyUserProfilePrefix = 'cached_user_profile_';

  static const String _keyLastSync = 'last_sync_timestamp';
  static const String _keyActivePeriod = 'active_period_type';

  // Daily Reminder keys
  static const String _keyDailyReminderEnabled = 'daily_reminder_enabled';
  static const String _keyDailyReminderTime = 'daily_reminder_time';
  static const String _keyDailyReminderMsg = 'daily_reminder_message';
  static const String _keyReminderIntervalHours = 'reminder_interval_hours';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    // Wipe any legacy unauthenticated guest plan caches
    await prefs.remove('cached_notes_list');
    await prefs.remove('guest_cached_notes_list');
    await prefs.remove('is_guest_mode_enabled');
    return LocalStorageService(prefs);
  }

  // User-scoped notes offline cache (Strictly authenticated users only)
  Future<bool> saveNotes(List<Map<String, dynamic>> notesJson, {String? userId}) async {
    if (userId == null || userId.isEmpty) {
      // Unauthenticated users cannot save plans locally
      return false;
    }
    final jsonString = jsonEncode(notesJson);
    return await _prefs.setString('$_keyNotesPrefix$userId', jsonString);
  }

  List<Map<String, dynamic>> getNotes({String? userId}) {
    if (userId == null || userId.isEmpty) {
      return [];
    }
    final jsonString = _prefs.getString('$_keyNotesPrefix$userId');
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(jsonString) as List;
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {
      return [];
    }
  }

  // Clear user-scoped notes on device without affecting cloud
  Future<bool> clearUserNotes(String userId) async {
    await clearPendingMutations(userId: userId);
    return await _prefs.remove('$_keyNotesPrefix$userId');
  }

  // Offline pending mutations queue (Scoped strictly to authenticated user)
  List<Map<String, dynamic>> getPendingMutations({String? userId}) {
    if (userId == null || userId.isEmpty) return [];
    final str = _prefs.getString('$_keyPendingMutationsPrefix$userId');
    if (str == null || str.isEmpty) return [];
    try {
      final decoded = jsonDecode(str) as List;
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> addPendingMutation(Map<String, dynamic> mutation, {String? userId}) async {
    if (userId == null || userId.isEmpty) return false;
    final list = getPendingMutations(userId: userId);
    list.add(mutation);
    return await _prefs.setString('$_keyPendingMutationsPrefix$userId', jsonEncode(list));
  }

  Future<bool> clearPendingMutations({String? userId}) async {
    if (userId == null || userId.isEmpty) return false;
    return await _prefs.remove('$_keyPendingMutationsPrefix$userId');
  }

  // Sync timestamp
  Future<bool> setLastSync(DateTime time) async {
    return await _prefs.setString(_keyLastSync, time.toIso8601String());
  }

  DateTime? getLastSync() {
    final str = _prefs.getString(_keyLastSync);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  // Active Period
  Future<bool> setActivePeriod(String period) async {
    return await _prefs.setString(_keyActivePeriod, period);
  }

  String? getActivePeriod() {
    return _prefs.getString(_keyActivePeriod);
  }

  // Daily Reminder Settings
  Future<bool> setDailyReminderEnabled(bool enabled) async {
    return await _prefs.setBool(_keyDailyReminderEnabled, enabled);
  }

  bool isDailyReminderEnabled() {
    return _prefs.getBool(_keyDailyReminderEnabled) ?? false;
  }

  Future<bool> setDailyReminderTime(String time) async {
    return await _prefs.setString(_keyDailyReminderTime, time);
  }

  String getDailyReminderTime() {
    return _prefs.getString(_keyDailyReminderTime) ?? '09:00';
  }

  Future<bool> setDailyReminderMessage(String msg) async {
    return await _prefs.setString(_keyDailyReminderMsg, msg);
  }

  String? getDailyReminderMessage() {
    return _prefs.getString(_keyDailyReminderMsg);
  }

  // Smart Recurring Reminder Interval (1 hour or 2 hours)
  Future<bool> setReminderIntervalHours(int hours) async {
    return await _prefs.setInt(_keyReminderIntervalHours, hours);
  }

  int getReminderIntervalHours() {
    return _prefs.getInt(_keyReminderIntervalHours) ?? 2;
  }

  // User Profile Offline Cache
  Future<bool> saveUserProfile(
    Map<String, dynamic> profileJson, {
    required String userId,
  }) async {
    if (userId.isEmpty) return false;
    return await _prefs.setString(
      '$_keyUserProfilePrefix$userId',
      jsonEncode(profileJson),
    );
  }

  Map<String, dynamic>? getUserProfile({required String userId}) {
    if (userId.isEmpty) return null;
    final raw = _prefs.getString('$_keyUserProfilePrefix$userId');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
