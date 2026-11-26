import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../../shared/widgets/animated_aurora_background.dart';
import '../../../shared/widgets/bouncy_button.dart';
import '../../../shared/widgets/pulsing_badge.dart';
import '../controllers/pomodoro_controller.dart';
import '../models/pomodoro_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/timer_display.dart';
import '../widgets/session_dots.dart';
import '../widgets/ambient_sound_bar.dart';

class PomodoroScreen extends StatefulWidget {
  final PomodoroController controller;
  final VoidCallback onOpenDrawer;

  const PomodoroScreen({
    super.key,
    required this.controller,
    required this.onOpenDrawer,
  });

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.onAssetMissingNotice = _showAssetMissingNotice;
    widget.controller.onNotification = _showNotificationDialog;
    widget.controller.preloadSounds();
  }

  void _showAssetMissingNotice(String soundKey) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.darkBgSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primaryGreen, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                LocaleKeys.soundMissingNotice.tr(args: [soundKey]),
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showNotificationDialog(String titleKey, String messageKey) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.primaryGreen),
        ),
        title: Text(
          titleKey.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        content: Text(
          messageKey.tr(),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final currentSession = (controller.completedSessions + 1)
            .clamp(1, controller.targetSessions);

        return Scaffold(
          backgroundColor: AppColors.darkBg,
          body: AnimatedAuroraBackground(
            intensity: 0.9,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.darkNatureGradient,
              ),
              child: SafeArea(
              child: Column(
                children: [
                  // Top App Bar with Drawer button, Title, and Quick Language Toggle Pills
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu_rounded, size: 26),
                          onPressed: widget.onOpenDrawer,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                LocaleKeys.pomodoroTitle.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                LocaleKeys.pomodoroSubtitle.tr(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Quick Language Selector Pills on Pomodoro Screen
                        const QuickLanguagePills(),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),

                          // Mode Toggles (25+5 vs 50+10) & Session Selector
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                // Mode Toggle Pills
                                Expanded(
                                  flex: 5,
                                  child: GlassCard(
                                    padding: const EdgeInsets.all(4),
                                    borderRadius: 14,
                                    child: Row(
                                      children: PomodoroTimerMode.values.map((mode) {
                                        final isSelected = controller.mode == mode;
                                        return Expanded(
                                          child: BouncyButton(
                                            onTap: () => controller.setMode(mode),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppColors.glassSurfaceLight
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(10),
                                                border: isSelected
                                                    ? Border.all(
                                                        color: AppColors.primaryGreen.withValues(alpha: 0.5),
                                                        width: 1,
                                                      )
                                                    : null,
                                              ),
                                              child: Text(
                                                mode.labelKey.tr(),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  color: isSelected
                                                      ? AppColors.primaryGreen
                                                      : AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Sessions Goal Selector
                                Expanded(
                                  flex: 6,
                                  child: GlassCard(
                                    padding: const EdgeInsets.all(4),
                                    borderRadius: 14,
                                    child: Row(
                                      children: [1, 2, 3, 4].map((count) {
                                        final isSelected = controller.targetSessions == count;
                                        return Expanded(
                                          child: BouncyButton(
                                            onTap: () => controller.setTargetSessions(count),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppColors.primaryGreen.withValues(alpha: 0.2)
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(10),
                                                border: isSelected
                                                    ? Border.all(
                                                        color: AppColors.primaryGreen,
                                                        width: 1,
                                                      )
                                                    : null,
                                              ),
                                              child: Text(
                                                '${count}S',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  color: isSelected
                                                      ? AppColors.primaryGreen
                                                      : AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Session Progress Visual Dots
                          SessionDots(
                            targetSessions: controller.targetSessions,
                            completedSessions: controller.completedSessions,
                            isRunning: controller.isRunning,
                            activeColor: controller.phase.color,
                          ),

                          const SizedBox(height: 24),

                          // Large Countdown Timer Display
                          TimerDisplay(
                            formattedTime: controller.formattedTime,
                            progress: controller.progress,
                            phase: controller.phase,
                            currentSession: currentSession,
                            totalSessions: controller.targetSessions,
                            isRunning: controller.isRunning && !controller.isPaused,
                          ),

                          const SizedBox(height: 32),

                          // Action Buttons: Play, Pause, Reset
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Reset Button
                                BouncyButton(
                                  onTap: controller.reset,
                                  child: IconButton.filledTonal(
                                    onPressed: controller.reset,
                                    iconSize: 26,
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.glassSurface,
                                      foregroundColor: AppColors.textSecondary,
                                      padding: const EdgeInsets.all(16),
                                    ),
                                    icon: const Icon(Icons.refresh_rounded),
                                  ),
                                ),
                                const SizedBox(width: 24),

                                // Main Play / Pause Button with living pulse
                                BouncyButton(
                                  onTap: () {
                                    if (!controller.isRunning) {
                                      controller.start();
                                    } else if (controller.isPaused) {
                                      controller.resume();
                                    } else {
                                      controller.pause();
                                    }
                                  },
                                  child: PulsingBadge(
                                    glowColor: controller.phase.color,
                                    maxScale: 1.05,
                                    animate: controller.isRunning && !controller.isPaused,
                                    duration: const Duration(milliseconds: 2000),
                                    child: Container(
                                      width: 76,
                                      height: 76,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: controller.phase == PomodoroPhase.focus
                                            ? AppColors.focusGradient
                                            : AppColors.breakGradient,
                                        boxShadow: [
                                          BoxShadow(
                                            color: controller.phase.color.withValues(alpha: 0.45),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        controller.isRunning && !controller.isPaused
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),

                                // Skip / Next session button
                                BouncyButton(
                                  onTap: controller.isRunning
                                      ? () => controller.reset()
                                      : null,
                                  child: IconButton.filledTonal(
                                    onPressed: controller.isRunning
                                        ? () => controller.reset()
                                        : null,
                                    iconSize: 26,
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.glassSurface,
                                      foregroundColor: AppColors.textSecondary,
                                      padding: const EdgeInsets.all(16),
                                    ),
                                    icon: const Icon(Icons.skip_next_rounded),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Bottom Ambient Nature Sound Bar
                          AmbientSoundBar(
                            activeSounds: controller.activeSounds,
                            onToggleSound: controller.toggleAmbientSound,
                            onClearAllSounds: controller.clearAllSounds,
                            volume: controller.volume,
                            onVolumeChanged: controller.setVolume,
                            isPaused: controller.isPaused,
                            isSoundBuffering: controller.isSoundBuffering,
                          ),

                          const SizedBox(height: 16),
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
    },
    );
  }
}
