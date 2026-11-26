import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../models/pomodoro_state.dart';

class TimerDisplay extends StatefulWidget {
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
  State<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.18, end: 0.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isRunning) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant TimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.animateTo(0.0, duration: const Duration(milliseconds: 400));
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.phase.color;

    return Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final pulseVal = _pulseController.value;
          final outerGlowOpacity = widget.isRunning
              ? (0.15 + 0.15 * pulseVal)
              : 0.08;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Living Concentric Breathing Pulse Ring 2 (Outer Ripple)
              if (widget.isRunning)
                Transform.scale(
                  scale: 1.0 + (0.12 * pulseVal),
                  child: Container(
                    width: 254,
                    height: 254,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeColor.withValues(
                          alpha: _opacityAnimation.value * 0.7,
                        ),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

              // Living Concentric Breathing Pulse Ring 1 (Inner Pulse)
              if (widget.isRunning)
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 246,
                    height: 246,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeColor.withValues(
                          alpha: _opacityAnimation.value,
                        ),
                        width: 2.0,
                      ),
                    ),
                  ),
                ),

              // Outer Dynamic Glow
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: outerGlowOpacity),
                      blurRadius: widget.isRunning ? (35 + 15 * pulseVal) : 35,
                      spreadRadius: widget.isRunning ? (6 + 4 * pulseVal) : 6,
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
                    AppColors.glassSurfaceLight.withValues(alpha: 0.15),
                  ),
                ),
              ),

              // Active Animated Progress Ring
              SizedBox(
                width: 240,
                height: 240,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  tween: Tween<double>(begin: 0.0, end: widget.progress),
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
                      color: themeColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: themeColor.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.phase == PomodoroPhase.focus
                              ? Icons.local_fire_department_rounded
                              : Icons.coffee_rounded,
                          size: 14,
                          color: themeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.phase.titleKey.tr(),
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
                    widget.formattedTime,
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
                      '${widget.currentSession}',
                      '${widget.totalSessions}',
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
          );
        },
      ),
    );
  }
}
