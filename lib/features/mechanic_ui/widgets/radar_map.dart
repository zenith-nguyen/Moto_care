import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Bản đồ placeholder: vị trí thợ + vòng bán kính hoạt động + hiệu ứng radar lan tỏa.
/// (Muốn dùng bản đồ thật: thay CustomPaint bằng GoogleMap/FlutterMap, giữ lớp overlay.)
class RadarMap extends StatefulWidget {
  const RadarMap({
    super.key,
    required this.active,
    required this.radiusKm,
    required this.orders,
    this.height = 260,
  });

  final bool active; // true = đang nhận đơn -> radar chạy
  final double radiusKm;
  final List<OrderRequest> orders;
  final double height;

  @override
  State<RadarMap> createState() => _RadarMapState();
}

class _RadarMapState extends State<RadarMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _RadarPainter(
                  pulse: _pulse,
                  active: widget.active,
                  radiusKm: widget.radiusKm,
                  orders: widget.orders,
                ),
              ),
            ),
            // Marker vị trí thợ ở giữa bản đồ
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.active ? AppColors.ink : AppColors.disabled,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: AppShadows.soft,
                ),
                child: const Icon(
                  Icons.two_wheeler,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: _MapChip(
                icon: Icons.my_location,
                label: widget.active
                    ? 'Bán kính nhận đơn ${widget.radiusKm.toStringAsFixed(0)} km'
                    : 'Tạm nghỉ — không nhận đơn',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSub),
          const SizedBox(width: 6),
          Text(label, style: appText(12, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.pulse,
    required this.active,
    required this.radiusKm,
    required this.orders,
  }) : super(repaint: pulse);

  final Animation<double> pulse;
  final bool active;
  final double radiusKm;
  final List<OrderRequest> orders;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Nền bản đồ + khối xanh (công viên)
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEDEFF1),
    );
    final park = Paint()..color = const Color(0xFFDCE8DA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.70, h * 0.10, w * 0.24, h * 0.22),
        const Radius.circular(14),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.68, w * 0.22, h * 0.20),
        const Radius.circular(14),
      ),
      park,
    );

    // Đường phố
    final major = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final minor = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    for (final fx in const [0.12, 0.32, 0.5, 0.68, 0.88]) {
      canvas.drawLine(
        Offset(w * fx, 0),
        Offset(w * fx, h),
        fx == 0.5 ? major : minor,
      );
    }
    for (final fy in const [0.18, 0.4, 0.6, 0.82]) {
      canvas.drawLine(
        Offset(0, h * fy),
        Offset(w, h * fy),
        fy == 0.4 ? major : minor,
      );
    }
    canvas.drawLine(Offset(-10, h * 0.95), Offset(w + 10, h * 0.1), major);

    // Vòng bán kính hoạt động
    final center = Offset(w / 2, h / 2);
    final maxR = math.min(w, h) * 0.42;
    final tone = active ? AppColors.primary : AppColors.disabled;

    canvas.drawCircle(
      center,
      maxR,
      Paint()..color = tone.op(active ? 0.08 : 0.10),
    );
    canvas.drawCircle(
      center,
      maxR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = tone.op(0.6),
    );

    // Sóng radar lan tỏa
    if (active) {
      for (var i = 0; i < 3; i++) {
        final t = (pulse.value + i / 3) % 1.0;
        canvas.drawCircle(
          center,
          maxR * t,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = AppColors.primary.op((1 - t) * 0.45),
        );
      }
    }

    // Ghim các đơn khẩn cấp (khoảng cách tỉ lệ với bán kính)
    for (var i = 0; i < orders.length; i++) {
      final o = orders[i];
      final dist =
          (o.distanceKm / radiusKm).clamp(0.12, 0.95).toDouble() * maxR;
      final angle = -math.pi / 2 + (i + 1) * 2.1;
      final p = center + Offset(math.cos(angle), math.sin(angle)) * dist;
      canvas.drawCircle(p, 9, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        6,
        Paint()..color = active ? AppColors.primary : AppColors.disabled,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.active != active || old.radiusKm != radiusKm || old.orders != orders;
}
