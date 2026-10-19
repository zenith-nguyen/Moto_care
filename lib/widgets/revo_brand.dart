import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'reference_image.dart';

class RevoLogo extends StatelessWidget {
  const RevoLogo(
      {super.key, this.size = 28, this.color = AppColors.ink, this.eColor});
  final double size;
  final Color color;
  final Color? eColor;
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'REVO',
        child: SizedBox(
            width: size * 4.2,
            height: size,
            child: CustomPaint(painter: _RevoWordmark(color, eColor ?? color))),
      );
}

class RevoCar extends StatelessWidget {
  const RevoCar({super.key, this.height = 200});
  final double height;
  @override
  Widget build(BuildContext context) => Semantics(
      label: 'Xe trắng trong thiết kế REVO',
      child: SizedBox(
          height: height,
          child: const ReferenceImage(
              asset: 'assets/images/reference_welcome.png',
              crop: Rect.fromLTWH(24, 366, 326, 184))));
}

/// Wordmark dựng bằng vector từ hình tham chiếu; không phải file logo gốc.
class _RevoWordmark extends CustomPainter {
  const _RevoWordmark(this.color, this.eColor);
  final Color color, eColor;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 132, size.height / 32);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
        Path()
          ..moveTo(3, 29)
          ..lineTo(3, 4)
          ..lineTo(18, 4)
          ..quadraticBezierTo(25, 4, 25, 11)
          ..quadraticBezierTo(25, 18, 18, 18)
          ..lineTo(3, 18)
          ..moveTo(15, 18)
          ..lineTo(27, 29),
        stroke);
    for (final y in [2.0, 13.5, 25.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(38, y, 23, 4.5), const Radius.circular(.6)),
          Paint()..color = eColor);
    }
    canvas.drawPath(
        Path()
          ..moveTo(72, 3)
          ..lineTo(84, 29)
          ..lineTo(96, 3),
        stroke);
    canvas.drawOval(const Rect.fromLTWH(106, 4, 23, 24), stroke);
  }

  @override
  bool shouldRepaint(_RevoWordmark oldDelegate) =>
      oldDelegate.color != color || oldDelegate.eColor != eColor;
}
