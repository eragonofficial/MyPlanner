import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../models/pomodoro_state.dart';

class TimerDisplay extends StatelessWidget {
  final String formattedTime;
  final double progress;
  final PomodoroPhase phase;
  final int currentSession;
  final int totalSessions;
  final bool isRunning;

  const TimerDisplay({
    super.key,
    required this.formattedTime,
    required this.progress,
    required this.phase,
    required this.currentSession,
    required this.totalSessions,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = phase.color;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: themeColor.withOpacity(isRunning ? 0.25 : 0.08),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),

          // Background Track
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.glassSurfaceLight.withOpacity(0.15),
              ),
            ),
          ),

          // Active Animated Progress Ring
          SizedBox(
            width: 240,
            height: 240,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 400),
              tween: Tween<double>(begin: 0.0, end: progress),
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                );
              },
            ),
          ),

          // Center Info
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Phase Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: themeColor.withOpacity(0.4), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      phase == PomodoroPhase.focus
                          ? Icons.local_fire_department_rounded
                          : Icons.coffee_rounded,
                      size: 14,
                      color: themeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      phase.titleKey.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Large Countdown Time
              Text(
                formattedTime,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),

              // Session Count Label
              Text(
                LocaleKeys.sessionCount.tr(args: [
                  '$currentSession',
                  '$totalSessions',
                ]),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
