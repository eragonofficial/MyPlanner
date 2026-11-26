import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../controllers/planner_controller.dart';
import '../models/note_model.dart';

class YearlyDashboardScreen extends StatefulWidget {
  final PlannerController controller;

  const YearlyDashboardScreen({super.key, required this.controller});

  @override
  State<YearlyDashboardScreen> createState() => _YearlyDashboardScreenState();
}

class _YearlyDashboardScreenState extends State<YearlyDashboardScreen> {
  late int _selectedYear;
  DateTime? _selectedHeatmapDate;
  int _selectedHeatmapCount = 0;

  @override
  void initState() {
    super.initState();
    // Dynamically initialized to the current real calendar year
    _selectedYear = DateTime.now().year;
  }

  // Calculate streak: consecutive calendar days ending today (or within selected year) with completed tasks
  int _calculateStreak(List<NoteModel> notes) {
    if (notes.isEmpty) return 0;

    final completedDates = notes
        .where((n) => n.isCompleted)
        .map((n) => DateTime(n.targetDate.year, n.targetDate.month, n.targetDate.day))
        .toSet();

    if (completedDates.isEmpty) return 0;

    final now = DateTime.now();
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    if (!completedDates.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      if (!completedDates.contains(checkDate)) {
        return 0;
      }
    }

    int streak = 0;
    while (completedDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  // Precompute map of YYYY-MM-DD -> completed count for selected year
  Map<String, int> _buildDayCompletionMap(List<NoteModel> notes) {
    final Map<String, int> map = {};
    for (final note in notes) {
      if (note.isCompleted && note.targetDate.year == _selectedYear) {
        final key = '${note.targetDate.year}-${note.targetDate.month.toString().padLeft(2, '0')}-${note.targetDate.day.toString().padLeft(2, '0')}';
        map[key] = (map[key] ?? 0) + 1;
      }
    }
    return map;
  }

  Color _getHeatmapColor(int count) {
    if (count == 0) return AppColors.glassSurface;
    if (count == 1) return AppColors.primaryGreen.withValues(alpha: 0.35);
    if (count == 2) return AppColors.primaryGreen.withValues(alpha: 0.65);
    return AppColors.primaryGreen;
  }

  @override
  Widget build(BuildContext context) {
    final allNotes = widget.controller.allNotes;
    final yearNotes = allNotes.where((n) => n.targetDate.year == _selectedYear).toList();

    final totalYearTasks = yearNotes.length;
    final completedYearTasks = yearNotes.where((n) => n.isCompleted).length;
    final completionRate = totalYearTasks > 0
        ? ((completedYearTasks / totalYearTasks) * 100).toInt()
        : 0;

    final streak = _calculateStreak(allNotes);
    final completionMap = _buildDayCompletionMap(allNotes);

    final isLeap = PlannerController.isLeapYear(_selectedYear);
    final daysInYear = PlannerController.daysInYear(_selectedYear);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(
          LocaleKeys.dashboardTitle.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Year Selector Bar with Leap Year indicator
              _buildYearSelector(isLeap: isLeap, daysInYear: daysInYear),

              const SizedBox(height: 16),

              // 365/366-Day Completion Overview Card
              _buildOverviewCard(
                completed: completedYearTasks,
                total: totalYearTasks,
                percentage: completionRate,
                streak: streak,
                daysInYear: daysInYear,
              ),

              const SizedBox(height: 20),

              // Period Breakdown Cards (Daily, Weekly, Monthly, Yearly)
              _buildPeriodBreakdown(yearNotes),

              const SizedBox(height: 24),

              // 365/366-Day Activity Heatmap Grid
              _buildHeatmapSection(completionMap, daysInYear),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearSelector({required bool isLeap, required int daysInYear}) {
    final now = DateTime.now();
    final isCurrentYear = _selectedYear == now.year;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primaryCyan),
            onPressed: () {
              setState(() {
                _selectedYear--;
                _selectedHeatmapDate = null;
              });
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_selectedYear',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLeap ? AppColors.accentAmber.withValues(alpha: 0.2) : AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isLeap ? AppColors.accentAmber.withValues(alpha: 0.5) : AppColors.glassBorder,
                      ),
                    ),
                    child: Text(
                      isLeap ? LocaleKeys.leapYear.tr() : LocaleKeys.regularYear.tr(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isLeap ? AppColors.accentAmber : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    LocaleKeys.daysCount.tr(args: ['$daysInYear']),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  if (!isCurrentYear) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedYear = DateTime.now().year;
                          _selectedHeatmapDate = null;
                        });
                      },
                      child: Text(
                        LocaleKeys.thisYear.tr(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryCyan,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryCyan),
            onPressed: () {
              setState(() {
                _selectedYear++;
                _selectedHeatmapDate = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required int completed,
    required int total,
    required int percentage,
    required int streak,
    required int daysInYear,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.darkBgSecondary,
            AppColors.darkBgCard.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocaleKeys.yearOverview.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              // Active streak badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentAmber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 16, color: AppColors.accentAmber),
                    const SizedBox(width: 4),
                    Text(
                      LocaleKeys.streakDays.tr(args: ['$streak']),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentAmber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Circular Percentage ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: total > 0 ? (completed / total) : 0.0,
                      strokeWidth: 7,
                      backgroundColor: AppColors.glassSurface,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Metrics
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completed / $total',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleKeys.completedCount.tr(args: ['$completed', '$total']),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodBreakdown(List<NoteModel> yearNotes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.periodBreakdown.tr(),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildBreakdownItem(PeriodType.daily, yearNotes)),
            const SizedBox(width: 10),
            Expanded(child: _buildBreakdownItem(PeriodType.weekly, yearNotes)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildBreakdownItem(PeriodType.monthly, yearNotes)),
            const SizedBox(width: 10),
            Expanded(child: _buildBreakdownItem(PeriodType.yearly, yearNotes)),
          ],
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(PeriodType period, List<NoteModel> yearNotes) {
    final periodNotes = yearNotes.where((n) => n.periodType == period).toList();
    final total = periodNotes.length;
    final completed = periodNotes.where((n) => n.isCompleted).length;
    final rate = total > 0 ? (completed / total) : 0.0;
    final percent = (rate * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                period.labelKey.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 5,
              backgroundColor: AppColors.glassSurface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryCyan),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$completed / $total',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapSection(Map<String, int> completionMap, int daysInYear) {
    final locale = context.locale.toString();
    final now = DateTime.now();

    // Start Jan 1 and End Dec 31
    final startDate = DateTime(_selectedYear, 1, 1);
    final endDate = DateTime(_selectedYear, 12, 31);
    final totalDays = endDate.difference(startDate).inDays + 1;

    // ISO Weekday: Monday = 1 (row 0), Sunday = 7 (row 6)
    final List<List<DateTime?>> weeks = [];
    List<DateTime?> currentWeek = List.filled(7, null);

    // Track which week each month starts on for the header labels
    final Map<int, String> monthLabels = {};

    for (int i = 0; i < totalDays; i++) {
      final date = startDate.add(Duration(days: i));
      final dayOfWeek = date.weekday - 1; // 0=Mon .. 6=Sun
      currentWeek[dayOfWeek] = date;

      // When day is the 1st of a month, mark this week with localized month short name
      if (date.day == 1) {
        monthLabels[weeks.length] = DateFormat.MMM(locale).format(date);
      }

      if (dayOfWeek == 6 || i == totalDays - 1) {
        weeks.add(List.from(currentWeek));
        currentWeek = List.filled(7, null);
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocaleKeys.activityHeatmap.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              // Legend
              Row(
                children: [
                  Text(
                    LocaleKeys.heatmapLegendLess.tr(),
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 4),
                  _buildLegendBox(0),
                  const SizedBox(width: 2),
                  _buildLegendBox(1),
                  const SizedBox(width: 2),
                  _buildLegendBox(2),
                  const SizedBox(width: 2),
                  _buildLegendBox(3),
                  const SizedBox(width: 4),
                  Text(
                    LocaleKeys.heatmapLegendMore.tr(),
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Heatmap with Weekday labels on left & Month labels on top
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekday indicators (Mon, Wed, Fri)
              Padding(
                padding: const EdgeInsets.only(top: 20, right: 6),
                child: Column(
                  children: [
                    _buildWeekdayLabel('M'),
                    const SizedBox(height: 17),
                    _buildWeekdayLabel('W'),
                    const SizedBox(height: 17),
                    _buildWeekdayLabel('F'),
                    const SizedBox(height: 17),
                    _buildWeekdayLabel('S'),
                  ],
                ),
              ),

              // Scrollable 52-Week Grid with Month headers
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month headers row
                      Row(
                        children: List.generate(weeks.length, (weekIndex) {
                          final label = monthLabels[weekIndex];
                          return SizedBox(
                            width: 17, // cell width (14) + margins (3)
                            child: label != null
                                ? OverflowBox(
                                    maxWidth: 34,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          );
                        }),
                      ),
                      const SizedBox(height: 4),

                      // Weeks grid
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: weeks.map((week) {
                          return Column(
                            children: week.map((date) {
                              if (date == null) {
                                return Container(
                                  width: 14,
                                  height: 14,
                                  margin: const EdgeInsets.all(1.5),
                                  color: Colors.transparent,
                                );
                              }

                              final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                              final count = completionMap[key] ?? 0;
                              final isSelected = _selectedHeatmapDate == date;
                              final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedHeatmapDate = date;
                                    _selectedHeatmapCount = count;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 14,
                                  height: 14,
                                  margin: const EdgeInsets.all(1.5),
                                  decoration: BoxDecoration(
                                    color: _getHeatmapColor(count),
                                    borderRadius: BorderRadius.circular(3),
                                    border: isSelected
                                        ? Border.all(color: Colors.white, width: 1.5)
                                        : (isToday
                                            ? Border.all(color: AppColors.primaryCyan, width: 1.2)
                                            : Border.all(color: AppColors.glassBorder.withValues(alpha: 0.25), width: 0.5)),
                                    boxShadow: isToday
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primaryCyan.withValues(alpha: 0.4),
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Tapped cell details banner
          if (_selectedHeatmapDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryCyan),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      LocaleKeys.heatmapTooltip.tr(args: [
                        '$_selectedHeatmapCount',
                        DateFormat.yMMMd(locale).format(_selectedHeatmapDate!),
                      ]),
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabel(String text) {
    return SizedBox(
      height: 14,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildLegendBox(int level) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _getHeatmapColor(level),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
