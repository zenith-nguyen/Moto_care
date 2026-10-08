import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bản đồ full-screen placeholder vẽ tuyến đường thợ -> khách.
/// [progress] (0..1) là vị trí thợ trên tuyến. Muốn dùng bản đồ thật thì thay widget này
/// bằng GoogleMap/FlutterMap, giữ nguyên các lớp UI nổi phía trên.
class RouteMap extends StatelessWidget {
  const RouteMap({
    super.key,
    required this.progress,
    this.topInset = 200,
    this.bottomInset = 360,
  });

  final Animation<double> progress;

  /// Vùng bị các card nổi che (trên: header + card khách, dưới: panel điều khiển).
  final double topInset;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _RouteMapPainter(
          progress: progress,
          topInset: topInset,
          bottomInset: bottomInset,
        ),
      ),
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  _RouteMapPainter({
    required this.progress,
    required this.topInset,
    required this.bottomInset,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final double topInset;
  final double bottomInset;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Nền + khối xanh
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEDEFF1),
    );
    final park = Paint()..color = const Color(0xFFDCE8DA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.62, h * 0.07, w * 0.30, h * 0.10),
        const Radius.circular(18),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-20, h * 0.60, w * 0.30, h * 0.12),
        const Radius.circular(18),
      ),
      park,
    );

    // Lưới đường
    final major = Paint()
      ..color = Colors.white
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    final minor = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    for (final fx in const [0.08, 0.3, 0.52, 0.74, 0.96]) {
      canvas.drawLine(
        Offset(w * fx, 0),
        Offset(w * fx, h),
        fx == 0.52 ? major : minor,
      );
    }
    for (final fy in const [0.12, 0.3, 0.46, 0.62, 0.8]) {
      canvas.drawLine(
        Offset(0, h * fy),
        Offset(w, h * fy),
        fy == 0.46 ? major : minor,
      );
    }
    canvas.drawLine(Offset(-20, h * 0.92), Offset(w + 20, h * 0.18), major);

    // Tuyến đường trong vùng nhìn thấy
    final area = Rect.fromLTRB(
      36,
      topInset,
      w - 36,
      math.max(topInset + 150, h - bottomInset),
    );
    final pts = <Offset>[
      Offset(area.left, area.bottom),
      Offset(area.left, area.top + area.height * 0.55),
      Offset(area.left + area.width * 0.5, area.top + area.height * 0.55),
      Offset(area.left + area.width * 0.5, area.top),
      Offset(area.right, area.top),
    ];
    final path = _roundedPath(pts, 28);
    final metric = path.computeMetrics().first;
    final total = metric.length;
    final t = progress.value.clamp(0.0, 1.0).toDouble();

    // Viền trắng + tuyến còn lại (đen) + đoạn đã đi (xám)
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.ink,
    );
    if (t > 0) {
      canvas.drawPath(
        metric.extractPath(0, total * t),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = AppColors.disabled,
      );
    }

    // Marker khách (điểm cuối) và thợ (theo progress)
    _paintMarker(canvas, pts.last, Icons.person_outline, AppColors.ink);
    final tangent = metric.getTangentForOffset(total * t);
    if (tangent != null) {
      _paintMarker(
        canvas,
        tangent.position,
        Icons.two_wheeler,
        AppColors.primary,
      );
    }
  }

  void _paintMarker(Canvas canvas, Offset p, IconData icon, Color color) {
    canvas.drawCircle(
      p.translate(0, 3),
      21,
      Paint()
        ..color = Colors.black.op(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(p, 21, Paint()..color = Colors.white);
    canvas.drawCircle(p, 17, Paint()..color = color);

    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 20,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
    )..layout();
    tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
  }

  /// Nối các điểm bằng đoạn thẳng, bo cong tại các góc.
  Path _roundedPath(List<Offset> pts, double radius) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length - 1; i++) {
      final prev = pts[i - 1];
      final cur = pts[i];
      final next = pts[i + 1];
      final d1 = (cur - prev).distance;
      final d2 = (next - cur).distance;
      final r = math.min(radius, math.min(d1, d2) / 2);
      final a = cur + (prev - cur) / d1 * r;
      final b = cur + (next - cur) / d2 * r;
      path.lineTo(a.dx, a.dy);
      path.quadraticBezierTo(cur.dx, cur.dy, b.dx, b.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter old) =>
      old.topInset != topInset || old.bottomInset != bottomInset;
}
