import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../controllers/planner_controller.dart';
import '../models/note_model.dart';

class CalendarNavigatorBar extends StatelessWidget {
  final PlannerController controller;

  const CalendarNavigatorBar({super.key, required this.controller});

  Future<void> _pickCalendarDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate,
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
      controller.setSelectedDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (controller.activePeriod) {
      case PeriodType.daily:
        return _buildDailyCalendarStrip(context);
      case PeriodType.weekly:
        return _buildWeeklyNavigator(context);
      case PeriodType.monthly:
        return _buildMonthlyNavigator(context);
      case PeriodType.yearly:
        return _buildYearlyNavigator(context);
      case null:
        return const SizedBox.shrink();
    }
  }

  // DAILY: Horizontal date strip around active date + Jump to Today
  Widget _buildDailyCalendarStrip(BuildContext context) {
    final locale = context.locale.toString();
    final selected = controller.selectedDate;
    final today = controller.today;

    // Generate 15 days window centered around selectedDate (e.g. -7 to +7 days)
    final days = List.generate(15, (index) {
      return selected.subtract(Duration(days: 7 - index));
    });

    final formattedHeaderDate = DateFormat.yMMMMd(locale).format(selected);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder, width: 0.8),
      ),
      child: Column(
        children: [
          // Header row: formatted full date & Jump to Today button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _pickCalendarDate(context),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryCyan),
                    const SizedBox(width: 8),
                    Text(
                      formattedHeaderDate,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: AppColors.primaryCyan, size: 20),
                  ],
                ),
              ),
              if (!controller.isSelectedDateToday)
                GestureDetector(
                  onTap: controller.jumpToToday,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryCyan.withOpacity(0.4)),
                    ),
                    child: Text(
                      LocaleKeys.today.tr(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryCyan,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal Date Strip
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final d = days[index];
                final isSelected = d.year == selected.year && d.month == selected.month && d.day == selected.day;
                final isToday = d.year == today.year && d.month == today.month && d.day == today.day;
                final weekdayName = DateFormat.E(locale).format(d); // Mon, Tue, etc. localized

                return GestureDetector(
                  onTap: () => controller.setSelectedDate(d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryCyan
                          : (isToday ? AppColors.primaryCyan.withOpacity(0.12) : AppColors.glassSurface),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryCyan
                            : (isToday ? AppColors.primaryCyan.withOpacity(0.5) : AppColors.glassBorder.withOpacity(0.5)),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekdayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.black : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // WEEKLY: Real ISO Calendar Week Range (Monday to Sunday)
  Widget _buildWeeklyNavigator(BuildContext context) {
    final locale = context.locale.toString();
    final start = controller.selectedWeekStart;
    final end = controller.selectedWeekEnd;
    final now = DateTime.now();

    final isCurrentWeek = !now.isBefore(start) && !now.isAfter(end);
    final weekRangeText = '${DateFormat.MMMd(locale).format(start)} – ${DateFormat.yMMMd(locale).format(end)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
            onPressed: () => controller.changeWeek(-1),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.date_range_rounded, size: 16, color: AppColors.primaryCyan),
                  const SizedBox(width: 6),
                  Text(
                    weekRangeText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (!isCurrentWeek) ...[
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: controller.jumpToToday,
                  child: Text(
                    LocaleKeys.thisWeek.tr(),
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
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryCyan),
            onPressed: () => controller.changeWeek(1),
          ),
        ],
      ),
    );
  }

  // MONTHLY: Real 12 Months of Active Year + Leap Year February accuracy
  Widget _buildMonthlyNavigator(BuildContext context) {
    final locale = context.locale.toString();
    final selected = controller.selectedDate;
    final now = DateTime.now();

    final isCurrentMonth = selected.year == now.year && selected.month == now.month;
    final monthYearText = DateFormat.yMMMM(locale).format(selected);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primaryCyan),
                onPressed: () => controller.changeMonth(-1),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    monthYearText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (!isCurrentMonth) ...[
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: controller.jumpToToday,
                      child: Text(
                        LocaleKeys.thisMonth.tr(),
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
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryCyan),
                onPressed: () => controller.changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 12 Months Quick Switcher Bar
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthNumber = index + 1;
                final isSelected = selected.month == monthNumber;
                final monthDate = DateTime(selected.year, monthNumber, 1);
                final monthShort = DateFormat.MMM(locale).format(monthDate);

                return GestureDetector(
                  onTap: () => controller.setMonth(monthNumber),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryCyan : AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryCyan : AppColors.glassBorder,
                        width: isSelected ? 1.2 : 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      monthShort,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.black : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // YEARLY: Real Calendar Year with Leap Year indicators (365/366 days)
  Widget _buildYearlyNavigator(BuildContext context) {
    final selectedYear = controller.selectedYear;
    final now = DateTime.now();
    final isCurrentYear = selectedYear == now.year;
    final isLeap = PlannerController.isLeapYear(selectedYear);
    final daysCount = PlannerController.daysInYear(selectedYear);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            onPressed: () => controller.changeYear(-1),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$selectedYear',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: isCurrentYear ? AppColors.primaryCyan : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLeap ? AppColors.accentAmber.withOpacity(0.2) : AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isLeap ? AppColors.accentAmber.withOpacity(0.5) : AppColors.glassBorder,
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
              Text(
                LocaleKeys.daysCount.tr(args: ['$daysCount']),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryCyan),
            onPressed: () => controller.changeYear(1),
          ),
        ],
      ),
    );
  }
}
