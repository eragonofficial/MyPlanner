import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../../../core/services/audio_player_service.dart';
import '../../pomodoro/models/pomodoro_state.dart';

/// A live interactive mini-sandbox where visitors can check off sample tasks,
/// watch animated progress rings, and test Pomodoro timer with ambient audio
/// (1-time guest trial) before signing in.
class InteractiveTryLiveWidget extends StatefulWidget {
  final VoidCallback onStartPlanning;

  const InteractiveTryLiveWidget({super.key, required this.onStartPlanning});

  @override
  State<InteractiveTryLiveWidget> createState() => _InteractiveTryLiveWidgetState();
}

class _InteractiveTryLiveWidgetState extends State<InteractiveTryLiveWidget>
    with SingleTickerProviderStateMixin {
  static const String _keyGuestTrialUsed = 'landing_pomodoro_guest_trial_used';
  static const String _keyGuestTrialStarted = 'landing_pomodoro_guest_trial_started';

  int _activeTab = 0; // 0 = Planner, 1 = Pomodoro

  // Planner state
  final List<bool> _taskStates = [true, false, false];

  // Pomodoro & Audio state
  final AudioPlayerService _audioService = AudioPlayerService();
  bool _isTimerRunning = false;
  bool _trialExhausted = false;
  bool _hasStartedTrialInSession = false;
  int _pomodoroSeconds = 25 * 60;
  Timer? _timer;
  int _selectedSoundIndex = 0;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _audioService.addListener(_onAudioUpdate);
    _loadTrialState();
  }

  void _onAudioUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadTrialState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final used = prefs.getBool(_keyGuestTrialUsed) ?? false;
      final started = prefs.getBool(_keyGuestTrialStarted) ?? false;
      if (used || started) {
        if (!used) {
          await prefs.setBool(_keyGuestTrialUsed, true);
        }
        if (mounted) {
          setState(() => _trialExhausted = true);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _audioService.removeListener(_onAudioUpdate);
    _audioService.dispose();
    super.dispose();
  }

  void _toggleTask(int index) {
    setState(() {
      _taskStates[index] = !_taskStates[index];
    });
  }

  void _togglePomodoroTimer() {
    if (_trialExhausted) {
      _showTrialLimitDialog();
      return;
    }

    if (!_isTimerRunning && !_hasStartedTrialInSession) {
      _hasStartedTrialInSession = true;
      setState(() => _isTimerRunning = true);

      // Unlock and play selected ambient sound synchronously inside user gesture
      if (!_audioService.hasActiveSounds) {
        final sound = AmbientSound.values[_selectedSoundIndex];
        _audioService.playSound(sound.keyName, assetPath: sound.assetPath);
      }

      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool(_keyGuestTrialStarted, true);
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (_pomodoroSeconds > 1) {
          setState(() => _pomodoroSeconds--);
        } else {
          _completeOrEndTrial();
        }
      });
    } else if (_isTimerRunning) {
      // Ending the active trial session finishes the 1-time guest allowance
      _completeOrEndTrial();
    }
  }

  void _completeOrEndTrial() {
    _timer?.cancel();
    _audioService.stopAll();
    setState(() {
      _isTimerRunning = false;
      _pomodoroSeconds = 25 * 60;
      _trialExhausted = true;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_keyGuestTrialUsed, true);
    });
    if (mounted) {
      _showTrialLimitDialog();
    }
  }

  void _onSelectSound(int index) {
    if (_trialExhausted) {
      _showTrialLimitDialog();
      return;
    }

    final sound = AmbientSound.values[index];
    setState(() => _selectedSoundIndex = index);

    if (_audioService.isSoundActive(sound.keyName)) {
      _audioService.pauseSound(sound.keyName);
      return;
    }

    for (final activeKey in _audioService.activeSoundKeys.toList()) {
      if (activeKey != sound.keyName) {
        _audioService.pauseSound(activeKey);
      }
    }
    _audioService.playSound(sound.keyName, assetPath: sound.assetPath);
  }

  void _showTrialLimitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.primaryCyan.withValues(alpha: 0.45)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentAmber.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_clock_rounded,
                color: AppColors.accentAmber,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                LocaleKeys.trialLimitTitle.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          LocaleKeys.trialLimitMsg.tr(),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              LocaleKeys.cancel.tr(),
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onStartPlanning();
            },
            icon: const Icon(Icons.login_rounded, size: 16),
            label: Text(
              LocaleKeys.trialLimitCta.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
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
                        onTap: () {
                          _audioService.stopAll();
                          setState(() => _activeTab = 0);
                        },
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
            decoration: const BoxDecoration(
              color: Color(0xFF161B26),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Color(0xFF334155), width: 0.8),
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF8FAFC),
                      ),
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
                progress == 1.0
                    ? LocaleKeys.taskCompleted.tr()
                    : LocaleKeys.taskPending.tr(),
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
                        ? AppColors.completedBgDark
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDone
                          ? AppColors.primaryGreen.withValues(alpha: 0.6)
                          : const Color(0xFF334155),
                      width: 1.2,
                    ),
                    boxShadow: isDone
                        ? [
                            BoxShadow(
                              color: AppColors.primaryGreen.withValues(alpha: 0.15),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
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
                            color: isDone ? AppColors.primaryGreen : const Color(0xFF94A3B8),
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
                            fontWeight: FontWeight.w600,
                            color: isDone ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            decorationColor: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.drag_indicator_rounded,
                        size: 16,
                        color: isDone
                            ? AppColors.primaryGreen.withValues(alpha: 0.7)
                            : const Color(0xFF94A3B8),
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
    const sounds = AmbientSound.values;

    return Column(
      children: [
        // 1-Time Guest Trial Status Badge or Lock Banner
        if (!_trialExhausted)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryCyan.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  size: 13,
                  color: AppColors.primaryCyan,
                ),
                const SizedBox(width: 6),
                Text(
                  LocaleKeys.trialBadgeAvailable.tr(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryCyan,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accentAmber.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.accentAmber,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        LocaleKeys.trialLimitTitle.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  LocaleKeys.trialLimitMsg.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onStartPlanning,
                    icon: const Icon(Icons.login_rounded, size: 16),
                    label: Text(
                      LocaleKeys.trialLimitCta.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Pomodoro circular timer with pulsing breathing ring
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _togglePomodoroTimer,
              child: Opacity(
                opacity: _trialExhausted ? 0.45 : 1.0,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final glowRadius = _isTimerRunning
                        ? 8.0 + 8.0 * _pulseController.value
                        : 4.0;
                    return Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _trialExhausted
                            ? const LinearGradient(
                                colors: [Color(0xFF475569), Color(0xFF334155)],
                              )
                            : AppColors.focusGradient,
                        boxShadow: [
                          BoxShadow(
                            color: _trialExhausted
                                ? Colors.transparent
                                : AppColors.primaryGreen.withValues(
                                    alpha: _isTimerRunning ? 0.45 : 0.2,
                                  ),
                            blurRadius: glowRadius,
                            spreadRadius: _isTimerRunning ? 3 : 1,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _trialExhausted
                                ? Icons.lock_rounded
                                : (_isTimerRunning
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded),
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
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Mini 7 Ambient Sounds dock (real audible playback + gesture unlock)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (int index = 0; index < sounds.length; index++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _onSelectSound(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Builder(
                      builder: (context) {
                        final sound = sounds[index];
                        final isSelected = _selectedSoundIndex == index;
                        final isPlaying = _audioService.isSoundActive(sound.keyName);
                        final isBuffering = _audioService.isSoundBuffering(sound.keyName);

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isPlaying
                                ? AppColors.primaryGreen.withValues(alpha: 0.25)
                                : (isSelected
                                    ? AppColors.primaryCyan.withValues(alpha: 0.14)
                                    : AppColors.glassSurface),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPlaying
                                  ? AppColors.primaryGreen
                                  : (isSelected
                                      ? AppColors.primaryCyan.withValues(alpha: 0.6)
                                      : AppColors.glassBorder),
                              width: isPlaying ? 1.3 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                sound.icon,
                                size: 15,
                                color: isPlaying
                                    ? AppColors.primaryGreen
                                    : (isSelected
                                        ? AppColors.primaryCyan
                                        : AppColors.textSecondary),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                sound.labelKey.tr(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: (isPlaying || isSelected)
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isPlaying
                                      ? AppColors.primaryGreen
                                      : (isSelected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary),
                                ),
                              ),
                              if (isPlaying) ...[
                                const SizedBox(width: 5),
                                if (isBuffering)
                                  const SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryGreen,
                                      ),
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.volume_up_rounded,
                                    size: 13,
                                    color: AppColors.primaryGreen,
                                  ),
                              ],
                            ],
                          ),
                        );
                      },
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
