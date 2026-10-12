import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bản đồ placeholder vẽ bằng CustomPainter (không cần API key).
/// Muốn dùng bản đồ thật: thay bằng google_maps_flutter / flutter_map, giữ các lớp UI nổi phía trên.

/// Nền bản đồ: khối phố, công viên, sông, đường chéo — vị trí theo tỉ lệ khung vẽ.
void _paintBaseMap(Canvas canvas, Size size) {
  final w = size.width;
  final h = size.height;
  canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.mapBase);

  final park = Paint()..color = AppColors.mapPark;
  for (final r in [
    Rect.fromLTWH(w * 0.08, h * 0.12, w * 0.26, h * 0.3),
    Rect.fromLTWH(w * 0.56, h * 0.18, w * 0.24, h * 0.36),
    Rect.fromLTWH(w * 0.02, h * 0.62, w * 0.22, h * 0.2),
  ]) {
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(14)), park);
  }

  // Sông ở đáy khung.
  final river = Path()
    ..moveTo(0, h * 0.9)
    ..quadraticBezierTo(w * 0.45, h * 0.78, w, h * 0.86)
    ..lineTo(w, h)
    ..lineTo(0, h)
    ..close();
  canvas.drawPath(river, Paint()..color = AppColors.mapWater);

  final major = Paint()
    ..color = Colors.white
    ..strokeWidth = 12
    ..strokeCap = StrokeCap.round;
  final minor = Paint()
    ..color = Colors.white
    ..strokeWidth = 7
    ..strokeCap = StrokeCap.round;
  for (final fx in const [0.1, 0.3, 0.5, 0.7, 0.9]) {
    canvas.drawLine(Offset(w * fx, 0), Offset(w * fx, h), fx == 0.5 ? major : minor);
  }
  for (final fy in const [0.16, 0.38, 0.6, 0.8]) {
    canvas.drawLine(Offset(0, h * fy), Offset(w, h * fy), fy == 0.38 ? major : minor);
  }
  canvas.drawLine(Offset(-10, h * 0.85), Offset(w + 10, h * 0.1), major);
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

/// Bản đồ trang chủ: vòng tròn đồng tâm bán kính nhận đơn quanh vị trí thợ.
class RadarMap extends StatefulWidget {
  const RadarMap({super.key, required this.active});

  /// Đang bật nhận đơn -> sóng radar chạy.
  final bool active;

  @override
  State<RadarMap> createState() => _RadarMapState();
}

class _RadarMapState extends State<RadarMap> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

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
    return CustomPaint(
      size: Size.infinite,
      painter: _RadarPainter(pulse: _pulse, active: widget.active),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.pulse, required this.active}) : super(repaint: pulse);

  final Animation<double> pulse;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBaseMap(canvas, size);
    final c = Offset(size.width / 2, size.height / 2);
    final base = math.min(size.width, size.height) / 2;
    final ringColor = active ? AppColors.success : AppColors.textMuted;

    for (final r in [base * 0.88, base * 0.62, base * 0.36]) {
      canvas.drawCircle(c, r, Paint()..color = AppColors.ink.withValues(alpha: 0.025));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFFB5B9BF),
      );
    }
    canvas.drawCircle(
      c,
      base * 0.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = ringColor,
    );
    if (active) {
      final t = pulse.value;
      canvas.drawCircle(
        c,
        base * 0.2 + base * 0.55 * t,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.success.withValues(alpha: (1 - t) * 0.5),
      );
    }
    canvas.drawCircle(c, 10, Paint()..color = Colors.white);
    canvas.drawCircle(c, 8, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.active != active;
}

/// Bản đồ tuyến đường thợ -> khách. [points] là toạ độ tỉ lệ (0..1) trong khung vẽ.
/// Điểm đầu là chấm đen, điểm cuối là ghim đỏ.
class RouteMap extends StatelessWidget {
  const RouteMap({super.key, required this.points, this.cornerRadius = 40});

  final List<Offset> points;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.infinite, painter: _RoutePainter(points, cornerRadius));
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.points, this.cornerRadius);

  final List<Offset> points;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBaseMap(canvas, size);
    final pts = [for (final p in points) Offset(p.dx * size.width, p.dy * size.height)];
    final path = _roundedPath(pts, cornerRadius);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.ink,
    );

    // Điểm đầu: chấm đen viền trắng.
    canvas.drawCircle(pts.first, 11, Paint()..color = Colors.white);
    canvas.drawCircle(pts.first, 8, Paint()..color = AppColors.ink);

    // Điểm cuối: ghim đỏ.
    final end = pts.last;
    canvas.drawOval(
      Rect.fromCenter(center: end.translate(0, 2), width: 22, height: 8),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    _paintIcon(canvas, end.translate(0, -22), Icons.location_on, 54, AppColors.danger);
    canvas.drawCircle(end.translate(0, -26), 6, Paint()..color = Colors.white);
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

/// Chip trắng nổi trên bản đồ: icon + chữ (vd. "1.2 km • 6 phút").
class MapChip extends StatelessWidget {
  const MapChip({super.key, required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: appText(13.5, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
