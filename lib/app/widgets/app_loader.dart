import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../brand.dart';

/// A modern "astrographical" loader: a glowing core orbited by planets on
/// tilted rings. Used for the splash screen and in-app loading/saving states so
/// waiting always looks like one consistent, branded animation.
class AppLoader extends StatefulWidget {
  const AppLoader({super.key, this.size = 72});

  final double size;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _OrbitPainter(
            t: _c.value,
            core: scheme.primary,
            glow: scheme.tertiary,
            ring: scheme.primary.withValues(alpha: 0.25),
            planets: [scheme.primary, scheme.tertiary, scheme.secondary],
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required this.t,
    required this.core,
    required this.glow,
    required this.ring,
    required this.planets,
  });

  final double t; // 0..1 animation phase
  final Color core;
  final Color glow;
  final Color ring;
  final List<Color> planets;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final twoPi = 2 * math.pi;

    // Three tilted orbits, each spinning at a different rate/direction.
    final orbits = [
      (rx: r * 0.95, ry: r * 0.42, tilt: 0.0, speed: 1.0),
      (rx: r * 0.80, ry: r * 0.36, tilt: twoPi / 3, speed: -1.6),
      (rx: r * 0.62, ry: r * 0.28, tilt: -twoPi / 3, speed: 2.3),
    ];

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = ring;

    for (var i = 0; i < orbits.length; i++) {
      final o = orbits[i];
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(o.tilt);
      final rect = Rect.fromCenter(
          center: Offset.zero, width: o.rx * 2, height: o.ry * 2);
      canvas.drawOval(rect, ringPaint);

      // Planet position along the tilted ellipse.
      final angle = twoPi * t * o.speed + i * 1.7;
      final p = Offset(o.rx * math.cos(angle), o.ry * math.sin(angle));
      final planetPaint = Paint()..color = planets[i % planets.length];
      // Fade the planet as it passes "behind" the core (upper half).
      final depth = (math.sin(angle) + 1) / 2; // 0 back .. 1 front
      planetPaint.color =
          planets[i % planets.length].withValues(alpha: 0.45 + 0.55 * depth);
      canvas.drawCircle(p, 3.2 + 1.6 * depth, planetPaint);
      canvas.restore();
    }

    // Glowing pulsing core.
    final pulse = 0.85 + 0.15 * math.sin(twoPi * t * 2);
    canvas.drawCircle(
      center,
      r * 0.16 * pulse,
      Paint()
        ..color = glow.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(center, r * 0.11 * pulse, Paint()..color = core);
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.t != t;
}

/// Full-screen branded splash shown while the app boots and gates resolve.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoader(size: 96),
            const SizedBox(height: 28),
            Text(Brand.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(Brand.company,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
