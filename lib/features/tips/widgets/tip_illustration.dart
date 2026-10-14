import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/service_scaffold.dart';
import '../models/emergency_tip.dart';

/// Local vector illustration: no network image loading or new asset package.
class TipIllustration extends StatelessWidget {
  const TipIllustration({super.key, required this.kind, this.step});
  final TipKind kind;
  final int? step;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: switch (kind) {
      TipKind.flood => 'Xe máy gặp đường ngập nước',
      TipKind.flatTire => 'Xe máy bị xẹp lốp',
      TipKind.battery => 'Bình ắc quy xe máy',
      TipKind.brakes => 'Xe máy giảm tốc bằng động cơ',
    },
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: CustomPaint(
        painter: _TipPainter(kind: kind),
        child: Stack(
          children: [
            const SizedBox.expand(),
            if (step != null)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: ServiceColors.orange,
                  foregroundColor: Colors.white,
                  child: Text('$step', style: const TextStyle(fontSize: 13)),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _TipPainter extends CustomPainter {
  _TipPainter({required this.kind});
  final TipKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ServiceColors.navy);
    canvas.save();
    canvas.scale(size.width / 200, size.height / 140);
    canvas.drawRect(
      const Rect.fromLTWH(0, 105, 200, 35),
      Paint()..color = const Color(0xFFE5E7EB),
    );
    final line = Paint()
      ..color = ServiceColors.orange
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final tire = Paint()
      ..color = const Color(0xFF707070)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(53, 92),
        width: 39,
        height: kind == TipKind.flatTire ? 25 : 39,
      ),
      tire,
    );
    canvas.drawCircle(const Offset(148, 92), 20, tire);
    final frame = Path()
      ..moveTo(53, 92)
      ..lineTo(80, 64)
      ..lineTo(115, 66)
      ..lineTo(94, 92)
      ..close()
      ..moveTo(115, 66)
      ..lineTo(148, 92)
      ..moveTo(115, 66)
      ..lineTo(125, 42)
      ..lineTo(142, 42);
    canvas.drawPath(frame, line);
    canvas.drawLine(
      const Offset(68, 59),
      const Offset(94, 59),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    switch (kind) {
      case TipKind.flood:
        final waves = Path()..moveTo(0, 112);
        for (var x = 0.0; x < 200; x += 20) {
          waves.quadraticBezierTo(x + 10, 101, x + 20, 112);
        }
        canvas.drawPath(
          waves,
          Paint()
            ..color = const Color(0xFF6AB7ED)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5,
        );
        for (var x = 20.0; x < 190; x += 35) {
          canvas.drawLine(
            Offset(x, 15),
            Offset(x - 5, 26),
            Paint()
              ..color = const Color(0xFF6AB7ED)
              ..strokeWidth = 2,
          );
        }
      case TipKind.flatTire:
        canvas.drawLine(
          const Offset(38, 107),
          const Offset(48, 92),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 3,
        );
        canvas.drawLine(
          const Offset(33, 106),
          const Offset(41, 110),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 3,
        );
      case TipKind.battery:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(15, 15, 45, 27),
            const Radius.circular(4),
          ),
          Paint()..color = const Color(0xFF69D49B),
        );
        canvas.drawRect(
          const Rect.fromLTWH(60, 23, 5, 10),
          Paint()..color = const Color(0xFF69D49B),
        );
        canvas.drawLine(
          const Offset(22, 28),
          const Offset(35, 28),
          Paint()
            ..color = const Color(0xFF151E2C)
            ..strokeWidth = 3,
        );
      case TipKind.brakes:
        for (var i = 0; i < 3; i++) {
          final x = 22.0 + i * 16;
          final arrow = Path()
            ..moveTo(x + 7, 18)
            ..lineTo(x, 26)
            ..lineTo(x + 7, 34);
          canvas.drawPath(
            arrow,
            Paint()
              ..color = ServiceColors.gold
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }
        canvas.drawArc(
          const Rect.fromLTWH(127, 71, 42, 42),
          0,
          math.pi * 1.6,
          false,
          Paint()
            ..color = ServiceColors.gold
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TipPainter oldDelegate) => oldDelegate.kind != kind;
}
