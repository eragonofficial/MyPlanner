import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// An ultra-modern 3D tilt glass card with pointer-following spotlight glow
/// and smooth elevation on hover.
class InteractiveGlassCard extends StatefulWidget {
  final Widget child;
  final Color accentColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  const InteractiveGlassCard({
    super.key,
    required this.child,
    this.accentColor = AppColors.primaryCyan,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 22,
    this.onTap,
  });

  @override
  State<InteractiveGlassCard> createState() => _InteractiveGlassCardState();
}

class _InteractiveGlassCardState extends State<InteractiveGlassCard> {
  bool _isHovered = false;
  Offset _pointerPos = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        setState(() {
          _isHovered = true;
          _pointerPos = event.localPosition;
        });
      },
      onHover: (event) {
        setState(() {
          _pointerPos = event.localPosition;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
          _pointerPos = Offset.zero;
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth > 0 ? constraints.maxWidth : 300.0;
          final height = constraints.maxHeight > 0 && constraints.maxHeight != double.infinity
              ? constraints.maxHeight
              : 220.0;

          // Normalized pointer offset in range [-1.0, 1.0]
          final normX = _isHovered ? ((_pointerPos.dx / width) * 2 - 1).clamp(-1.0, 1.0) : 0.0;
          final normY = _isHovered ? ((_pointerPos.dy / height) * 2 - 1).clamp(-1.0, 1.0) : 0.0;

          // 3D perspective matrix transform
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective depth
            ..rotateX(-normY * 0.06)
            ..rotateY(normX * 0.06)
            ..translate(0.0, _isHovered ? -6.0 : 0.0, 0.0);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: transform,
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.darkBgSecondary.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: _isHovered
                    ? widget.accentColor.withValues(alpha: 0.6)
                    : AppColors.glassBorder,
                width: _isHovered ? 1.4 : 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? widget.accentColor.withValues(alpha: 0.22)
                      : Colors.black.withValues(alpha: 0.35),
                  blurRadius: _isHovered ? 24 : 12,
                  spreadRadius: _isHovered ? 2 : 0,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Stack(
                children: [
                  // Pointer-following radial spotlight glow
                  if (_isHovered)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(normX, normY),
                            radius: 0.85,
                            colors: [
                              widget.accentColor.withValues(alpha: 0.16),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Card Content
                  InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: Padding(
                      padding: widget.padding,
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
