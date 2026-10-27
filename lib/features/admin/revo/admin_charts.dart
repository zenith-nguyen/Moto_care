import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'admin_dashboard_highlights.dart';
import 'revo_admin_style.dart';

/// Period toggle (7 ngày / 30 ngày) used on the trend and revenue cards.
class AdminChartPeriodTabs extends StatelessWidget {
  const AdminChartPeriodTabs({
    super.key,
    required this.period,
    required this.onChanged,
  });

  final String period;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFEDF4FB),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Wrap(
        spacing: 4,
        children: [
          for (final value in ['7 ngày', '30 ngày'])
            TextButton(
              key: ValueKey('admin-chart-period-$value'),
              onPressed: () => onChanged(value),
              style: TextButton.styleFrom(
                minimumSize: const Size(70, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                backgroundColor: period == value
                    ? const Color(0xFF111111)
                    : Colors.transparent,
                foregroundColor: period == value
                    ? Colors.white
                    : AdminChartStyle.muted,
                shape: const StadiumBorder(),
                textStyle: revoFont(fontSize: 11, fontWeight: FontWeight.w500),
              ),
              child: Text(value),
            ),
        ],
      ),
    ),
  );
}

/// Cumulative rescue activity with the preceding equal-length period in gray.
class AdminSosTrendChart extends StatelessWidget {
  const AdminSosTrendChart({
    super.key,
    required this.points,
    required this.previousPoints,
    this.compact = false,
  });

  final List<RevoTimeseriesPoint> points;
  final List<RevoTimeseriesPoint> previousPoints;
  final bool compact;

  List<double> _cumulative(List<RevoTimeseriesPoint> source) {
    var total = 0;
    return [for (final point in source) (total += point.orders).toDouble()];
  }

  @override
  Widget build(BuildContext context) => _RevoLineChart(
    points: points,
    values: _cumulative(points),
    previousValues: _cumulative(previousPoints),
    compact: compact,
    money: false,
  );
}

/// Daily revenue uses the same blue area chart as the rescue trend.
class AdminRevenueChart extends StatelessWidget {
  const AdminRevenueChart({
    super.key,
    required this.points,
    this.compact = false,
  });

  final List<RevoTimeseriesPoint> points;
  final bool compact;

  @override
  Widget build(BuildContext context) => _RevoLineChart(
    points: points,
    values: [for (final point in points) point.collected.toDouble()],
    compact: compact,
    money: true,
  );
}

class _RevoLineChart extends StatefulWidget {
  const _RevoLineChart({
    required this.points,
    required this.values,
    required this.money,
    required this.compact,
    this.previousValues = const [],
  });

  final List<RevoTimeseriesPoint> points;
  final List<double> values;
  final List<double> previousValues;
  final bool money;
  final bool compact;

  @override
  State<_RevoLineChart> createState() => _RevoLineChartState();
}

class _RevoLineChartState extends State<_RevoLineChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant _RevoLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) _selectedIndex = null;
  }

  String _pill(double value) =>
      widget.money ? revoMoney(value.round()) : '${value.round()} ca lũy kế';

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return SizedBox(
        height: widget.compact ? 150 : 200,
        child: Center(
          child: Text(
            'Chưa có dữ liệu trong kỳ.',
            style: revoFont(fontSize: 12, color: AdminChartStyle.muted),
          ),
        ),
      );
    }
    final count = widget.points.length;
    final index = (_selectedIndex ?? count - 1).clamp(0, count - 1);
    final maximum = [
      ...widget.values,
      ...widget.previousValues,
      1.0,
    ].reduce(math.max);
    final rawInterval = math.max(1.0, maximum / 3);
    final magnitude = math
        .pow(10, (math.log(rawInterval) / math.ln10).floor())
        .toDouble();
    final interval = [1, 2, 5, 10]
        .map((step) => step * magnitude)
        .firstWhere((step) => step >= rawInterval, orElse: () => magnitude);
    final maxY = math.max(interval, (maximum / interval).ceil() * interval);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            key: const ValueKey('admin-chart-selection'),
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AdminChartStyle.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${DateFormat('dd/MM').format(widget.points[index].day)} · '
              '${_pill(widget.values[index])}',
              style: revoFont(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ),
        SizedBox(
          height: widget.compact ? 150 : 210,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) =>
                  _select(d.localPosition.dx, constraints.maxWidth),
              onHorizontalDragUpdate: (d) =>
                  _select(d.localPosition.dx, constraints.maxWidth),
              child: CustomPaint(
                size: Size(constraints.maxWidth, widget.compact ? 150 : 210),
                painter: _LineChartPainter(
                  points: widget.points,
                  values: widget.values,
                  previousValues: widget.previousValues,
                  maxY: maxY,
                  interval: interval,
                  selectedIndex: index,
                  money: widget.money,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _select(double dx, double width) {
    const leftPad = 44.0;
    final count = widget.points.length;
    if (count <= 1) {
      setState(() => _selectedIndex = 0);
      return;
    }
    final plotWidth = math.max(1.0, width - leftPad - 8);
    final ratio = ((dx - leftPad) / plotWidth).clamp(0.0, 1.0);
    setState(() => _selectedIndex = (ratio * (count - 1)).round());
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.points,
    required this.values,
    required this.previousValues,
    required this.maxY,
    required this.interval,
    required this.selectedIndex,
    required this.money,
  });

  final List<RevoTimeseriesPoint> points;
  final List<double> values;
  final List<double> previousValues;
  final double maxY;
  final double interval;
  final int selectedIndex;
  final bool money;

  static const _leftPad = 44.0;
  static const _bottomPad = 26.0;
  static const _rightPad = 8.0;
  static const _topPad = 6.0;

  String _axisLabel(double value) {
    if (!money || value < 1000) return '${value.round()}';
    if (value >= 1000000) {
      return '${NumberFormat('0.#', 'vi_VN').format(value / 1000000)}tr';
    }
    return '${NumberFormat('0.#', 'vi_VN').format(value / 1000)}K';
  }

  double _x(int i, double plotW) =>
      _leftPad +
      (points.length == 1 ? plotW / 2 : plotW * i / (points.length - 1));

  double _y(double v, double plotH) =>
      _topPad + plotH * (1 - (maxY == 0 ? 0 : v / maxY));

  void _text(
    Canvas canvas,
    String s,
    Offset at, {
    TextAlign align = TextAlign.left,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: revoFont(fontSize: 10, color: AdminChartStyle.muted),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    var dx = at.dx;
    if (align == TextAlign.right) dx = at.dx - tp.width;
    if (align == TextAlign.center) dx = at.dx - tp.width / 2;
    tp.paint(canvas, Offset(dx, at.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = math.max(1.0, size.width - _leftPad - _rightPad);
    final plotH = math.max(1.0, size.height - _topPad - _bottomPad);
    final baseline = _topPad + plotH;

    final gridPaint = Paint()
      ..color = AdminChartStyle.border
      ..strokeWidth = .8;
    // Horizontal grid + y axis labels.
    for (var v = 0.0; v <= maxY + 0.001; v += interval) {
      final y = _y(v, plotH);
      canvas.drawLine(
        Offset(_leftPad, y),
        Offset(size.width - _rightPad, y),
        gridPaint,
      );
      _text(
        canvas,
        _axisLabel(v),
        Offset(_leftPad - 6, y - 6),
        align: TextAlign.right,
      );
    }
    // Axis borders.
    final axisPaint = Paint()
      ..color = AdminChartStyle.border
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(_leftPad, _topPad),
      Offset(_leftPad, baseline),
      axisPaint,
    );
    canvas.drawLine(
      Offset(_leftPad, baseline),
      Offset(size.width - _rightPad, baseline),
      axisPaint,
    );

    // Bottom date labels (first, last, and a middle one).
    final labelIndexes = <int>{0, points.length - 1, (points.length - 1) ~/ 2};
    for (final i in labelIndexes) {
      if (i < 0 || i >= points.length) continue;
      _text(
        canvas,
        DateFormat('dd/MM').format(points[i].day),
        Offset(_x(i, plotW), baseline + 6),
        align: TextAlign.center,
      );
    }

    // Previous period (gray line).
    if (previousValues.length == points.length && previousValues.length > 1) {
      final prevPaint = Paint()
        ..color = const Color(0xFFBAC6D3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final path = Path();
      for (var i = 0; i < previousValues.length; i++) {
        final o = Offset(_x(i, plotW), _y(previousValues[i], plotH));
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, prevPaint);
    }

    // Current line + area.
    final linePath = Path();
    for (var i = 0; i < values.length; i++) {
      final o = Offset(_x(i, plotW), _y(values[i], plotH));
      i == 0 ? linePath.moveTo(o.dx, o.dy) : linePath.lineTo(o.dx, o.dy);
    }
    final areaPath = Path.from(linePath)
      ..lineTo(_x(values.length - 1, plotW), baseline)
      ..lineTo(_x(0, plotW), baseline)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AdminChartStyle.blue.withValues(alpha: .16),
            AdminChartStyle.blue.withValues(alpha: .01),
          ],
        ).createShader(Rect.fromLTWH(_leftPad, _topPad, plotW, plotH)),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = AdminChartStyle.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Selected vertical dashed line + dot.
    final sx = _x(selectedIndex, plotW);
    final dashPaint = Paint()
      ..color = AdminChartStyle.blue.withValues(alpha: .6)
      ..strokeWidth = 1;
    for (var y = _topPad; y < baseline; y += 9) {
      canvas.drawLine(
        Offset(sx, y),
        Offset(sx, math.min(y + 5, baseline)),
        dashPaint,
      );
    }
    final sy = _y(values[selectedIndex], plotH);
    canvas.drawCircle(Offset(sx, sy), 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(sx, sy),
      4.5,
      Paint()
        ..color = AdminChartStyle.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.values != values ||
      old.previousValues != previousValues ||
      old.selectedIndex != selectedIndex ||
      old.maxY != maxY;
}
