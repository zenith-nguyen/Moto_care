import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/home_weather.dart';

/// Gradient and shadow layers keep the weather illustration crisp at any size.
class WeatherConditionIcon extends StatelessWidget {
  const WeatherConditionIcon({
    super.key,
    required this.condition,
    this.isNight = false,
    this.size = 72,
  });

  final HomeWeatherCondition condition;

  /// When true, the sun illustration is replaced by a crescent moon so a clear
  /// night does not show a daytime sun.
  final bool isNight;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _WeatherPainter(condition, isNight),
    ),
  );
}

class _WeatherPainter extends CustomPainter {
  const _WeatherPainter(this.condition, this.isNight);
  final HomeWeatherCondition condition;
  final bool isNight;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 96, size.height / 96);
    final wet =
        condition == HomeWeatherCondition.rainy ||
        condition == HomeWeatherCondition.stormy;
    if (condition == HomeWeatherCondition.sunny ||
        condition == HomeWeatherCondition.partlyCloudy) {
      const center = Offset(64, 30);
      if (isNight) {
        _paintMoon(canvas, center);
      } else {
        final ray = Paint()
          ..color = const Color(0xFFFFC85C)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 10; i++) {
          final angle = i * math.pi / 5;
          final direction = Offset(math.cos(angle), math.sin(angle));
          canvas.drawLine(
            center + direction * 22,
            center + direction * 27,
            ray,
          );
        }
        final sun = Path()
          ..addOval(Rect.fromCircle(center: center, radius: 18));
        canvas.drawShadow(sun, const Color(0xFFDE9B31), 4, false);
        canvas.drawPath(
          sun,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-.5, -.6),
              colors: [Color(0xFFFFF4B8), Color(0xFFFFD45F), Color(0xFFFFAE40)],
            ).createShader(const Rect.fromLTWH(46, 12, 36, 36)),
        );
        canvas.drawOval(
          const Rect.fromLTWH(52, 16, 12, 6),
          Paint()..color = Colors.white.withValues(alpha: .55),
        );
      }
    }
    if (condition == HomeWeatherCondition.sunny) return;
    final base = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(14, 47, 67, 24),
          const Radius.circular(12),
        ),
      );
    var cloud = base;
    for (final circle in [
      const Rect.fromLTWH(21, 36, 29, 29),
      const Rect.fromLTWH(37, 27, 36, 36),
      const Rect.fromLTWH(59, 42, 26, 26),
    ]) {
      cloud = Path.combine(PathOperation.union, cloud, Path()..addOval(circle));
    }
    canvas.drawShadow(
      cloud,
      const Color(0xFF597B93).withValues(alpha: .4),
      6,
      false,
    );
    canvas.drawPath(
      cloud,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: wet
              ? const [Color(0xFFF5FAFF), Color(0xFFBCD0E0), Color(0xFF8DAEC8)]
              : const [Colors.white, Color(0xFFF7FBFF), Color(0xFFD3E3F0)],
        ).createShader(const Rect.fromLTWH(14, 27, 71, 44)),
    );
    canvas.drawPath(
      cloud,
      Paint()
        ..color = Colors.white.withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    if (wet) {
      final drops = Paint()
        ..color = const Color(0xFF659EC6)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      for (final x in [29.0, 48.0, 67.0]) {
        canvas.drawLine(Offset(x, 79), Offset(x - 3, 86), drops);
      }
    }
  }

  void _paintMoon(Canvas canvas, Offset center) {
    // Crescent = full disc minus an offset disc.
    final full = Path()..addOval(Rect.fromCircle(center: center, radius: 18));
    final bite = Path()
      ..addOval(Rect.fromCircle(center: center.translate(9, -5), radius: 16));
    final crescent = Path.combine(PathOperation.difference, full, bite);
    canvas.drawShadow(crescent, const Color(0xFF3B5BA5), 4, false);
    canvas.drawPath(
      crescent,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.4, -.5),
          colors: [Color(0xFFFFF6D6), Color(0xFFFFE9A8), Color(0xFFF6CE73)],
        ).createShader(const Rect.fromLTWH(46, 12, 36, 36)),
    );
    final star = Paint()..color = const Color(0xFFFFF1C2);
    for (final spot in [
      const Offset(44, 18),
      const Offset(50, 42),
      const Offset(78, 36),
    ]) {
      canvas.drawCircle(spot, 1.8, star);
    }
  }

  @override
  bool shouldRepaint(_WeatherPainter oldDelegate) =>
      oldDelegate.condition != condition || oldDelegate.isNight != isNight;
}
