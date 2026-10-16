import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/admin_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../models/admin_models.dart';
import 'admin_common.dart';

const _tooltipStyle = TextStyle(
  fontFamily: 'Montserrat',
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: AdminTokens.text,
);

/// Cumulative rescue activity, with the preceding equal-length period in gray.
/// Daily source values remain available through the card's data disclosure.
class AdminSosTrendChart extends StatelessWidget {
  const AdminSosTrendChart({
    super.key,
    required this.points,
    required this.previousPoints,
  });

  final List<AdminTimeseriesPoint> points;
  final List<AdminTimeseriesPoint> previousPoints;

  List<FlSpot> _cumulative(List<AdminTimeseriesPoint> source) {
    var total = 0;
    return [
      for (var i = 0; i < source.length; i++)
        FlSpot(
          source.length == 1 ? .5 : i.toDouble(),
          (total += source[i].orders).toDouble(),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const AdminStateView.empty();
    final current = _cumulative(points);
    final previous = _cumulative(previousPoints);
    final maximum = math.max(
      current.last.y,
      previous.isEmpty ? 0.0 : previous.last.y,
    );
    return Semantics(
      image: true,
      label:
          'Biểu đồ ca cứu hộ lũy kế. Đỏ: kỳ đã chọn, '
          '${current.last.y.toInt()} ca. Xám: kỳ trước, '
          '${previous.isEmpty ? 0 : previous.last.y.toInt()} ca. '
          'Chạm để xem số liệu; dữ liệu từng ngày ở bên dưới.',
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 10, 5, 0),
              child: LineChart(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 250),
                LineChartData(
                  minX: 0,
                  maxX: math.max(1, points.length - 1).toDouble(),
                  minY: 0,
                  maxY: math.max(1, maximum * 1.18),
                  titlesData: const FlTitlesData(show: false),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(
                    border: const Border(
                      bottom: BorderSide(color: AdminTokens.border),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AdminTokens.surface,
                      tooltipBorderRadius: BorderRadius.circular(12),
                      tooltipBorder: const BorderSide(
                        color: AdminTokens.border,
                      ),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (spots) => spots.map((spot) {
                        final source = spot.barIndex == 0 && previous.isNotEmpty
                            ? previousPoints
                            : points;
                        final index = source.length == 1
                            ? 0
                            : spot.x.round().clamp(0, source.length - 1);
                        return LineTooltipItem(
                          '${DateFormat('dd/MM').format(source[index].day)}\n'
                          '${spot.y.toInt()} ca lũy kế',
                          _tooltipStyle,
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    if (previous.isNotEmpty)
                      LineChartBarData(
                        spots: previous,
                        isCurved: true,
                        preventCurveOverShooting: true,
                        curveSmoothness: .25,
                        color: const Color(0xFFBDBDBD),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                      ),
                    LineChartBarData(
                      spots: current,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      curveSmoothness: .25,
                      color: AdminTokens.primaryRed,
                      barWidth: 3.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        checkToShowDot: (spot, _) => spot == current.last,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 4.5,
                              color: AdminTokens.primaryRed,
                              strokeWidth: 2.5,
                              strokeColor: AdminTokens.card,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AdminTokens.primaryRed.withValues(alpha: .14),
                            AdminTokens.primaryRed.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _DateAxis(points: points),
        ],
      ),
    );
  }
}

/// Rounded daily bars and an unobtrusive average reference, as in Health.
class AdminRevenueBarChart extends StatelessWidget {
  const AdminRevenueBarChart({super.key, required this.points});
  final List<AdminTimeseriesPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const AdminStateView.empty();
    final average =
        points.fold(0, (sum, p) => sum + p.collected) / points.length;
    final peak = points.map((p) => p.collected).reduce(math.max);
    return Semantics(
      image: true,
      label:
          'Biểu đồ tiền thu mỗi ngày. Trung bình '
          '${adminMoney(average.round())} mỗi ngày. '
          'Chạm cột để xem giá trị; dữ liệu từng ngày ở bên dưới.',
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            SizedBox(
              height: 190,
              child: BarChart(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 250),
                BarChartData(
                  minY: 0,
                  maxY: math.max(1, peak * 1.2),
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: const FlTitlesData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: math.max(1, peak / 3),
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: AdminTokens.border, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: average,
                        color: AdminTokens.primaryBlue.withValues(alpha: .45),
                        strokeWidth: 1.5,
                        dashArray: [5, 4],
                      ),
                    ],
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AdminTokens.surface,
                      tooltipBorderRadius: BorderRadius.circular(12),
                      tooltipBorder: const BorderSide(
                        color: AdminTokens.border,
                      ),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem(
                            '${DateFormat('dd/MM').format(points[group.x].day)}\n'
                            '${adminMoney(rod.toY.round())}',
                            _tooltipStyle,
                          ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < points.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: points[i].collected.toDouble(),
                            width: (constraints.maxWidth / points.length * .55)
                                .clamp(3, 26),
                            color: i == points.length - 1
                                ? AdminTokens.primaryBlue
                                : AdminTokens.primaryBlue.withValues(
                                    alpha: .28,
                                  ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(5),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _DateAxis(points: points, weekdays: points.length <= 7),
          ],
        ),
      ),
    );
  }
}

class _DateAxis extends StatelessWidget {
  const _DateAxis({required this.points, this.weekdays = false});
  final List<AdminTimeseriesPoint> points;
  final bool weekdays;

  @override
  Widget build(BuildContext context) {
    String label(AdminTimeseriesPoint point) => weekdays
        ? (point.day.weekday == 7 ? 'CN' : 'T${point.day.weekday + 1}')
        : DateFormat('dd/MM').format(point.day);
    final compact = MediaQuery.textScalerOf(context).scale(1) > 1.2;
    if (weekdays && !compact) {
      return Row(
        children: [
          for (final point in points)
            Expanded(
              child: Text(
                label(point),
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: AdminTokens.muted),
              ),
            ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: points.length == 1
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < points.length; i++)
          if (i == 0 ||
              i == points.length - 1 ||
              (weekdays && !compact) ||
              (points.length > 7 && i == points.length ~/ 2))
            Text(
              label(points[i]),
              style: AppTextStyles.caption.copyWith(color: AdminTokens.muted),
            ),
      ],
    );
  }
}
