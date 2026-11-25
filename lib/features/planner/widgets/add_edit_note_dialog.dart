import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../models/note_model.dart';

class AddEditNoteDialog extends StatefulWidget {
  final NoteModel? existingNote;
  final PeriodType initialPeriod;
  final DateTime? initialDate;
  final Function({
    required String title,
    required String description,
    required DateTime targetDate,
    required PriorityLevel priority,
    required PeriodType periodType,
    DateTime? reminderTime,
  }) onSave;

  const AddEditNoteDialog({
    super.key,
    this.existingNote,
    required this.initialPeriod,
    this.initialDate,
    required this.onSave,
  });

  @override
  State<AddEditNoteDialog> createState() => _AddEditNoteDialogState();
}

class _AddEditNoteDialogState extends State<AddEditNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _selectedDate;
  late PriorityLevel _selectedPriority;
  late PeriodType _selectedPeriod;
  DateTime? _selectedReminderTime;

  @override
  void initState() {
    super.initState();
    final note = widget.existingNote;
    _titleController = TextEditingController(text: note?.title ?? '');
    _descController = TextEditingController(text: note?.description ?? '');
    _selectedDate = note?.targetDate ?? widget.initialDate ?? DateTime.now();
    _selectedPriority = note?.priority ?? PriorityLevel.medium;
    _selectedPeriod = note?.periodType ?? widget.initialPeriod;
    _selectedReminderTime = note?.reminderTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryCyan,
              onPrimary: Colors.black,
              surface: AppColors.darkBgSecondary,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // Adjust reminder date if reminder was already set
        if (_selectedReminderTime != null) {
          _selectedReminderTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _selectedReminderTime!.hour,
            _selectedReminderTime!.minute,
          );
        }
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final initialTime = _selectedReminderTime != null
        ? TimeOfDay(hour: _selectedReminderTime!.hour, minute: _selectedReminderTime!.minute)
        : TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryCyan,
              onPrimary: Colors.black,
              surface: AppColors.darkBgSecondary,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedReminderTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _clearReminder() {
    setState(() {
      _selectedReminderTime = null;
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        targetDate: _selectedDate,
        priority: _selectedPriority,
        periodType: _selectedPeriod,
        reminderTime: _selectedReminderTime,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingNote != null;
    final dateFormat = DateFormat.yMMMd(context.locale.toString());

    return Dialog(
      backgroundColor: AppColors.darkBgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dialog Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? LocaleKeys.editTask.tr() : LocaleKeys.newTask.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title Input
                TextFormField(
                  controller: _titleController,
                  autofocus: !isEditing,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: LocaleKeys.taskTitle.tr(),
                    hintText: LocaleKeys.taskTitleHint.tr(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return LocaleKeys.requiredField.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Description Input
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: LocaleKeys.taskDesc.tr(),
                    hintText: LocaleKeys.taskDescHint.tr(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Period Selection Chips
                Text(
                  LocaleKeys.plannerTitle.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: PeriodType.values.map((period) {
                    final selected = _selectedPeriod == period;
                    return ChoiceChip(
                      label: Text(period.labelKey.tr()),
                      selected: selected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedPeriod = period);
                      },
                      selectedColor: AppColors.primaryCyan.withOpacity(0.2),
                      backgroundColor: AppColors.glassSurface,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: selected ? AppColors.primaryCyan : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: selected ? AppColors.primaryCyan : AppColors.glassBorder,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Priority Selection
                Text(
                  LocaleKeys.taskPriority.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: PriorityLevel.values.map((p) {
                    final selected = _selectedPriority == p;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPriority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? p.color.withOpacity(0.2) : AppColors.glassSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? p.color : AppColors.glassBorder,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            p.labelKey.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                              color: selected ? p.color : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Target Date Picker Tile
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.primaryCyan,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              LocaleKeys.taskDate.tr(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          dateFormat.format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Reminder Time Picker Tile
                GestureDetector(
                  onTap: _pickReminderTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedReminderTime != null
                          ? AppColors.primaryCyan.withOpacity(0.12)
                          : AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedReminderTime != null
                            ? AppColors.primaryCyan.withOpacity(0.5)
                            : AppColors.glassBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _selectedReminderTime != null
                                  ? Icons.alarm_on_rounded
                                  : Icons.alarm_add_rounded,
                              color: _selectedReminderTime != null
                                  ? AppColors.primaryCyan
                                  : AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              LocaleKeys.reminderTime.tr(),
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedReminderTime != null
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              _selectedReminderTime != null
                                  ? DateFormat('HH:mm').format(_selectedReminderTime!)
                                  : LocaleKeys.noReminder.tr(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selectedReminderTime != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _selectedReminderTime != null
                                    ? AppColors.primaryCyan
                                    : AppColors.textMuted,
                              ),
                            ),
                            if (_selectedReminderTime != null) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: _clearReminder,
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons: Cancel & Save
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.glassBorder),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(LocaleKeys.cancel.tr()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          LocaleKeys.save.tr(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
