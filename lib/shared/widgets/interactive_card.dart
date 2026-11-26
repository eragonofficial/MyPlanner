import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

/// Reusable tactile card with spring bounce on tap, 3D tilt on pointer hover (Web),
/// and soft glowing aura.
class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color accentColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Border? border;

  const InteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.accentColor = AppColors.primaryCyan,
    this.borderRadius,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.border,
  });

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool _isHovered = false;
  bool _isPressed = false;
  Offset _pointerPos = Offset.zero;

  void _triggerHaptic() {
    if (!kIsWeb) {
      try {
        HapticFeedback.selectionClick();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(16);

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
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.onTap != null) {
            setState(() => _isPressed = true);
            _triggerHaptic();
          }
        },
        onTapUp: (_) {
          if (_isPressed) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (_isPressed) setState(() => _isPressed = false);
        },
        onTap: widget.onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth > 0 ? constraints.maxWidth : 300.0;
            final h = constraints.maxHeight > 0 && constraints.maxHeight != double.infinity
                ? constraints.maxHeight
                : 120.0;

            final normX = _isHovered ? ((_pointerPos.dx / w) * 2 - 1).clamp(-1.0, 1.0) : 0.0;
            final normY = _isHovered ? ((_pointerPos.dy / h) * 2 - 1).clamp(-1.0, 1.0) : 0.0;

            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(-normY * 0.04)
              ..rotateY(normX * 0.04)
              ..scale(_isPressed ? 0.97 : (_isHovered ? 1.01 : 1.0));

            return AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              transform: transform,
              transformAlignment: Alignment.center,
              margin: widget.margin,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? AppColors.darkBgCard,
                borderRadius: radius,
                border: widget.border ??
                    Border.all(
                      color: _isHovered
                          ? widget.accentColor.withValues(alpha: 0.5)
                          : AppColors.glassBorder,
                      width: _isHovered ? 1.2 : 0.8,
                    ),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? widget.accentColor.withValues(alpha: 0.20)
                        : Colors.black.withValues(alpha: 0.25),
                    blurRadius: _isHovered ? 18 : 8,
                    offset: Offset(0, _isHovered ? 6 : 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: Stack(
                  children: [
                    if (_isHovered)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(normX, normY),
                              radius: 0.8,
                              colors: [
                                widget.accentColor.withValues(alpha: 0.12),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    widget.child,
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
