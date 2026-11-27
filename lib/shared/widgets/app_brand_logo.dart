import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Shared brand logo widget displaying the official My Planner artwork
/// inside a crisp glowing circular container across Web and Android.
class AppBrandLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const AppBrandLogo({
    super.key,
    this.size = 36,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size >= 44 ? 2.0 : 1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primaryCyan, AppColors.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppColors.primaryCyan.withValues(alpha: 0.35),
                  blurRadius: size >= 48 ? 16 : 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size),
        child: Image.asset(
          'assets/images/planner_ikonka.jpg',
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.25),
        ),
      ),
    );
  }
}
