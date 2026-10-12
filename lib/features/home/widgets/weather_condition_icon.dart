import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/home_weather.dart';

/// Gradient and shadow layers keep the weather illustration crisp at any size.
class WeatherConditionIcon extends StatelessWidget {
  const WeatherConditionIcon({
    super.key,
    required this.condition,
    this.size = 72,
  });

  final HomeWeatherCondition condition;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _WeatherPainter(condition),
    ),
  );
}

class _WeatherPainter extends CustomPainter {
  const _WeatherPainter(this.condition);
  final HomeWeatherCondition condition;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 96, size.height / 96);
    final wet =
        condition == HomeWeatherCondition.rainy ||
        condition == HomeWeatherCondition.stormy;
    if (condition == HomeWeatherCondition.sunny ||
        condition == HomeWeatherCondition.partlyCloudy) {
      const center = Offset(64, 30);
      final ray = Paint()
        ..color = const Color(0xFFFFC85C)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 10; i++) {
        final angle = i * math.pi / 5;
        final direction = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(center + direction * 22, center + direction * 27, ray);
      }
      final sun = Path()..addOval(Rect.fromCircle(center: center, radius: 18));
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

  @override
  bool shouldRepaint(_WeatherPainter oldDelegate) =>
      oldDelegate.condition != condition;
}
