import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Zero-based Wallet income chart. Null dates have no recorded data yet.
class IncomeLineChart extends StatefulWidget {
  const IncomeLineChart({
    super.key,
    required this.values,
    required this.dates,
    this.height = 205,
  }) : assert(values.length == dates.length);

  final List<int?> values;
  final List<DateTime> dates;
  final double height;

  @override
  State<IncomeLineChart> createState() => _IncomeLineChartState();
}

class _IncomeLineChartState extends State<IncomeLineChart> {
  int? _selection;
  int? get selected {
    if (_selection != null &&
        _selection! < widget.values.length &&
        widget.values[_selection!] != null) {
      return _selection;
    }
    int? best;
    for (var i = 0; i < widget.values.length; i++) {
      if (widget.values[i] != null &&
          (best == null || widget.values[i]! > widget.values[best]!)) {
        best = i;
      }
    }
    return best;
  }

  @override
  void didUpdateWidget(covariant IncomeLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.dates, widget.dates)) _selection = null;
  }

  @override
  Widget build(BuildContext context) {
    final index = selected;
    if (index == null) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text('Chưa có dữ liệu trong kỳ',
              style: appText(12, color: AppColors.textSub)),
        ),
      );
    }
    final description =
        '${formatDM(widget.dates[index])} · ${formatVnd(widget.values[index]!)}';
    return Semantics(
      label: 'Biểu đồ thu nhập sau phí. $description. Chạm điểm để xem ngày.',
      child: LayoutBuilder(builder: (context, box) {
        final plotWidth = math.max(1.0, box.maxWidth - 50);
        void select(double dx) {
          final i = ((dx - 38) / plotWidth * (widget.values.length - 1))
              .round()
              .clamp(0, widget.values.length - 1);
          if (widget.values[i] != null) setState(() => _selection = i);
        }

        final pointX = 38 +
            (widget.values.length == 1
                ? plotWidth / 2
                : plotWidth * index / (widget.values.length - 1));
        return GestureDetector(
          key: const ValueKey('weekly-income-chart'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => select(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => select(d.localPosition.dx),
          child: SizedBox(
            height: widget.height,
            child: Stack(children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _IncomePainter(
                    values: widget.values,
                    dates: widget.dates,
                    selected: index,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left:
                    (pointX - 66).clamp(0.0, math.max(0.0, box.maxWidth - 132)),
                width: 132,
                child: ExcludeSemantics(
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(description,
                          style: appText(10,
                              color: Colors.white, weight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        );
      }),
    );
  }
}

class _IncomePainter extends CustomPainter {
  const _IncomePainter({
    required this.values,
    required this.dates,
    required this.selected,
  });
  final List<int?> values;
  final List<DateTime> dates;
  final int selected;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const left = 38.0, top = 43.0, bottom = 26.0, right = 12.0;
    final width = size.width - left - right;
    final height = size.height - top - bottom;
    final largest = values.whereType<int>().fold<int>(0, math.max);
    final rawStep = math.max(1000.0, largest / 3);
    final power =
        math.pow(10, (math.log(rawStep) / math.ln10).floor()).toDouble();
    final step = [1, 2, 5, 10].firstWhere((v) => v * power >= rawStep) * power;
    final ceiling = step * 3;
    final grid = Paint()..color = AppColors.border;
    void label(String text, Offset at, {bool rightAlign = false}) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: appText(9, color: AppColors.textSub)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      painter.paint(
          canvas, Offset(at.dx - (rightAlign ? painter.width : 0), at.dy));
    }

    String money(double value) => value == 0
        ? '0'
        : value >= 1000000
            ? '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M'
            : '${(value / 1000).round()}K';
    for (var i = 0; i <= 3; i++) {
      final y = top + height * i / 3;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), grid);
      label(money(ceiling * (3 - i) / 3), Offset(left - 7, y - 6),
          rightAlign: true);
    }
    Offset point(int i) => Offset(
          left +
              (values.length == 1
                  ? width / 2
                  : width * i / (values.length - 1)),
          top + height * (1 - (values[i] ?? 0) / ceiling),
        );
    final stride = values.length <= 7 ? 1 : (values.length / 6).ceil();
    for (var i = 0; i < values.length; i++) {
      if (i % stride != 0 && i != values.length - 1) continue;
      final x = point(i).dx;
      canvas.drawLine(Offset(x, top), Offset(x, top + height + 5), grid);
      final painter = TextPainter(
        text: TextSpan(
            text: formatDM(dates[i]),
            style: appText(9, color: AppColors.textSub)),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
          canvas,
          Offset((x - painter.width / 2).clamp(0, size.width - painter.width),
              size.height - 16));
    }
    final points = [
      for (var i = 0; i < values.length; i++)
        if (values[i] != null) point(i)
    ];
    if (points.isEmpty) return;
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    // Shape-preserving cubic interpolation: no overshoot below zero or over
    // the adjacent values; each point remains the actual ledger bucket.
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      final middle = (a.dx + b.dx) / 2;
      line.cubicTo(middle, a.dy, middle, b.dy, b.dx, b.dy);
    }
    final area = Path.from(line)
      ..lineTo(points.last.dx, top + height)
      ..lineTo(points.first.dx, top + height)
      ..close();
    canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: .16),
              AppColors.primary.withValues(alpha: .015)
            ],
          ).createShader(Rect.fromLTWH(left, top, width, height)));
    final selectedPoint = point(selected);
    final dash = Paint()
      ..color = AppColors.primary.withValues(alpha: .6)
      ..strokeWidth = 1;
    for (var y = top; y < top + height; y += 7) {
      canvas.drawLine(Offset(selectedPoint.dx, y),
          Offset(selectedPoint.dx, math.min(y + 4, top + height)), dash);
    }
    canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = AppColors.primary);
    for (var i = 0; i < values.length; i++) {
      if (values[i] == null) continue;
      canvas.drawCircle(
          point(i),
          i == selected ? 5 : (values.length > 7 ? 2.5 : 4),
          Paint()..color = Colors.white);
      canvas.drawCircle(
          point(i),
          i == selected ? 3.8 : (values.length > 7 ? 1.8 : 3),
          Paint()..color = AppColors.primary);
    }
  }

  @override
  bool shouldRepaint(covariant _IncomePainter old) =>
      !listEquals(old.values, values) ||
      !listEquals(old.dates, dates) ||
      old.selected != selected;
}
