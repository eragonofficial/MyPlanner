import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../models/note_model.dart';

class NoteCard extends StatefulWidget {
  final NoteModel note;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onReschedule;

  const NoteCard({
    super.key,
    required this.note,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.onReschedule,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> with SingleTickerProviderStateMixin {
  late AnimationController _celebrationController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void didUpdateWidget(covariant NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger celebration sparkle burst when marked completed
    if (!oldWidget.note.isCompleted && widget.note.isCompleted) {
      _celebrationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _handleToggle() {
    if (!kIsWeb) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }
    if (!widget.note.isCompleted) {
      _celebrationController.forward(from: 0.0);
    }
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final dateFormat = DateFormat.yMMMd(context.locale.toString());
    final formattedDate = dateFormat.format(note.targetDate);
    final isOverdue = note.isOverdue();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleColor = note.isCompleted
        ? AppColors.getCompletedTextColor(isDark)
        : (isDark ? AppColors.textPrimary : AppColors.textOnLight);
    final strikethroughColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF047857);
    final descColor = note.isCompleted
        ? (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF065F46))
        : (isDark ? AppColors.textSecondary : AppColors.textOnLightSecondary);
    final metaColor = note.isCompleted
        ? (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF047857))
        : (isDark ? AppColors.textMuted : AppColors.textOnLightMuted);
    final barColor = note.isCompleted
        ? (isDark ? AppColors.primaryGreen : const Color(0xFF059669))
        : (isOverdue ? AppColors.accentRed : note.priority.color);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Dismissible(
        key: ValueKey(note.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accentRed.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
        ),
        onDismissed: (_) => widget.onDelete(),
        child: AnimatedBuilder(
          animation: _celebrationController,
          builder: (context, child) {
            final celebrationVal = _celebrationController.value;
            final isCelebrating = _celebrationController.isAnimating;

            final cardBg = note.isCompleted
                ? AppColors.getCompletedCardBg(isDark)
                : (isDark ? AppColors.darkBgCard : Colors.white);
            final cardBorderColor = isCelebrating
                ? AppColors.primaryGreen.withValues(
                    alpha: 0.4 + 0.5 * math.sin(celebrationVal * math.pi),
                  )
                : (note.isCompleted
                    ? (isDark ? AppColors.primaryGreen.withValues(alpha: 0.35) : const Color(0xFF6EE7B7))
                    : (isOverdue
                        ? AppColors.accentRed.withValues(alpha: 0.4)
                        : note.priority.color.withValues(alpha: _isHovered ? 0.6 : 0.3)));

            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, _isHovered ? -2.0 : 0.0, 0),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cardBorderColor,
                  width: _isHovered ? 1.2 : 1.0,
                ),
                boxShadow: [
                  if (isCelebrating)
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(
                        alpha: (1.0 - celebrationVal) * 0.4,
                      ),
                      blurRadius: 18,
                      spreadRadius: 2,
                    )
                  else if (_isHovered)
                    BoxShadow(
                      color: (isOverdue ? AppColors.accentRed : note.priority.color)
                          .withValues(alpha: 0.20),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: child,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Priority indicator bar
                  Container(
                    width: 5,
                    color: barColor,
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
                              // Checkbox with spring pop scale + particle burst overlay
                              CustomPaint(
                                foregroundPainter: _celebrationController.isAnimating
                                    ? _CelebrationSparklePainter(
                                        progress: _celebrationController.value,
                                      )
                                    : null,
                                child: GestureDetector(
                                  onTap: _handleToggle,
                                  child: AnimatedBuilder(
                                    animation: _celebrationController,
                                    builder: (context, _) {
                                      final isCelebrating = _celebrationController.isAnimating;
                                      final celebrationVal = _celebrationController.value;

                                      return Transform.scale(
                                        scale: isCelebrating
                                            ? (1.0 + 0.28 * math.sin(celebrationVal * math.pi))
                                            : 1.0,
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
                                                  : (isOverdue
                                                      ? AppColors.accentRed
                                                      : AppColors.textSecondary),
                                              width: 2,
                                            ),
                                            boxShadow: isCelebrating
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors.primaryGreen.withValues(alpha: 0.5),
                                                      blurRadius: 8,
                                                      spreadRadius: 1,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: note.isCompleted
                                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Title & Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: AnimatedDefaultTextStyle(
                                            duration: const Duration(milliseconds: 200),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: titleColor,
                                              decoration: note.isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              decorationColor: strikethroughColor,
                                            ),
                                            child: Text(note.title),
                                          ),
                                        ),
                                        if (isOverdue) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentRed.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: AppColors.accentRed.withValues(alpha: 0.4),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              LocaleKeys.uncompletedPlans.tr(),
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.accentRed,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (note.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        note.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: descColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Actions Menu (Reschedule / Edit / Delete)
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
                                  if (val == 'reschedule' && widget.onReschedule != null) {
                                    widget.onReschedule!();
                                  }
                                  if (val == 'edit') widget.onEdit();
                                  if (val == 'delete') widget.onDelete();
                                },
                                itemBuilder: (context) => [
                                  if (isOverdue && widget.onReschedule != null)
                                    PopupMenuItem(
                                      value: 'reschedule',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.event_repeat_rounded,
                                              size: 18, color: AppColors.primaryCyan),
                                          const SizedBox(width: 8),
                                          Text(LocaleKeys.rescheduleToToday.tr(),
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.primaryCyan,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
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
                        // Bottom row: Priority pill, Target Date, and Quick Reschedule Button
                        Row(
                          children: [
                            // Priority badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: note.priority.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: note.priority.color.withValues(alpha: 0.4),
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
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13,
                                  color: isOverdue ? AppColors.accentRed : metaColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOverdue ? AppColors.accentRed : metaColor,
                                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500,
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
                                        ? metaColor
                                        : AppColors.primaryCyan,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    DateFormat('HH:mm').format(note.reminderTime!),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: note.isCompleted
                                          ? metaColor
                                          : AppColors.primaryCyan,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Spacer(),

                            // Quick Reschedule action or Status label
                            if (isOverdue && widget.onReschedule != null)
                              InkWell(
                                onTap: widget.onReschedule,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryCyan.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.primaryCyan.withValues(alpha: 0.4),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.event_repeat_rounded,
                                          size: 13, color: AppColors.primaryCyan),
                                      const SizedBox(width: 4),
                                      Text(
                                        LocaleKeys.rescheduleToToday.tr(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryCyan,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Text(
                                note.isCompleted
                                    ? LocaleKeys.taskCompleted.tr()
                                    : LocaleKeys.taskPending.tr(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: note.isCompleted
                                      ? (isDark ? AppColors.primaryGreen : const Color(0xFF047857))
                                      : metaColor,
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
    ),
  );
}
}

class _CelebrationSparklePainter extends CustomPainter {
  final double progress;

  _CelebrationSparklePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = Offset(size.width / 2, size.height / 2);
    const count = 10;
    final maxRadius = 36.0 * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    final colors = [
      AppColors.primaryGreen,
      AppColors.primaryCyan,
      AppColors.accentAmber,
      Colors.white,
    ];

    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi / count) + (progress * 0.5);
      final dist = maxRadius * (0.8 + 0.2 * math.sin(i * 3));
      final pOffset = Offset(
        center.dx + dist * math.cos(angle),
        center.dy + dist * math.sin(angle),
      );

      final color = colors[i % colors.length].withValues(alpha: opacity);
      final r = (2.2 * (1.0 - progress * 0.5)).clamp(0.6, 2.5);

      final paint = Paint()..color = color;
      canvas.drawCircle(pOffset, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationSparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
