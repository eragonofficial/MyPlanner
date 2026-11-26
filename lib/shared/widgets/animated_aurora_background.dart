import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// A lightweight, continuous living aurora glow & particle background layer
/// designed for high 60fps performance across Android and Web without distracting
/// from foreground content readability.
class AnimatedAuroraBackground extends StatefulWidget {
  final Widget child;
  final bool showParticles;
  final double intensity;

  const AnimatedAuroraBackground({
    super.key,
    required this.child,
    this.showParticles = true,
    this.intensity = 1.0,
  });

  @override
  State<AnimatedAuroraBackground> createState() => _AnimatedAuroraBackgroundState();
}

class _AnimatedAuroraBackgroundState extends State<AnimatedAuroraBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random(101);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();

    if (widget.showParticles) {
      for (int i = 0; i < 24; i++) {
        _particles.add(
          _Particle(
            x: _random.nextDouble(),
            y: _random.nextDouble(),
            radius: _random.nextDouble() * 2.0 + 0.8,
            speed: _random.nextDouble() * 0.12 + 0.04,
            opacity: _random.nextDouble() * 0.35 + 0.10,
            phase: _random.nextDouble() * 2 * math.pi,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _AmbientAuroraPainter(
            progress: _controller.value,
            particles: _particles,
            intensity: widget.intensity,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _Particle {
  double x;
  double y;
  final double radius;
  final double speed;
  final double opacity;
  final double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.phase,
  });
}

class _AmbientAuroraPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;
  final double intensity;

  _AmbientAuroraPainter({
    required this.progress,
    required this.particles,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    // Dark sleek background
    final bgPaint = Paint()..color = AppColors.darkBg;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final t = progress * 2 * math.pi;

    // 1. Cyan floating orb (Top left)
    final orb1Center = Offset(
      w * 0.20 + 45 * math.cos(t),
      h * 0.22 + 35 * math.sin(t),
    );
    final orb1Radius = w * 0.40;
    final orb1Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryCyan.withValues(alpha: 0.10 * intensity),
          AppColors.primaryCyan.withValues(alpha: 0.02 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: orb1Center, radius: orb1Radius));
    canvas.drawCircle(orb1Center, orb1Radius, orb1Paint);

    // 2. Indigo/Purple floating orb (Top right)
    final orb2Center = Offset(
      w * 0.80 - 40 * math.sin(t * 1.1),
      h * 0.30 + 40 * math.cos(t * 0.9),
    );
    final orb2Radius = w * 0.45;
    final orb2Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accentIndigo.withValues(alpha: 0.09 * intensity),
          AppColors.accentIndigo.withValues(alpha: 0.02 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.60, 1.0],
      ).createShader(Rect.fromCircle(center: orb2Center, radius: orb2Radius));
    canvas.drawCircle(orb2Center, orb2Radius, orb2Paint);

    // 3. Emerald Green floating orb (Center bottom)
    final orb3Center = Offset(
      w * 0.50 + 35 * math.sin(t * 0.85),
      h * 0.72 - 30 * math.cos(t * 1.15),
    );
    final orb3Radius = w * 0.38;
    final orb3Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryGreen.withValues(alpha: 0.08 * intensity),
          AppColors.primaryGreen.withValues(alpha: 0.02 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: orb3Center, radius: orb3Radius));
    canvas.drawCircle(orb3Center, orb3Radius, orb3Paint);

    // Floating micro dust particles
    for (final p in particles) {
      final currentY = (p.y - progress * p.speed) % 1.0;
      final currentX = (p.x + 0.015 * math.sin(t * 2 + p.phase)) % 1.0;
      final offset = Offset(currentX * w, currentY * h);

      final particlePaint = Paint()
        ..color = Colors.white.withValues(
          alpha: p.opacity * intensity * (0.6 + 0.4 * math.sin(t * 3 + p.phase)),
        );
      canvas.drawCircle(offset, p.radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientAuroraPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.intensity != intensity;
  }
}
