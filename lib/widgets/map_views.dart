import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bản đồ placeholder vẽ bằng CustomPainter (không cần API key).
/// Muốn dùng bản đồ thật: thay bằng google_maps_flutter / flutter_map, giữ các lớp UI nổi phía trên.

/// Nền bản đồ: khối phố, công viên, sông, đường chéo — vị trí theo tỉ lệ khung vẽ.
void _paintBaseMap(Canvas canvas, Size size) {
  final w = size.width;
  final h = size.height;
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF0F3F7));
  const xs = [.0, .08, .18, .27, .37, .47, .60, .72, .86, .96, 1.0];
  const ys = [.0, .1, .2, .33, .46, .60, .73, .86, .96, 1.0];
  for (var x = 0; x < xs.length - 1; x++) {
    for (var y = 0; y < ys.length - 1; y++) {
      final block = Rect.fromLTRB(
          xs[x] * w + 5, ys[y] * h + 5, xs[x + 1] * w - 5, ys[y + 1] * h - 5);
      if (block.width <= 0 || block.height <= 0) continue;
      canvas.drawRRect(
          RRect.fromRectAndRadius(block, const Radius.circular(4)),
          Paint()
            ..color = (x + y) % 5 == 0
                ? const Color(0xFFDCEBDD)
                : const Color(0xFFE4E9EF));
      if (block.width > 25 && block.height > 35) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(block.deflate(5), const Radius.circular(2)),
            Paint()..color = Colors.white.withValues(alpha: .38));
      }
    }
  }
  final water = Path()
    ..moveTo(w * .92, 0)
    ..cubicTo(w * .76, h * .28, w * 1.05, h * .44, w * .86, h * .67)
    ..cubicTo(w * .72, h * .85, w * .99, h * .94, w * .86, h)
    ..lineTo(w, h)
    ..lineTo(w, 0)
    ..close();
  canvas.drawPath(water, Paint()..color = const Color(0xFFB7DEF2));
  for (final x in xs.skip(1).take(xs.length - 2)) {
    final a = Offset(x * w, 0);
    final b = Offset(x * w, h);
    canvas.drawLine(
        a,
        b,
        Paint()
          ..color = const Color(0xFFDAE0E9)
          ..strokeWidth = (x == .27 || x == .72) ? 14 : 7);
    canvas.drawLine(
        a,
        b,
        Paint()
          ..color = Colors.white
          ..strokeWidth = (x == .27 || x == .72) ? 11 : 5);
  }
  for (final y in ys.skip(1).take(ys.length - 2)) {
    final a = Offset(0, y * h);
    final b = Offset(w, y * h);
    canvas.drawLine(
        a,
        b,
        Paint()
          ..color = const Color(0xFFDAE0E9)
          ..strokeWidth = (y == .33 || y == .46) ? 14 : 7);
    canvas.drawLine(
        a,
        b,
        Paint()
          ..color = Colors.white
          ..strokeWidth = (y == .33 || y == .46) ? 11 : 5);
  }
  void label(String text, double x, double y,
      {double fontSize = 9, Color color = const Color(0xFF53677B)}) {
    final p = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
            text: text,
            style: appText(fontSize, color: color, weight: FontWeight.w500)))
      ..layout(maxWidth: w * .75);
    final position = Offset(x * w, y * h);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            (position & p.size).inflate(3), const Radius.circular(3)),
        Paint()..color = Colors.white.withValues(alpha: .75));
    p.paint(canvas, position);
  }

  label('QUẬN 1', .07, .26, fontSize: 15, color: AppColors.primaryDeep);
  label('Nguyễn Thị Minh Khai', .32, .20);
  label('Hai Bà Trưng', .50, .52);
  label('Lê Duẩn', .12, .73);
  label('Công viên 30/4', .06, .39, fontSize: 10, color: AppColors.successDark);
  label('Bản đồ minh hoạ', .05, .93, fontSize: 9);
}

void _paintIcon(
  Canvas canvas,
  Offset center,
  IconData icon,
  double size,
  Color color,
) {
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

class _RadarMapState extends State<RadarMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

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
  _RadarPainter({required this.pulse, required this.active})
      : super(repaint: pulse);

  final Animation<double> pulse;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBaseMap(canvas, size);
    final c = Offset(size.width / 2, size.height / 2);
    final base = math.min(size.width, size.height) / 2;
    final ringColor = active ? AppColors.success : AppColors.textMuted;

    for (final r in [base * 0.88, base * 0.62, base * 0.36]) {
      canvas.drawCircle(
        c,
        r,
        Paint()..color = AppColors.ink.withValues(alpha: 0.025),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = AppColors.border,
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
    canvas.drawCircle(c, 8, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.active != active;
}

/// Bản đồ tuyến đường thợ -> khách. [points] là toạ độ tỉ lệ (0..1) trong khung vẽ.
/// Điểm đầu là vị trí thợ, điểm cuối là ghim khách hàng màu xanh.
class RouteMap extends StatelessWidget {
  const RouteMap({super.key, required this.points, this.cornerRadius = 40});

  final List<Offset> points;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
        label:
            'Bản đồ mô phỏng: vị trí thợ, tuyến đường màu xanh và vị trí khách',
        child: CustomPaint(
            size: Size.infinite, painter: _RoutePainter(points, cornerRadius)));
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.points, this.cornerRadius);

  final List<Offset> points;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBaseMap(canvas, size);
    final pts = [
      for (final p in points) Offset(p.dx * size.width, p.dy * size.height),
    ];
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
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.primary,
    );

    void markerLabel(String text, Offset point) {
      final tp = TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(
              text: text,
              style: appText(10,
                  color: AppColors.primaryDeep, weight: FontWeight.w700)))
        ..layout();
      final pos = point + Offset(-tp.width / 2, 24);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              (pos & tp.size).inflate(5), const Radius.circular(6)),
          Paint()..color = Colors.white);
      tp.paint(canvas, pos);
    }

    markerLabel('Vị trí thợ', pts.first);
    markerLabel('Khách hàng', pts.last);
    // Vị trí thợ: chấm xanh viền trắng.
    canvas.drawCircle(pts.first, 19, Paint()..color = Colors.white);
    canvas.drawCircle(pts.first, 16, Paint()..color = AppColors.primary);
    _paintIcon(canvas, pts.first, Icons.navigation_rounded, 23, Colors.white);

    // Vị trí khách hàng: ghim xanh.
    final end = pts.last;
    canvas.drawOval(
      Rect.fromCenter(center: end.translate(0, 2), width: 22, height: 8),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    _paintIcon(
      canvas,
      end.translate(0, -22),
      Icons.location_on,
      54,
      AppColors.primary,
    );
    _paintIcon(
      canvas,
      end.translate(0, -26),
      Icons.person_outline_rounded,
      17,
      Colors.white,
    );
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
