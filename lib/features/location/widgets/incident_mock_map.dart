import 'package:flutter/material.dart';

import '../../home/theme/home_theme.dart';

/// A local, pannable map illustration. It makes no network or GPS requests.
class IncidentMockMap extends StatelessWidget {
  const IncidentMockMap({
    super.key,
    required this.offset,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final Offset offset;
  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback onPanEnd;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Bản đồ minh họa vị trí sự cố. Kéo bản đồ để đổi điểm ghim.',
    child: GestureDetector(
      key: const ValueKey('incident-map-canvas'),
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) => onPanUpdate(details.delta),
      onPanEnd: (_) => onPanEnd(),
      child: CustomPaint(
        painter: _IncidentMapPainter(offset: offset),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class IncidentSosPin extends StatelessWidget {
  const IncidentSosPin({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Ghim SOS cố định. Vị trí xe gặp sự cố.',
    child: SizedBox(
      key: const ValueKey('incident-sos-pin'),
      width: 72,
      height: 104,
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: HomeColors.primary,
              border: Border.all(color: HomeColors.surface, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
                Text(
                  'SOS',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 3, height: 18, color: HomeColors.primary),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: HomeColors.primary,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    ),
  );
}

class _IncidentMapPainter extends CustomPainter {
  const _IncidentMapPainter({required this.offset});
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE9ECEF),
    );
    canvas.save();
    canvas.translate(size.width / 2 + offset.dx, size.height * .3 + offset.dy);
    for (var row = -5; row < 6; row++) {
      for (var col = -5; col < 6; col++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(col * 96 + 8, row * 100 + 8, 78, 82),
            const Radius.circular(10),
          ),
          Paint()..color = const Color(0xFFF9FAFB),
        );
      }
    }
    final river = Path()
      ..moveTo(260, -700)
      ..cubicTo(140, -350, 330, -150, 190, 150)
      ..cubicTo(120, 340, 340, 490, 170, 780);
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFFA9DDE9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 44,
    );
    final roads = [
      const [Offset(-550, -220), Offset(-70, -240), Offset(500, -270)],
      const [Offset(-550, -50), Offset(-90, -65), Offset(270, -85)],
      const [Offset(-550, 170), Offset(-110, 160), Offset(270, 205)],
      const [Offset(-180, -700), Offset(-160, -70), Offset(-100, 600)],
      const [
        Offset(100, -700),
        Offset(85, -100),
        Offset(70, 230),
        Offset(130, 700),
      ],
      const [Offset(-60, -70), Offset(-50, 90), Offset(100, 70)],
      const [Offset(-150, 80), Offset(-260, 100), Offset(-280, 260)],
    ];
    for (final points in roads) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFD9DEE4)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 20,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 12,
      );
    }
    _label(canvas, 'Đường số 7', const Offset(-22, -266));
    _label(canvas, 'Bùi Văn Ba', const Offset(-135, -92));
    _label(canvas, 'Hẻm 118', const Offset(-260, 73));
    _label(canvas, 'Huỳnh Tấn Phát', const Offset(102, 122));
    _label(canvas, 'Rạch Đầu Ngựa', const Offset(130, 345));
    canvas.drawCircle(
      const Offset(0, 0),
      22,
      Paint()..color = HomeColors.primary.withValues(alpha: .12),
    );
    canvas.drawCircle(const Offset(0, 0), 8, Paint()..color = Colors.white);
    canvas.drawCircle(
      const Offset(0, 0),
      5,
      Paint()..color = HomeColors.primary,
    );
    canvas.restore();
  }

  void _label(Canvas canvas, String text, Offset position) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: Color(0xFF88939B),
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(_IncidentMapPainter oldDelegate) =>
      oldDelegate.offset != offset;
}
