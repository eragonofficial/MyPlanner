import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../models/note_model.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd(context.locale.toString());
    final formattedDate = dateFormat.format(note.targetDate);

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accentRed.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: note.isCompleted
              ? AppColors.darkBgSecondary.withOpacity(0.6)
              : AppColors.darkBgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: note.isCompleted
                ? AppColors.glassBorder.withOpacity(0.4)
                : note.priority.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Priority color indicator bar
                Container(
                  width: 5,
                  color: note.isCompleted
                      ? AppColors.textMuted.withOpacity(0.5)
                      : note.priority.color,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Custom Animated Checkbox
                            GestureDetector(
                              onTap: onToggle,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(right: 12, top: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: note.isCompleted
                                      ? AppColors.primaryGreen
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: note.isCompleted
                                        ? AppColors.primaryGreen
                                        : AppColors.textSecondary,
                                    width: 2,
                                  ),
                                ),
                                child: note.isCompleted
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                            ),
                            // Title & Description
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: note.isCompleted
                                          ? AppColors.textMuted
                                          : AppColors.textPrimary,
                                      decoration: note.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: AppColors.textMuted,
                                    ),
                                  ),
                                  if (note.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      note.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: note.isCompleted
                                            ? AppColors.textMuted.withOpacity(0.7)
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Actions Menu (Edit / Delete)
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              color: AppColors.darkBgSecondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.glassBorder),
                              ),
                              onSelected: (val) {
                                if (val == 'edit') onEdit();
                                if (val == 'delete') onDelete();
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit_outlined,
                                          size: 18, color: AppColors.primaryCyan),
                                      const SizedBox(width: 8),
                                      Text(LocaleKeys.editTask.tr(),
                                          style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_outline,
                                          size: 18, color: AppColors.accentRed),
                                      const SizedBox(width: 8),
                                      Text(LocaleKeys.delete.tr(),
                                          style: const TextStyle(
                                              fontSize: 14, color: AppColors.accentRed)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Bottom row: Priority pill and Target Date
                        Row(
                          children: [
                            // Priority badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: note.priority.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: note.priority.color.withOpacity(0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                note.priority.labelKey.tr(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: note.priority.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Target date
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            if (note.reminderTime != null) ...[
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.alarm_rounded,
                                    size: 13,
                                    color: note.isCompleted
                                        ? AppColors.textMuted
                                        : AppColors.primaryCyan,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    DateFormat('HH:mm').format(note.reminderTime!),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: note.isCompleted
                                          ? AppColors.textMuted
                                          : AppColors.primaryCyan,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Spacer(),
                            // Status label
                            Text(
                              note.isCompleted
                                  ? LocaleKeys.taskCompleted.tr()
                                  : LocaleKeys.taskPending.tr(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: note.isCompleted
                                    ? AppColors.primaryGreen
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
