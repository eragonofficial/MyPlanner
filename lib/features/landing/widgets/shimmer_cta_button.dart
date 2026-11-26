import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// A button with a periodic light-shimmer sweep and spring-scale hover effect.
class ShimmerCtaButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;
  final Color primaryColor;
  final Color textColor;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const ShimmerCtaButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.primaryColor = AppColors.primaryGreen,
    this.textColor = Colors.black,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    this.fontSize = 15,
  });

  @override
  State<ShimmerCtaButton> createState() => _ShimmerCtaButtonState();
}

class _ShimmerCtaButtonState extends State<ShimmerCtaButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: _isHovered ? 0.5 : 0.3),
                    blurRadius: _isHovered ? 24 : 14,
                    spreadRadius: _isHovered ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Base button
                    ElevatedButton(
                      onPressed: widget.onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: widget.textColor,
                        padding: widget.padding,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 18, color: widget.textColor),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: widget.fontSize,
                              fontWeight: FontWeight.bold,
                              color: widget.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Shimmer light sweep overlay
                    Positioned.fill(
                      child: IgnorePointer(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final shimmerX = (_shimmerController.value * (w * 2.5)) - (w * 0.75);
                            return Transform.translate(
                              offset: Offset(shimmerX, 0),
                              child: Container(
                                width: w * 0.45,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.35),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
