import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_service.dart';
import '../data/planner_repository.dart';
import '../models/note_model.dart';

enum SyncStatus {
  synced,
  syncing,
  offline,
  error,
}

enum PlanFilterTab {
  active,
  uncompleted,
}

class PlannerController extends ChangeNotifier {
  final PlannerRepository _repository;
  final NotificationService _notificationService = NotificationService();

  PeriodType? _activePeriod = PeriodType.daily;
  PlanFilterTab _currentFilterTab = PlanFilterTab.active;
  List<NoteModel> _notes = [];
  bool _isLoading = false;

  SyncStatus _syncStatus = SyncStatus.offline;
  DateTime? _lastSyncTime;

  // Real Gregorian Calendar state, dynamically initialized to DateTime.now()
  late DateTime _selectedDate;
  Timer? _midnightTimer;

  PlannerController(this._repository) {
    _initCalendarDate();
    _loadInitialNotes();
    _startMidnightTimer();
    // Defer network sync & notification rescheduling until after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rescheduleActiveReminders();
      syncWithCloud();
    });
  }

  void _initCalendarDate() {
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _startMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final diff = nextMidnight.difference(now) + const Duration(seconds: 1);

    _midnightTimer = Timer(diff, () {
      _onMidnightRollover();
      _startMidnightTimer(); // Chain to next midnight
    });
  }

  void _onMidnightRollover() {
    debugPrint('Midnight (00:00) auto-rollover check triggered!');
    if (isSelectedDateToday) {
      _selectedDate = today;
    }
    _rescheduleActiveReminders();
    notifyListeners();
  }

  void _loadInitialNotes() {
    _notes = _repository.loadInitialNotes();
  }

  PlannerRepository get repository => _repository;

  // Filter Tabs: Active Plans vs Uncompleted (Overdue) Plans
  PlanFilterTab get currentFilterTab => _currentFilterTab;

  void setFilterTab(PlanFilterTab tab) {
    if (_currentFilterTab == tab) return;
    _currentFilterTab = tab;
    notifyListeners();
  }

  // Sync Getters
  SyncStatus get syncStatus => _syncStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isCloudSyncAvailable => _repository.isCloudSyncAvailable;

  // Calendar Getters
  DateTime get selectedDate => _selectedDate;
  int get selectedYear => _selectedDate.year;
  int get selectedMonth => _selectedDate.month;
  int get selectedDay => _selectedDate.day;

  DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get isSelectedDateToday {
    final t = today;
    return _selectedDate.year == t.year &&
        _selectedDate.month == t.month &&
        _selectedDate.day == t.day;
  }

  // Week start: Monday 00:00:00 of the week of _selectedDate
  DateTime get selectedWeekStart {
    final d = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  // Week end: Sunday 23:59:59 of the week of _selectedDate
  DateTime get selectedWeekEnd {
    final start = selectedWeekStart;
    return DateTime(start.year, start.month, start.day + 6, 23, 59, 59);
  }

  // Month start and end
  DateTime get selectedMonthStart => DateTime(_selectedDate.year, _selectedDate.month, 1);
  DateTime get selectedMonthEnd {
    final nextMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    return nextMonth.subtract(const Duration(seconds: 1));
  }

  // Year start and end
  DateTime get selectedYearStart => DateTime(_selectedDate.year, 1, 1);
  DateTime get selectedYearEnd => DateTime(_selectedDate.year, 12, 31, 23, 59, 59);

  // Leap year calculation
  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  static int daysInYear(int year) => isLeapYear(year) ? 366 : 365;

  int get daysInCurrentYear => daysInYear(_selectedDate.year);

  // Calendar Navigation Methods
  void setSelectedDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void jumpToToday() {
    _initCalendarDate();
    notifyListeners();
  }

  void changeDay(int deltaDays) {
    _selectedDate = _selectedDate.add(Duration(days: deltaDays));
    notifyListeners();
  }

  void changeWeek(int deltaWeeks) {
    _selectedDate = _selectedDate.add(Duration(days: 7 * deltaWeeks));
    notifyListeners();
  }

  void changeMonth(int deltaMonths) {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + deltaMonths, 1);
    notifyListeners();
  }

  void setMonth(int month) {
    _selectedDate = DateTime(_selectedDate.year, month, 1);
    notifyListeners();
  }

  void changeYear(int deltaYears) {
    _selectedDate = DateTime(_selectedDate.year + deltaYears, _selectedDate.month, 1);
    notifyListeners();
  }

  void setYear(int year) {
    _selectedDate = DateTime(year, _selectedDate.month, 1);
    notifyListeners();
  }

  PeriodType? get activePeriod => _activePeriod;
  bool get isAllPlansSelected => _activePeriod == null;
  List<NoteModel> get allNotes => _notes;
  bool get isLoading => _isLoading;

  // Filter notes strictly aligned to the active Gregorian period (or all plans if null)
  List<NoteModel> get filteredNotes {
    final list = _notes.where((note) {
      if (_activePeriod == null) return true;
      if (note.periodType != _activePeriod) return false;

      final target = note.targetDate;
      switch (_activePeriod!) {
        case PeriodType.daily:
          return target.year == _selectedDate.year &&
              target.month == _selectedDate.month &&
              target.day == _selectedDate.day;

        case PeriodType.weekly:
          final start = selectedWeekStart;
          final end = selectedWeekEnd;
          return !target.isBefore(start) && !target.isAfter(end);

        case PeriodType.monthly:
          return target.year == _selectedDate.year &&
              target.month == _selectedDate.month;

        case PeriodType.yearly:
          return target.year == _selectedDate.year;
      }
    }).toList();

    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      final pCompare = b.priority.index.compareTo(a.priority.index);
      if (pCompare != 0) return pCompare;
      return a.targetDate.compareTo(b.targetDate);
    });

    return list;
  }

  // Overdue Uncompleted plans for the active period (rolled over at midnight)
  List<NoteModel> get uncompletedNotesForActivePeriod {
    final list = _notes.where((note) {
      if (note.isCompleted) return false;
      if (!note.isOverdue()) return false;
      if (_activePeriod == null) return true;
      return note.periodType == _activePeriod;
    }).toList();

    list.sort((a, b) {
      final pCompare = b.priority.index.compareTo(a.priority.index);
      if (pCompare != 0) return pCompare;
      return b.targetDate.compareTo(a.targetDate); // Most recently missed first
    });

    return list;
  }

  // Display notes reflecting current filter tab (Active vs Uncompleted)
  List<NoteModel> get displayNotes =>
      _currentFilterTab == PlanFilterTab.uncompleted
          ? uncompletedNotesForActivePeriod
          : filteredNotes;

  int get totalForActivePeriod => filteredNotes.length;

  int get completedForActivePeriod =>
      filteredNotes.where((n) => n.isCompleted).length;

  int get uncompletedCountForActivePeriod =>
      uncompletedNotesForActivePeriod.length;

  int get totalUncompletedCount =>
      _notes.where((n) => !n.isCompleted && n.isOverdue()).length;

  int getCountForPeriod(PeriodType type) {
    return _notes.where((n) {
      if (n.periodType != type) return false;
      final target = n.targetDate;
      switch (type) {
        case PeriodType.daily:
          return target.year == _selectedDate.year &&
              target.month == _selectedDate.month &&
              target.day == _selectedDate.day;
        case PeriodType.weekly:
          return !target.isBefore(selectedWeekStart) && !target.isAfter(selectedWeekEnd);
        case PeriodType.monthly:
          return target.year == _selectedDate.year && target.month == _selectedDate.month;
        case PeriodType.yearly:
          return target.year == _selectedDate.year;
      }
    }).length;
  }

  int getUncompletedCountForPeriod(PeriodType type) {
    return _notes
        .where((n) => !n.isCompleted && n.periodType == type && n.isOverdue())
        .length;
  }

  void setPeriodType(PeriodType? period) {
    if (_activePeriod == period) return;
    _activePeriod = period;
    notifyListeners();
  }

  /// Core Sync Pull: Triggered on startup, login, app resume, or manual tap
  Future<void> syncWithCloud({bool showLoading = false}) async {
    if (showLoading) {
      _isLoading = true;
    }
    _syncStatus = SyncStatus.syncing;
    notifyListeners();

    try {
      final result = await _repository.syncCloudAndLocal();
      _notes = result.notes;

      switch (result.outcome) {
        case SyncOutcome.synced:
          _syncStatus = SyncStatus.synced;
          _lastSyncTime = DateTime.now();
          break;
        case SyncOutcome.offline:
          _syncStatus = SupabaseService.isAuthenticated
              ? SyncStatus.synced
              : SyncStatus.offline;
          break;
        case SyncOutcome.error:
          _syncStatus = SyncStatus.error;
          break;
      }

      _rescheduleActiveReminders();
    } catch (e) {
      debugPrint('Sync failed with error: $e');
      _syncStatus = SyncStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Called after user logs in (or token refreshed) to execute Guest-to-Account merge
  Future<void> handleAuthChanged() async {
    await syncWithCloud(showLoading: true);
  }

  /// Called after user logs out to clear local user cache without touching Supabase
  Future<void> handleSignOut() async {
    final userId = SupabaseService.currentUserId;
    if (userId != null) {
      await _repository.clearUserLocalCacheOnSignOut(userId);
    }
    _notes = _repository.loadInitialNotes();
    _syncStatus = SyncStatus.offline;
    notifyListeners();
  }

  void _rescheduleActiveReminders() {
    // 1. Specific single-task reminders
    for (final n in _notes) {
      if (!n.isCompleted && n.reminderTime != null && n.reminderTime!.isAfter(DateTime.now())) {
        _notificationService.scheduleTaskReminder(
          taskId: n.id,
          title: n.title,
          description: n.description,
          reminderTime: n.reminderTime!,
        );
      }
    }

    // 2. Dynamic hourly / 2-hourly plan-specific reminders between 08:00 and 22:00
    updateHourlyPlanReminders();
  }

  void updateHourlyPlanReminders() {
    final isDailyReminderEnabled = _repository.localStorage.isDailyReminderEnabled();
    if (!isDailyReminderEnabled) {
      _notificationService.cancelHourlyPlanReminders();
      return;
    }

    final intervalHours = _repository.localStorage.getReminderIntervalHours();
    final todayMidnight = today;
    final tomorrowMidnight = todayMidnight.add(const Duration(days: 1));

    // Active uncompleted plans due today or pending
    final pendingPlans = _notes
        .where((n) =>
            !n.isCompleted &&
            (n.periodType == PeriodType.daily &&
                !n.targetDate.isBefore(todayMidnight) &&
                n.targetDate.isBefore(tomorrowMidnight)))
        .map((n) => n.title.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    // Fallback to any active uncompleted plans if no daily plans due today
    final titlesToRemind = pendingPlans.isNotEmpty
        ? pendingPlans
        : _notes.where((n) => !n.isCompleted).map((n) => n.title.trim()).toList();

    _notificationService.scheduleHourlyPlanReminders(
      intervalHours: intervalHours,
      uncompletedPlanTitles: titlesToRemind,
    );
  }

  Future<void> addNote({
    required String title,
    String description = '',
    DateTime? targetDate,
    required PriorityLevel priority,
    PeriodType? periodType,
    DateTime? reminderTime,
  }) async {
    // Unauthenticated users cannot add/save plans
    if (!SupabaseService.isAuthenticated) return;

    final effectiveTargetDate = targetDate ?? _selectedDate;

    final newNote = NoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: SupabaseService.currentUserId,
      title: title,
      description: description,
      periodType: periodType ?? _activePeriod ?? PeriodType.daily,
      targetDate: effectiveTargetDate,
      priority: priority,
      isCompleted: false,
      reminderTime: reminderTime,
    );

    // Optimistic UI update
    _notes.insert(0, newNote);
    _syncStatus = SupabaseService.isAuthenticated ? SyncStatus.syncing : SyncStatus.offline;
    notifyListeners();

    if (reminderTime != null && reminderTime.isAfter(DateTime.now())) {
      _notificationService.scheduleTaskReminder(
        taskId: newNote.id,
        title: newNote.title,
        description: newNote.description,
        reminderTime: reminderTime,
      );
    }
    updateHourlyPlanReminders();

    await _repository.addNote(newNote, _notes);
    if (SupabaseService.isAuthenticated) {
      _syncStatus = SyncStatus.synced;
      _lastSyncTime = DateTime.now();
      notifyListeners();
    }
  }

  Future<void> updateNote(NoteModel updated) async {
    if (!SupabaseService.isAuthenticated) return;
    final index = _notes.indexWhere((n) => n.id == updated.id);
    if (index == -1) return;

    // Optimistic UI update
    _notes[index] = updated;
    _syncStatus = SupabaseService.isAuthenticated ? SyncStatus.syncing : SyncStatus.offline;
    notifyListeners();

    if (updated.isCompleted || updated.reminderTime == null) {
      _notificationService.cancelTaskReminder(updated.id);
    } else if (updated.reminderTime != null && updated.reminderTime!.isAfter(DateTime.now())) {
      _notificationService.scheduleTaskReminder(
        taskId: updated.id,
        title: updated.title,
        description: updated.description,
        reminderTime: updated.reminderTime!,
      );
    }
    updateHourlyPlanReminders();

    await _repository.updateNote(updated, _notes);
    if (SupabaseService.isAuthenticated) {
      _syncStatus = SyncStatus.synced;
      _lastSyncTime = DateTime.now();
      notifyListeners();
    }
  }

  /// Reschedules an overdue / uncompleted plan to a new target date (default: today)
  Future<void> rescheduleNote(NoteModel note, [DateTime? newTargetDate]) async {
    if (!SupabaseService.isAuthenticated) return;
    final target = newTargetDate ?? today;
    final updated = note.copyWith(
      targetDate: target,
      isCompleted: false,
      updatedAt: DateTime.now(),
    );
    await updateNote(updated);
  }

  Future<void> toggleComplete(NoteModel note) async {
    if (!SupabaseService.isAuthenticated) return;
    final updated = note.copyWith(isCompleted: !note.isCompleted);
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updated;
      _syncStatus = SupabaseService.isAuthenticated ? SyncStatus.syncing : SyncStatus.offline;
      notifyListeners();
    }

    if (updated.isCompleted) {
      _notificationService.cancelTaskReminder(updated.id);
    } else if (updated.reminderTime != null && updated.reminderTime!.isAfter(DateTime.now())) {
      _notificationService.scheduleTaskReminder(
        taskId: updated.id,
        title: updated.title,
        description: updated.description,
        reminderTime: updated.reminderTime!,
      );
    }
    updateHourlyPlanReminders();

    await _repository.toggleComplete(note, _notes);
    if (SupabaseService.isAuthenticated) {
      _syncStatus = SyncStatus.synced;
      _lastSyncTime = DateTime.now();
      notifyListeners();
    }
  }

  Future<void> deleteNote(String noteId) async {
    if (!SupabaseService.isAuthenticated) return;
    _notes.removeWhere((n) => n.id == noteId);
    _syncStatus = SupabaseService.isAuthenticated ? SyncStatus.syncing : SyncStatus.offline;
    notifyListeners();

    _notificationService.cancelTaskReminder(noteId);
    updateHourlyPlanReminders();

    await _repository.deleteNote(noteId, _notes);
    if (SupabaseService.isAuthenticated) {
      _syncStatus = SyncStatus.synced;
      _lastSyncTime = DateTime.now();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }
}
