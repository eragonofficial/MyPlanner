import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/locale_keys.dart';

/// A live interactive mini-sandbox where visitors can check off sample tasks,
/// watch animated progress rings, and test Pomodoro timer rings before signing in.
class InteractiveTryLiveWidget extends StatefulWidget {
  final VoidCallback onStartPlanning;

  const InteractiveTryLiveWidget({super.key, required this.onStartPlanning});

  @override
  State<InteractiveTryLiveWidget> createState() => _InteractiveTryLiveWidgetState();
}

class _InteractiveTryLiveWidgetState extends State<InteractiveTryLiveWidget>
    with SingleTickerProviderStateMixin {
  int _activeTab = 0; // 0 = Planner, 1 = Pomodoro

  // Planner state
  final List<bool> _taskStates = [true, false, false];

  // Pomodoro state
  bool _isTimerRunning = false;
  int _pomodoroSeconds = 25 * 60;
  Timer? _timer;
  int _selectedSoundIndex = 0;

  final List<({String name, IconData icon})> _sounds = const [
    (name: 'dengiz', icon: Icons.waves_rounded),
    (name: 'hasharot', icon: Icons.nights_stay_rounded),
    (name: 'ormon', icon: Icons.forest_rounded),
    (name: 'qushlar', icon: Icons.flutter_dash),
    (name: 'sharshara', icon: Icons.water_drop_rounded),
    (name: 'toglar', icon: Icons.landscape_rounded),
    (name: 'yomgir', icon: Icons.cloudy_snowing),
  ];

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleTask(int index) {
    setState(() {
      _taskStates[index] = !_taskStates[index];
    });
  }

  void _togglePomodoroTimer() {
    setState(() {
      _isTimerRunning = !_isTimerRunning;
    });

    if (_isTimerRunning) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() {
          if (_pomodoroSeconds > 0) {
            _pomodoroSeconds--;
          } else {
            _isTimerRunning = false;
            _pomodoroSeconds = 25 * 60;
            _timer?.cancel();
          }
        });
      });
    } else {
      _timer?.cancel();
    }
  }

  String _formatTimer(int totalSecs) {
    final m = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _taskStates.where((c) => c).length;
    final progress = completedCount / _taskStates.length;

    return Container(
      constraints: const BoxConstraints(maxWidth: 820),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryCyan.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryCyan.withValues(alpha: 0.15),
            blurRadius: 36,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top macOS-style window header bar & Tab toggles
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.glassBorder, width: 0.8),
              ),
            ),
            child: Row(
              children: [
                // Window dots
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app_rounded, color: AppColors.primaryCyan, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        LocaleKeys.landingTryLive.tr(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryCyan,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Segmented Tab Switcher (Planner vs Pomodoro)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.glassSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTabButton(
                        title: LocaleKeys.periodDaily.tr(),
                        icon: Icons.checklist_rounded,
                        isSelected: _activeTab == 0,
                        onTap: () => setState(() => _activeTab = 0),
                      ),
                      const SizedBox(width: 4),
                      _buildTabButton(
                        title: LocaleKeys.landingSandboxPomodoro.tr(),
                        icon: Icons.timer_outlined,
                        isSelected: _activeTab == 1,
                        onTap: () => setState(() => _activeTab = 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Content (Planner or Pomodoro preview)
          Padding(
            padding: const EdgeInsets.all(22),
            child: _activeTab == 0
                ? _buildPlannerPreview(completedCount, progress)
                : _buildPomodoroPreview(),
          ),

          // Bottom Callout Bar with Shimmer CTA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.glassSurface.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              border: const Border(
                top: BorderSide(color: AppColors.glassBorder, width: 0.8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, color: AppColors.primaryGreen, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      LocaleKeys.landingLivePreview.tr(),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: widget.onStartPlanning,
                  icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                  label: Text(
                    LocaleKeys.landingStartFreeCta.tr(),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryCyan.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlannerPreview(int completedCount, double progress) {
    final tasks = [
      LocaleKeys.landingSandboxTask1.tr(),
      LocaleKeys.landingSandboxTask2.tr(),
      LocaleKeys.landingSandboxTask3.tr(),
    ];

    return Column(
      children: [
        // Live Progress Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3.5,
                        backgroundColor: AppColors.glassSurfaceLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                      ),
                      Center(
                        child: Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.completedCount.tr(args: [
                        '$completedCount',
                        '${_taskStates.length}',
                      ]),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd(context.locale.toString()).format(DateTime.now()),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.4)),
              ),
              child: Text(
                progress == 1.0 ? 'Completed 🎉' : 'In Progress',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Interactive Tasks List
        Column(
          children: List.generate(tasks.length, (i) {
            final isDone = _taskStates[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _toggleTask(i),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.glassSurface.withValues(alpha: 0.4)
                        : AppColors.glassSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDone
                          ? AppColors.primaryGreen.withValues(alpha: 0.4)
                          : AppColors.glassBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? AppColors.primaryGreen : Colors.transparent,
                          border: Border.all(
                            color: isDone ? AppColors.primaryGreen : AppColors.textSecondary,
                            width: 1.8,
                          ),
                        ),
                        child: isDone
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tasks[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            decorationColor: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.drag_indicator_rounded,
                        size: 16,
                        color: AppColors.textMuted.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPomodoroPreview() {
    return Column(
      children: [
        // Pomodoro circular timer with pulsing breathing ring
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _togglePomodoroTimer,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final glowRadius = _isTimerRunning ? 8.0 + 8.0 * _pulseController.value : 4.0;
                  return Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.focusGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: _isTimerRunning ? 0.45 : 0.2),
                          blurRadius: glowRadius,
                          spreadRadius: _isTimerRunning ? 3 : 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        Text(
                          _formatTimer(_pomodoroSeconds),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Mini 7 Ambient Sounds dock
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (int index = 0; index < _sounds.length; index++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedSoundIndex = index),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedSoundIndex == index
                            ? AppColors.primaryGreen.withValues(alpha: 0.25)
                            : AppColors.glassSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedSoundIndex == index
                              ? AppColors.primaryGreen
                              : AppColors.glassBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sounds[index].icon,
                            size: 15,
                            color: _selectedSoundIndex == index
                                ? AppColors.primaryGreen
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _sounds[index].name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: _selectedSoundIndex == index
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _selectedSoundIndex == index
                                  ? AppColors.primaryGreen
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
