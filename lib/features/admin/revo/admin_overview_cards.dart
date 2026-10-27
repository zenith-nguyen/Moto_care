import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/admin_tokens.dart';
import 'admin_charts.dart';
import 'admin_dashboard_highlights.dart';
import 'admin_health_card.dart';
import 'revo_admin_style.dart';

const _iceBlue = Color(0xFFEBF3FE);
const _heading = Color(0xFF1A2B4C);
const _pending = Color(0xFFE57373);

TextStyle get _overviewHeadingStyle => revoFont(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: _heading,
  height: 1.35,
  letterSpacing: -0.3,
);

class AdminSosOverviewCard extends StatelessWidget {
  const AdminSosOverviewCard({
    super.key,
    required this.data,
    required this.period,
    this.showChart = true,
  });

  final AdminDashboardHighlights data;
  final String period;
  final bool showChart;

  @override
  Widget build(BuildContext context) {
    final periodLabel = switch (period) {
      'Hôm nay' => 'Hôm nay',
      'Tùy chọn' => 'Khoảng đã chọn',
      _ => '$period gần nhất',
    };
    return AdminHealthCard(
      key: const ValueKey('admin-sos-overview'),
      title: 'Ca cứu hộ SOS & Đơn hàng',
      color: _heading,
      backgroundColor: Colors.white,
      borderColor: AdminChartStyle.border,
      actionColor: AdminChartStyle.muted,
      titleStyle: revoFont(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _heading,
        height: 1.4,
        letterSpacing: -0.3,
      ),
      onOpen: () => context.go('/admin/orders'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${data.orders}',
            style: revoFont(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: AdminChartStyle.blue,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$periodLabel • ${data.orders} ca đã ghi nhận',
            style: revoFont(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: AdminChartStyle.muted,
              letterSpacing: -0.2,
            ),
          ),
          if (showChart) ...[
            const SizedBox(height: 20),
            AdminSosTrendChart(
              points: data.points,
              previousPoints: const [],
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}

class AdminPeopleOverviewCard extends StatelessWidget {
  const AdminPeopleOverviewCard({
    super.key,
    required this.data,
    required this.period,
    required this.onPeriodChanged,
    this.showFootnote = false,
  });

  final AdminDashboardHighlights data;
  final String period;
  final ValueChanged<String?> onPeriodChanged;
  final bool showFootnote;

  @override
  Widget build(BuildContext context) => AdminHealthCard(
    key: const ValueKey('admin-people-overview'),
    title: 'Trạng thái hệ thống',
    titleStyle: _overviewHeadingStyle,
    color: _heading,
    backgroundColor: _iceBlue,
    trailing: _PeriodDropdown(value: period, onChanged: onPeriodChanged),
    onOpen: () => context.go('/admin/providers'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SystemMetric(
                  value: NumberFormat.decimalPattern('vi_VN')
                      .format(data.metric('Tổng khách')),
                  label: 'Tổng khách',
                  footer: const Icon(
                    Icons.people_outline_rounded,
                    size: 20,
                    color: AdminTokens.primaryBlue,
                  ),
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _SystemMetric(
                  value:
                      '${data.metric('Thợ online')}/${data.metric('Tổng thợ')}',
                  label: 'Thợ online',
                  footer: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AdminTokens.success.withValues(alpha: .12),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AdminTokens.success,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(width: 8, height: 8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: Tooltip(
                  message:
                      '${data.metric('Thợ chờ duyệt')} việc cần xử lý; '
                      '${data.metric('Đơn đang làm')} đơn hoàn tiền',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.go('/admin/finance'),
                    child: _SystemMetric(
                      value: '${data.metric('Thợ chờ duyệt')}',
                      label: 'Cần xử lý',
                      color: _pending,
                      footer: Text(
                        '${data.metric('Đơn đang làm')} đơn',
                        style: revoFont(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AdminTokens.primaryBlue,
                          height: 1.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showFootnote) ...[
          const SizedBox(height: 20),
          Text(
            'Khách và thợ: số hiện tại · Cần xử lý: yêu cầu đang chờ',
            style: revoFont(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AdminTokens.muted,
              height: 1.5,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ],
    ),
  );
}

class AdminRevenueOverviewCard extends StatelessWidget {
  const AdminRevenueOverviewCard({super.key, required this.data});

  final AdminDashboardHighlights data;

  @override
  Widget build(BuildContext context) => AdminHealthCard(
    key: const ValueKey('admin-revenue-overview'),
    title: 'Doanh thu & Dòng tiền',
    titleStyle: _overviewHeadingStyle,
    color: _heading,
    backgroundColor: Colors.white,
    borderColor: AdminChartStyle.border,
    onOpen: () => context.go('/admin/finance'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          revoMoney(data.collected),
          style: revoFont(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AdminChartStyle.blue,
            height: 1.25,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        AdminRevenueChart(points: data.points, compact: true),
      ],
    ),
  );
}

class _SystemMetric extends StatelessWidget {
  const _SystemMetric({
    required this.value,
    required this.label,
    required this.footer,
    this.color = AdminTokens.text,
  });

  final String value;
  final String label;
  final Widget footer;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: revoFont(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.3,
            letterSpacing: -0.5,
          ),
        ),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: revoFont(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AdminTokens.muted,
          height: 1.4,
          letterSpacing: -0.2,
        ),
      ),
      const SizedBox(height: 12),
      footer,
    ],
  );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) => VerticalDivider(
    width: 20,
    thickness: 1,
    color: _heading.withValues(alpha: .08),
  );
}

class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: _heading.withValues(alpha: .045),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          isDense: true,
          borderRadius: BorderRadius.circular(20),
          icon: const Icon(
            Icons.expand_more_rounded,
            size: 16,
            color: _heading,
          ),
          dropdownColor: Colors.white,
          style: revoFont(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _heading,
            letterSpacing: -0.2,
          ),
          items: [
            for (final period in ['Hôm nay', '7 ngày', '30 ngày', 'Tùy chọn'])
              DropdownMenuItem(value: period, child: Text(period)),
          ],
        ),
      ),
    ),
  );
}
