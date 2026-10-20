import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Small, code-native REVO symbols. Shared round caps and stroke, no bitmap,
/// dependency, gradient or color changes between read/unread notifications.
class NotificationGlyph extends StatelessWidget {
  const NotificationGlyph(
      {super.key,
      required this.type,
      this.size = 32,
      this.color = AppColors.primary});
  final RevoNotificationType type;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _NotificationGlyphPainter(type, color)),
      );
}

class _NotificationGlyphPainter extends CustomPainter {
  const _NotificationGlyphPainter(this.type, this.color);
  final RevoNotificationType type;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    final cut = Paint()..color = Colors.white;
    void line(double x, double y, double x2, double y2) =>
        canvas.drawLine(Offset(x, y), Offset(x2, y2), stroke);
    void document() {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(7, 5, 28, 36), const Radius.circular(3)),
          stroke);
      line(13, 13, 28, 13);
      line(13, 20, 25, 20);
      line(13, 27, 20, 27);
    }

    switch (type) {
      case RevoNotificationType.emergency:
        final cab = Path()
          ..moveTo(4, 27)
          ..lineTo(10, 18)
          ..lineTo(20, 18)
          ..lineTo(24, 27)
          ..lineTo(24, 36)
          ..lineTo(4, 36)
          ..close();
        canvas.drawPath(cab, stroke);
        canvas.drawPath(
            Path()
              ..moveTo(10, 26)
              ..lineTo(13, 21)
              ..lineTo(18, 21)
              ..lineTo(21, 26)
              ..close(),
            stroke);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(23, 27, 21, 9), const Radius.circular(1)),
            stroke);
        canvas.drawPath(
            Path()
              ..moveTo(26, 26)
              ..lineTo(35, 7)
              ..quadraticBezierTo(36, 5, 37, 8)
              ..lineTo(40, 16),
            stroke);
        line(29, 26, 36, 12);
        line(38, 14, 38, 23);
        canvas.drawPath(
            Path()
              ..moveTo(38, 23)
              ..quadraticBezierTo(44, 24, 40, 27),
            stroke);
        canvas.drawCircle(const Offset(11, 36), 5, cut);
        canvas.drawCircle(const Offset(11, 36), 5, stroke);
        canvas.drawCircle(const Offset(36, 36), 5, cut);
        canvas.drawCircle(const Offset(36, 36), 5, stroke);
        canvas.drawCircle(const Offset(11, 36), 1.5, fill);
        canvas.drawCircle(const Offset(36, 36), 1.5, fill);
        line(13, 15, 13, 13);
        line(5, 31, 8, 31);
      case RevoNotificationType.message:
        canvas.drawPath(
            Path()
              ..moveTo(19, 7)
              ..lineTo(30, 7)
              ..cubicTo(40, 7, 43, 13, 43, 23)
              ..cubicTo(43, 32, 38, 36, 29, 36)
              ..lineTo(18, 36)
              ..lineTo(9, 43)
              ..quadraticBezierTo(7, 44, 7, 40)
              ..lineTo(7, 21)
              ..cubicTo(7, 12, 11, 7, 19, 7)
              ..close(),
            stroke);
        for (final x in [18.0, 25.0, 32.0]) {
          canvas.drawCircle(Offset(x, 22), 1.8, fill);
        }
      case RevoNotificationType.quoteApproved:
      case RevoNotificationType.quoteRejected:
        document();
        canvas.drawCircle(const Offset(35, 33), 10, cut);
        canvas.drawCircle(const Offset(35, 33), 8.5, fill);
        final white = Paint()
          ..color = Colors.white
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(
            type == RevoNotificationType.quoteApproved
                ? (Path()
                  ..moveTo(31, 33)
                  ..lineTo(34, 36)
                  ..lineTo(39, 30))
                : (Path()
                  ..moveTo(32, 30)
                  ..lineTo(38, 36)
                  ..moveTo(38, 30)
                  ..lineTo(32, 36)),
            white);
      case RevoNotificationType.income:
      case RevoNotificationType.withdrawal:
        canvas.drawPath(
            Path()
              ..moveTo(8, 18)
              ..lineTo(31, 9)
              ..quadraticBezierTo(34, 8, 35, 12)
              ..lineTo(37, 20),
            stroke);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(6, 17, 36, 26), const Radius.circular(4)),
            fill);
        final white = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.3;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(29, 25, 15, 11), const Radius.circular(4)),
            white);
        canvas.drawCircle(const Offset(34, 30.5), 1.6, cut);
      case RevoNotificationType.certificate:
        document();
        canvas.drawPath(
            Path()
              ..moveTo(29, 33)
              ..lineTo(29, 45)
              ..lineTo(35, 41)
              ..lineTo(41, 45)
              ..lineTo(40, 33)
              ..close(),
            fill);
        canvas.drawCircle(const Offset(35, 31), 10, cut);
        canvas.drawCircle(const Offset(35, 31), 8.5, fill);
        canvas.drawPath(_star(const Offset(35, 31), 5, 3.2), cut);
      case RevoNotificationType.review:
        canvas.drawPath(_star(const Offset(24, 24), 20, 9.5), stroke);
      case RevoNotificationType.order:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(10, 8, 28, 35), const Radius.circular(3)),
            stroke);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(18, 4, 12, 8), const Radius.circular(2)),
            stroke);
        line(17, 20, 31, 20);
        line(17, 27, 31, 27);
        line(17, 34, 27, 34);
      case RevoNotificationType.system:
        canvas.drawPath(
            Path()
              ..moveTo(10, 34)
              ..lineTo(14, 29)
              ..lineTo(14, 20)
              ..cubicTo(14, 7, 34, 7, 34, 20)
              ..lineTo(34, 29)
              ..lineTo(38, 34)
              ..close(),
            stroke);
        canvas.drawArc(
            const Rect.fromLTWH(20, 34, 8, 8), 0, math.pi, false, stroke);
        line(24, 7, 24, 4);
    }
    canvas.restore();
  }

  Path _star(Offset center, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? outer : inner;
      final p = Offset(center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _NotificationGlyphPainter old) =>
      old.type != type || old.color != color;
}
