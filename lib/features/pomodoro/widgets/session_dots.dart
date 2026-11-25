import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SessionDots extends StatelessWidget {
  final int targetSessions;
  final int completedSessions;
  final bool isRunning;
  final Color activeColor;

  const SessionDots({
    super.key,
    required this.targetSessions,
    required this.completedSessions,
    required this.isRunning,
    this.activeColor = AppColors.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(targetSessions, (index) {
        final isCompleted = index < completedSessions;
        final isCurrent = index == completedSessions;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: isCurrent && isRunning ? 20 : 12,
          height: 12,
          decoration: BoxDecoration(
            color: isCompleted
                ? activeColor
                : (isCurrent && isRunning ? activeColor.withOpacity(0.7) : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isCompleted || (isCurrent && isRunning)
                  ? activeColor
                  : AppColors.glassBorder,
              width: 1.5,
            ),
            boxShadow: isCompleted || (isCurrent && isRunning)
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
