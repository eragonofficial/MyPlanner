import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_service.dart';
import '../data/planner_repository.dart';
import '../models/note_model.dart';

class PlannerController extends ChangeNotifier {
  final PlannerRepository _repository;
  final NotificationService _notificationService = NotificationService();

  PeriodType _activePeriod = PeriodType.daily;
  List<NoteModel> _notes = [];
  bool _isLoading = false;

  // Real Gregorian Calendar state, dynamically initialized to DateTime.now()
  late DateTime _selectedDate;

  PlannerController(this._repository) {
    _initCalendarDate();
    loadNotes();
  }

  void _initCalendarDate() {
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

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

  PeriodType get activePeriod => _activePeriod;
  List<NoteModel> get allNotes => _notes;
  bool get isLoading => _isLoading;
  bool get isCloudSyncAvailable => _repository.isCloudSyncAvailable;

  // Filter notes strictly aligned to the active Gregorian period
  List<NoteModel> get filteredNotes {
    final list = _notes.where((note) {
      if (note.periodType != _activePeriod) return false;

      final target = note.targetDate;
      switch (_activePeriod) {
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

  int get totalForActivePeriod => filteredNotes.length;

  int get completedForActivePeriod =>
      filteredNotes.where((n) => n.isCompleted).length;

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

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notes = await _repository.getNotes();
      // Schedule any active future reminders
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
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setPeriodType(PeriodType period) {
    if (_activePeriod == period) return;
    _activePeriod = period;
    notifyListeners();
  }

  Future<void> addNote({
    required String title,
    String description = '',
    DateTime? targetDate,
    required PriorityLevel priority,
    PeriodType? periodType,
    DateTime? reminderTime,
  }) async {
    final effectiveTargetDate = targetDate ?? _selectedDate;

    final newNote = NoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: SupabaseService.currentUserId,
      title: title,
      description: description,
      periodType: periodType ?? _activePeriod,
      targetDate: effectiveTargetDate,
      priority: priority,
      isCompleted: false,
      reminderTime: reminderTime,
    );

    _notes.insert(0, newNote);
    notifyListeners();

    if (reminderTime != null && reminderTime.isAfter(DateTime.now())) {
      _notificationService.scheduleTaskReminder(
        taskId: newNote.id,
        title: newNote.title,
        description: newNote.description,
        reminderTime: reminderTime,
      );
    }

    await _repository.addNote(newNote, _notes);
  }

  Future<void> updateNote(NoteModel updated) async {
    final index = _notes.indexWhere((n) => n.id == updated.id);
    if (index == -1) return;

    _notes[index] = updated;
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

    await _repository.updateNote(updated, _notes);
  }

  Future<void> toggleComplete(NoteModel note) async {
    final updated = note.copyWith(isCompleted: !note.isCompleted);
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updated;
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

    await _repository.toggleComplete(note, _notes);
  }

  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
    notifyListeners();

    _notificationService.cancelTaskReminder(noteId);
    await _repository.deleteNote(noteId, _notes);
  }

  Future<void> syncWithCloud() async {
    await _repository.syncLocalNotesToCloud();
    await loadNotes();
  }
}
