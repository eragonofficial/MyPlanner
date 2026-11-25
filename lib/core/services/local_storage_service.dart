import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keyNotes = 'cached_notes_list';
  static const String _keyLastSync = 'last_sync_timestamp';
  static const String _keyActivePeriod = 'active_period_type';
  static const String _keyGuestMode = 'is_guest_mode_enabled';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // Notes cache
  Future<bool> saveNotes(List<Map<String, dynamic>> notesJson) async {
    final jsonString = jsonEncode(notesJson);
    return await _prefs.setString(_keyNotes, jsonString);
  }

  List<Map<String, dynamic>> getNotes() {
    final jsonString = _prefs.getString(_keyNotes);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(jsonString) as List;
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      return [];
    }
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

  // Guest Mode
  Future<bool> setGuestMode(bool enabled) async {
    return await _prefs.setBool(_keyGuestMode, enabled);
  }

  bool isGuestMode() {
    return _prefs.getBool(_keyGuestMode) ?? false;
  }
}
