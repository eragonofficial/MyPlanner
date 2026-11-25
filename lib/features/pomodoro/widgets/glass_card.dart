import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? surfaceColor;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.surfaceColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor ?? AppColors.glassSurface,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ?? Border.all(color: AppColors.glassBorder, width: 0.8),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
