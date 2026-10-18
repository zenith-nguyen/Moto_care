import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/admin_tokens.dart';
import '../models/admin_dashboard_models.dart';
import 'admin_common.dart';
import 'admin_health_card.dart';
import 'admin_timeseries_chart.dart';

const _navy = Color(0xFF0A192F);
const _iceBlue = Color(0xFFEBF3FE);
const _heading = Color(0xFF1A2B4C);
const _pending = Color(0xFFE57373);

TextStyle get _overviewHeadingStyle => GoogleFonts.montserrat(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: _heading,
  height: 1.35,
);

class AdminSosOverviewCard extends StatelessWidget {
  const AdminSosOverviewCard({
    super.key,
    required this.data,
    required this.period,
  });

  final AdminDashboardHighlights data;
  final String period;

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
      color: Colors.white,
      backgroundColor: _navy,
      actionColor: Colors.white70,
      titleStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: .8),
        height: 1.4,
      ),
      onOpen: () => context.go('/admin/orders'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.orders}',
                  style: GoogleFonts.montserrat(
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$periodLabel • ${data.orders} ca đã ghi nhận',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: .7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ExcludeSemantics(
            child: Image.asset(
              'assets/images/admin-rescue-invoice-truck.png',
              width: 104,
              height: 104,
              cacheWidth: 312,
              fit: BoxFit.contain,
            ),
          ),
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
                      '${data.metric('Thợ chờ duyệt')} thợ chờ duyệt; '
                      '${data.metric('Đơn đang làm')} đơn đang làm',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.go('/admin/providers'),
                    child: _SystemMetric(
                      value: '${data.metric('Thợ chờ duyệt')}',
                      label: 'Cần xử lý',
                      color: _pending,
                      footer: Text(
                        '${data.metric('Đơn đang làm')} đơn',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AdminTokens.primaryBlue,
                          height: 1.5,
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
            'Khách và thợ: số hiện tại · Đơn đang làm: trong kỳ đã chọn',
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AdminTokens.muted,
              height: 1.5,
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
    backgroundColor: AdminTokens.card,
    onOpen: () => context.go('/admin/finance'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          adminMoney(data.collected),
          style: GoogleFonts.montserrat(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: AdminTokens.primaryBlue,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 16),
        AdminRevenueBarChart(points: data.points, compact: true),
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
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: color,
            height: 1.3,
          ),
        ),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AdminTokens.muted,
          height: 1.4,
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
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _heading,
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
