import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';

enum PeriodType {
  daily,
  weekly,
  monthly,
  yearly;

  String get labelKey {
    switch (this) {
      case PeriodType.daily:
        return LocaleKeys.periodDaily;
      case PeriodType.weekly:
        return LocaleKeys.periodWeekly;
      case PeriodType.monthly:
        return LocaleKeys.periodMonthly;
      case PeriodType.yearly:
        return LocaleKeys.periodYearly;
    }
  }

  static PeriodType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'weekly':
        return PeriodType.weekly;
      case 'monthly':
        return PeriodType.monthly;
      case 'yearly':
        return PeriodType.yearly;
      case 'daily':
      default:
        return PeriodType.daily;
    }
  }
}

enum PriorityLevel {
  low,
  medium,
  high;

  String get labelKey {
    switch (this) {
      case PriorityLevel.low:
        return LocaleKeys.priorityLow;
      case PriorityLevel.medium:
        return LocaleKeys.priorityMedium;
      case PriorityLevel.high:
        return LocaleKeys.priorityHigh;
    }
  }

  Color get color {
    switch (this) {
      case PriorityLevel.low:
        return AppColors.priorityLow;
      case PriorityLevel.medium:
        return AppColors.priorityMedium;
      case PriorityLevel.high:
        return AppColors.priorityHigh;
    }
  }

  static PriorityLevel fromString(String val) {
    switch (val.toLowerCase()) {
      case 'high':
        return PriorityLevel.high;
      case 'medium':
        return PriorityLevel.medium;
      case 'low':
      default:
        return PriorityLevel.low;
    }
  }
}

class NoteModel {
  final String id;
  final String? userId;
  final String title;
  final String description;
  final PeriodType periodType;
  final DateTime targetDate;
  final PriorityLevel priority;
  final bool isCompleted;
  final DateTime? reminderTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    this.userId,
    required this.title,
    this.description = '',
    required this.periodType,
    required this.targetDate,
    this.priority = PriorityLevel.medium,
    this.isCompleted = false,
    this.reminderTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  NoteModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    PeriodType? periodType,
    DateTime? targetDate,
    PriorityLevel? priority,
    bool? isCompleted,
    DateTime? reminderTime,
    bool clearReminderTime = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      periodType: periodType ?? this.periodType,
      targetDate: targetDate ?? this.targetDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderTime: clearReminderTime ? null : (reminderTime ?? this.reminderTime),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'period_type': periodType.name,
      'target_date': targetDate.toIso8601String(),
      'priority': priority.name,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (userId != null && userId!.isNotEmpty) {
      map['user_id'] = userId;
    }
    if (reminderTime != null) {
      map['reminder_time'] = reminderTime!.toIso8601String();
    }
    return map;
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id']?.toString() ?? UniqueKey().toString(),
      userId: map['user_id']?.toString(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      periodType: PeriodType.fromString(map['period_type'] ?? 'daily'),
      targetDate: map['target_date'] != null
          ? DateTime.tryParse(map['target_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      priority: PriorityLevel.fromString(map['priority'] ?? 'medium'),
      isCompleted: map['is_completed'] == true || map['is_completed'] == 1,
      reminderTime: map['reminder_time'] != null
          ? DateTime.tryParse(map['reminder_time'].toString())
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
