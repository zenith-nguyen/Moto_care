import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Biểu đồ đường thu nhập 7 ngày (T2..CN) có vùng tô nhạt, điểm cao nhất nổi bật + nhãn thứ.
/// Vẽ bằng CustomPainter, không cần thư viện chart.
class IncomeLineChart extends StatelessWidget {
  const IncomeLineChart({
    super.key,
    required this.values,
    this.lineColor = AppColors.ink,
    this.areaColor = const Color(0xFFF0F0F1),
    this.highlightColor = AppColors.danger,
    this.height = 96,
  });

  final List<int> values;
  final Color lineColor;
  final Color areaColor;
  final Color highlightColor;
  final double height;

  int get _peak {
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[best]) best = i;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final peak = _peak;
    return Semantics(
      label:
          'Biểu đồ thu nhập 7 ngày, cao nhất ${formatVnd(values[peak])} vào ${weekdayLabelAt(peak)}',
      child: Column(
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _ChartPainter(
                values: values,
                peak: peak,
                lineColor: lineColor,
                areaColor: areaColor,
                highlightColor: highlightColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: Text(
                    weekdayLabelAt(i),
                    textAlign: TextAlign.center,
                    style: appText(
                      13,
                      weight: i == peak ? FontWeight.w700 : FontWeight.w500,
                      color: i == peak ? highlightColor : AppColors.textSub,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.values,
    required this.peak,
    required this.lineColor,
    required this.areaColor,
    required this.highlightColor,
  });

  final List<int> values;
  final int peak;
  final Color lineColor;
  final Color areaColor;
  final Color highlightColor;

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n < 2) return;
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final span = (hi - lo) == 0 ? 1 : (hi - lo);

    final colW = size.width / n;
    Offset point(int i) {
      final t = (values[i] - lo) / span; // 0..1
      final y = size.height - (0.1 + 0.8 * t) * size.height;
      return Offset(colW * i + colW / 2, y);
    }

    final pts = [for (var i = 0; i < n; i++) point(i)];

    final area = Path()..moveTo(pts.first.dx, size.height);
    for (final p in pts) {
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(pts.last.dx, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = areaColor);

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = lineColor,
    );

    for (var i = 0; i < n; i++) {
      final hot = i == peak;
      canvas.drawCircle(pts[i], hot ? 6 : 4, Paint()..color = hot ? highlightColor : lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.values != values || old.peak != peak || old.lineColor != lineColor;
}
