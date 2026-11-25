import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/auth_guard_modal.dart';
import '../controllers/planner_controller.dart';
import '../models/note_model.dart';
import '../widgets/period_tabs_bar.dart';
import '../widgets/calendar_navigator_bar.dart';
import '../widgets/note_card.dart';
import '../widgets/add_edit_note_dialog.dart';
import 'yearly_dashboard_screen.dart';

class PlannerScreen extends StatelessWidget {
  final PlannerController controller;
  final VoidCallback onOpenDrawer;

  const PlannerScreen({
    super.key,
    required this.controller,
    required this.onOpenDrawer,
  });

  bool _checkAuth(BuildContext context) {
    if (!SupabaseService.isAuthenticated) {
      AuthGuardModal.show(context, onAuthSuccess: controller.syncWithCloud);
      return false;
    }
    return true;
  }

  void _showAddEditDialog(BuildContext context, [NoteModel? existingNote]) {
    if (!_checkAuth(context)) return;

    showDialog(
      context: context,
      builder: (ctx) => AddEditNoteDialog(
        existingNote: existingNote,
        initialPeriod: controller.activePeriod,
        initialDate: controller.selectedDate,
        onSave: ({
          required String title,
          required String description,
          required DateTime targetDate,
          required PriorityLevel priority,
          required PeriodType periodType,
          DateTime? reminderTime,
        }) {
          if (existingNote != null) {
            final updated = existingNote.copyWith(
              title: title,
              description: description,
              targetDate: targetDate,
              priority: priority,
              periodType: periodType,
              reminderTime: reminderTime,
              clearReminderTime: reminderTime == null,
            );
            controller.updateNote(updated);
          } else {
            controller.addNote(
              title: title,
              description: description,
              targetDate: targetDate,
              priority: priority,
              periodType: periodType,
              reminderTime: reminderTime,
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, NoteModel note) {
    if (!_checkAuth(context)) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBgSecondary,
        title: Text(
          LocaleKeys.deleteConfirmTitle.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          LocaleKeys.deleteConfirmMsg.tr(),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteNote(note.id);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
            ),
            child: Text(LocaleKeys.delete.tr()),
          ),
        ],
      ),
    );
  }

  List<NoteModel> _getSampleGuestNotes() {
    final activeDate = controller.selectedDate;
    return [
      NoteModel(
        id: 'sample_1',
        title: LocaleKeys.sampleNote1Title.tr(),
        description: LocaleKeys.sampleNote1Desc.tr(),
        periodType: controller.activePeriod,
        targetDate: activeDate,
        priority: PriorityLevel.high,
        isCompleted: false,
      ),
      NoteModel(
        id: 'sample_2',
        title: LocaleKeys.sampleNote2Title.tr(),
        description: LocaleKeys.sampleNote2Desc.tr(),
        periodType: controller.activePeriod,
        targetDate: activeDate.add(const Duration(hours: 2)),
        priority: PriorityLevel.medium,
        isCompleted: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isGuest = !SupabaseService.isAuthenticated;
        final actualNotes = controller.filteredNotes;
        final isUsingSampleNotes = isGuest && controller.allNotes.isEmpty;
        final displayNotes = isUsingSampleNotes ? _getSampleGuestNotes() : actualNotes;

        final total = isUsingSampleNotes ? displayNotes.length : controller.totalForActivePeriod;
        final completed = isUsingSampleNotes
            ? displayNotes.where((n) => n.isCompleted).length
            : controller.completedForActivePeriod;
        final progress = total > 0 ? (completed / total) : 0.0;

        return Scaffold(
          backgroundColor: AppColors.darkBg,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded, size: 26),
              onPressed: onOpenDrawer,
            ),
            title: Text(
              LocaleKeys.plannerTitle.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            actions: [
              // Analytics Dashboard Shortcut Button
              IconButton(
                icon: const Icon(Icons.insights_rounded, color: AppColors.primaryCyan, size: 22),
                tooltip: LocaleKeys.analytics.tr(),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => YearlyDashboardScreen(controller: controller),
                    ),
                  );
                },
              ),
              // Cloud Sync / Guest Status Pill
              GestureDetector(
                onTap: isGuest
                    ? () => AuthGuardModal.show(context, onAuthSuccess: controller.syncWithCloud)
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: !isGuest
                        ? AppColors.primaryGreen.withOpacity(0.15)
                        : AppColors.accentAmber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: !isGuest
                          ? AppColors.primaryGreen.withOpacity(0.4)
                          : AppColors.accentAmber.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        !isGuest ? Icons.cloud_done_rounded : Icons.person_outline_rounded,
                        size: 14,
                        color: !isGuest ? AppColors.primaryGreen : AppColors.accentAmber,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        !isGuest ? LocaleKeys.navSyncOnline.tr() : LocaleKeys.guestModeBadge.tr(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: !isGuest ? AppColors.primaryGreen : AppColors.accentAmber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.primaryCyan,
            backgroundColor: AppColors.darkBgSecondary,
            onRefresh: controller.loadNotes,
            child: CustomScrollView(
              slivers: [
                // Guest Banner (when unauthenticated)
                if (isGuest)
                  SliverToBoxAdapter(
                    child: GestureDetector(
                      onTap: () => AuthGuardModal.show(context, onAuthSuccess: controller.syncWithCloud),
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryCyan.withOpacity(0.12),
                              AppColors.accentIndigo.withOpacity(0.12),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.primaryCyan, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                LocaleKeys.authGuardMessage.tr(),
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryCyan,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                LocaleKeys.signIn.tr(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Header with Progress summary
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.darkBgSecondary,
                          AppColors.darkBgCard.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.glassBorder, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LocaleKeys.plannerSubtitle.tr(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  LocaleKeys.completedCount.tr(args: [
                                    '$completed',
                                    '$total',
                                  ]),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            // Circular / Percent Badge
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryGreen.withOpacity(0.15),
                                border: Border.all(
                                  color: AppColors.primaryGreen.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: AppColors.glassSurface,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Link to 365-Day Analytics
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => YearlyDashboardScreen(controller: controller),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryCyan.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryCyan.withOpacity(0.2),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.auto_graph_rounded,
                                  size: 14,
                                  color: AppColors.primaryCyan,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  LocaleKeys.viewAnalytics.tr(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryCyan,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 11,
                                  color: AppColors.primaryCyan,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Period Tabs (Daily, Weekly, Monthly, Yearly)
                SliverToBoxAdapter(
                  child: PeriodTabsBar(
                    activePeriod: controller.activePeriod,
                    onPeriodSelected: controller.setPeriodType,
                    getCount: (type) {
                      if (isUsingSampleNotes) {
                        return type == controller.activePeriod ? displayNotes.length : 0;
                      }
                      return controller.getCountForPeriod(type);
                    },
                  ),
                ),

                // Dynamic Real Calendar Navigator Bar (Daily strip, Weekly, Monthly, Yearly)
                SliverToBoxAdapter(
                  child: CalendarNavigatorBar(controller: controller),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Notes List or Empty State
                if (displayNotes.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.glassSurface,
                                border: Border.all(color: AppColors.glassBorder),
                              ),
                              child: const Icon(
                                Icons.assignment_outlined,
                                size: 48,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              LocaleKeys.emptyTasksTitle.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              LocaleKeys.emptyTasksDesc.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditDialog(context),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(LocaleKeys.addTaskBtn.tr()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryCyan,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final note = displayNotes[index];
                        return NoteCard(
                          note: note,
                          onToggle: () {
                            if (!_checkAuth(context)) return;
                            controller.toggleComplete(note);
                          },
                          onEdit: () {
                            if (!_checkAuth(context)) return;
                            _showAddEditDialog(context, note);
                          },
                          onDelete: () {
                            if (!_checkAuth(context)) return;
                            _confirmDelete(context, note);
                          },
                        );
                      },
                      childCount: displayNotes.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddEditDialog(context),
            backgroundColor: AppColors.primaryCyan,
            foregroundColor: Colors.black,
            elevation: 4,
            icon: const Icon(Icons.add_rounded, size: 22),
            label: Text(
              LocaleKeys.addTaskBtn.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        );
      },
    );
  }
}
