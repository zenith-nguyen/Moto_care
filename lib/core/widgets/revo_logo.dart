import 'package:flutter/material.dart';

import '../theme/revo_brand.dart';

class RevoLogo extends StatelessWidget {
  const RevoLogo({
    super.key,
    this.width = 150,
    this.color = RevoBrandColors.ink,
    this.eColor = RevoBrandColors.primary,
  });

  final double width;
  final Color color;
  final Color eColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo REVO',
      image: true,
      child: SizedBox(
        width: width,
        height: width * 32 / 132,
        child: CustomPaint(painter: _RevoWordmarkPainter(color, eColor)),
      ),
    );
  }
}

/// Canonical REVO wordmark shared by the Customer and Provider applications.
/// The three blue bars form the stylised letter "e" from the Provider design.
class _RevoWordmarkPainter extends CustomPainter {
  const _RevoWordmarkPainter(this.color, this.eColor);

  final Color color;
  final Color eColor;

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
      stroke,
    );

    final ePaint = Paint()..color = eColor;
    for (final y in [2.0, 13.5, 25.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(38, y, 23, 4.5),
          const Radius.circular(.6),
        ),
        ePaint,
      );
    }

    canvas.drawPath(
      Path()
        ..moveTo(72, 3)
        ..lineTo(84, 29)
        ..lineTo(96, 3),
      stroke,
    );
    canvas.drawOval(const Rect.fromLTWH(106, 4, 23, 24), stroke);
  }

  @override
  bool shouldRepaint(_RevoWordmarkPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.eColor != eColor;
}
