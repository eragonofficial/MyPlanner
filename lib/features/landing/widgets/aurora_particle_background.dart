import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Dynamic animated mesh-gradient aurora & gently drifting particle background
/// inspired by Linear, Framer, and modern SaaS landing pages.
class AuroraParticleBackground extends StatefulWidget {
  final Widget child;

  const AuroraParticleBackground({super.key, required this.child});

  @override
  State<AuroraParticleBackground> createState() => _AuroraParticleBackgroundState();
}

class _AuroraParticleBackgroundState extends State<AuroraParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    // Generate 32 drifting ambient light particles
    for (int i = 0; i < 32; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          radius: _random.nextDouble() * 2.2 + 0.8,
          speed: _random.nextDouble() * 0.15 + 0.05,
          opacity: _random.nextDouble() * 0.45 + 0.15,
          phase: _random.nextDouble() * 2 * math.pi,
        ),
      );
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
          painter: _AuroraPainter(
            progress: _controller.value,
            particles: _particles,
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

class _AuroraPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  _AuroraPainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    // Dark sleek foundation
    final bgPaint = Paint()..color = AppColors.darkBg;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final t = progress * 2 * math.pi;

    // 1. Cyan Aurora Orb (Top-Left drifting)
    final orb1Center = Offset(
      w * 0.22 + 60 * math.cos(t),
      h * 0.18 + 40 * math.sin(t),
    );
    final orb1Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryCyan.withValues(alpha: 0.16),
          AppColors.primaryCyan.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: orb1Center, radius: w * 0.42));
    canvas.drawCircle(orb1Center, w * 0.42, orb1Paint);

    // 2. Purple / Indigo Aurora Orb (Top-Right drifting)
    final orb2Center = Offset(
      w * 0.78 - 50 * math.sin(t * 1.1),
      h * 0.28 + 45 * math.cos(t * 0.9),
    );
    final orb2Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accentIndigo.withValues(alpha: 0.14),
          AppColors.accentIndigo.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: orb2Center, radius: w * 0.45));
    canvas.drawCircle(orb2Center, w * 0.45, orb2Paint);

    // 3. Emerald Green Aurora Orb (Center-Bottom drifting)
    final orb3Center = Offset(
      w * 0.50 + 40 * math.sin(t * 0.8),
      h * 0.65 - 35 * math.cos(t * 1.2),
    );
    final orb3Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryGreen.withValues(alpha: 0.12),
          AppColors.primaryGreen.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: orb3Center, radius: w * 0.38));
    canvas.drawCircle(orb3Center, w * 0.38, orb3Paint);

    // 4. Subtle Amber Glow Orb (Mid-Right drifting)
    final orb4Center = Offset(
      w * 0.85 + 30 * math.cos(t * 0.7),
      h * 0.75 + 30 * math.sin(t * 0.7),
    );
    final orb4Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accentAmber.withValues(alpha: 0.09),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: orb4Center, radius: w * 0.30));
    canvas.drawCircle(orb4Center, w * 0.30, orb4Paint);

    // 5. Floating Dust / Star Particles
    for (final p in particles) {
      final currentY = (p.y - progress * p.speed) % 1.0;
      final currentX = (p.x + 0.02 * math.sin(t * 2 + p.phase)) % 1.0;
      final offset = Offset(currentX * w, currentY * h);

      final particlePaint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity * (0.7 + 0.3 * math.sin(t * 3 + p.phase)));
      canvas.drawCircle(offset, p.radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
