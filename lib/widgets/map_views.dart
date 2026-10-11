import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bản đồ placeholder vẽ bằng CustomPainter (không cần API key).
/// Muốn dùng bản đồ thật: thay bằng google_maps_flutter / flutter_map, giữ các lớp UI nổi.

void _paintGrid(Canvas canvas, Size size, {double cell = 76, double road = 14}) {
  canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
  final block = Paint()..color = AppColors.mapBlock;
  for (double y = road / 2; y < size.height; y += cell) {
    for (double x = road / 2; x < size.width; x += cell) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cell - road, cell - road),
          const Radius.circular(4),
        ),
        block,
      );
    }
  }
}

void _paintIcon(Canvas canvas, Offset center, IconData icon, double size, Color color) {
  final tp = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    ),
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

/// Bản đồ trang chủ: lưới ô vuông + vòng tròn đồng tâm radar quanh vị trí thợ.
class RadarMap extends StatefulWidget {
  const RadarMap({super.key, required this.active});

  /// Đang bật nhận đơn -> sóng radar chạy.
  final bool active;

  @override
  State<RadarMap> createState() => _RadarMapState();
}

class _RadarMapState extends State<RadarMap> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  @override
  void initState() {
    super.initState();
    if (widget.active) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant RadarMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_pulse.isAnimating) _pulse.repeat();
    if (!widget.active && _pulse.isAnimating) _pulse.stop();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _RadarPainter(pulse: _pulse, active: widget.active)),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: widget.active ? AppColors.ink : AppColors.textMuted,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 5),
            ),
            child: const Icon(Icons.two_wheeler, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.pulse, required this.active}) : super(repaint: pulse);

  final Animation<double> pulse;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);
    final c = Offset(size.width / 2, size.height / 2);
    final rings = [52.0, 92.0, 132.0];
    for (final r in rings.reversed) {
      canvas.drawCircle(c, r, Paint()..color = AppColors.ink.withValues(alpha: 0.035));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFFCDD0D5),
      );
    }
    if (active) {
      final t = pulse.value;
      canvas.drawCircle(
        c,
        40 + (rings.last - 40) * t,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = AppColors.ink.withValues(alpha: (1 - t) * 0.35),
      );
    }
    // Các điểm khách lân cận trên vòng radar.
    for (final (r, a) in [(132.0, -0.9), (92.0, 2.9), (132.0, 0.55)]) {
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawCircle(p, 12, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        12,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..color = active ? AppColors.ink : AppColors.textMuted,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.active != active;
}

/// Bản đồ tuyến đường thợ -> khách. [points] là toạ độ tỉ lệ (0..1) trong vùng vẽ.
class RouteMap extends StatelessWidget {
  const RouteMap({
    super.key,
    required this.points,
    this.cornerRadius = 36,
    this.cell = 76,
    this.road = 14,
    this.markerAtEnd = true,
  });

  final List<Offset> points;
  final double cornerRadius;
  final double cell;
  final double road;

  /// true: icon xe ở cuối tuyến (popup offer). false: icon xe ở giữa tuyến (đang di chuyển).
  final bool markerAtEnd;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _RoutePainter(points, cornerRadius, cell, road, markerAtEnd),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.points, this.cornerRadius, this.cell, this.road, this.markerAtEnd);

  final List<Offset> points;
  final double cornerRadius;
  final double cell;
  final double road;
  final bool markerAtEnd;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size, cell: cell, road: road);
    final pts = [for (final p in points) Offset(p.dx * size.width, p.dy * size.height)];
    final path = _roundedPath(pts, cornerRadius);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFDADDE1),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.ink,
    );

    // Điểm đầu tuyến.
    canvas.drawCircle(pts.first, 11, Paint()..color = AppColors.ink);

    final metric = path.computeMetrics().first;
    final pos = markerAtEnd ? pts.last : metric.getTangentForOffset(metric.length * 0.45)!.position;
    canvas.drawCircle(pos, 22, Paint()..color = Colors.white);
    canvas.drawCircle(
      pos,
      22,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.ink,
    );
    _paintIcon(canvas, pos, Icons.two_wheeler, 24, AppColors.ink);
  }

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
      path
        ..lineTo(a.dx, a.dy)
        ..quadraticBezierTo(cur.dx, cur.dy, b.dx, b.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => old.points != points;
}
