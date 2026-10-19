import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/admin_tokens.dart';
import '../theme/admin_typography.dart';
import '../models/admin_dashboard_models.dart';
import 'admin_common.dart';
import 'admin_health_card.dart';
import 'admin_overview_cards.dart';
import 'admin_timeseries_chart.dart';

class AdminDashboardHighlightsView extends StatelessWidget {
  const AdminDashboardHighlightsView({
    super.key,
    required this.data,
    required this.period,
    required this.onPeriodChanged,
    required this.selectedFilterIndex,
  });
  final AdminDashboardHighlights data;
  final String period;
  final ValueChanged<String?> onPeriodChanged;
  final int selectedFilterIndex;

  @override
  Widget build(BuildContext context) => switch (selectedFilterIndex) {
    1 => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSosOverviewCard(data: data, period: period),
        const SizedBox(height: 16),
        _SosDetailsCard(data: data, period: period),
      ],
    ),
    2 => AdminPeopleOverviewCard(
      data: data,
      period: period,
      onPeriodChanged: onPeriodChanged,
      showFootnote: true,
    ),
    3 => _RevenueCard(data: data),
    _ => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSosOverviewCard(data: data, period: period),
        const SizedBox(height: 16),
        AdminPeopleOverviewCard(
          data: data,
          period: period,
          onPeriodChanged: onPeriodChanged,
        ),
        const SizedBox(height: 16),
        AdminRevenueOverviewCard(data: data),
      ],
    ),
  };
}

class _SosDetailsCard extends StatelessWidget {
  const _SosDetailsCard({required this.data, required this.period});
  final AdminDashboardHighlights data;
  final String period;

  @override
  Widget build(BuildContext context) => AdminHealthCard(
    title: 'Xu hướng cứu hộ',
    icon: Icons.local_fire_department_rounded,
    color: AdminTokens.primaryRed,
    onOpen: () => context.go('/admin/orders'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          data.orders > data.previousOrders
              ? 'Số ca cứu hộ đang cao hơn kỳ trước.'
              : data.orders < data.previousOrders
              ? 'Số ca cứu hộ đang thấp hơn kỳ trước.'
              : 'Số ca cứu hộ ổn định so với kỳ trước.',
          style: _insightStyle,
        ),
        const Divider(height: 32),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 12,
            runSpacing: 14,
            children: [
              SizedBox(
                width: (constraints.maxWidth - 12) / 2,
                child: _ComparisonValue(
                  label: period,
                  value: '${data.orders}',
                  unit: 'ca',
                  color: AdminTokens.primaryRed,
                ),
              ),
              SizedBox(
                width: (constraints.maxWidth - 12) / 2,
                child: _ComparisonValue(
                  label: 'Kỳ trước',
                  value: '${data.previousOrders}',
                  unit: 'ca',
                  color: AdminTokens.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminSosTrendChart(
          points: data.points,
          previousPoints: data.previousPoints,
        ),
        const SizedBox(height: 12),
        Text(
          'Trung bình ${NumberFormat('0.#', 'vi_VN').format(data.dailyOrdersAverage)} ca/ngày',
          style: _mutedStyle,
        ),
        const SizedBox(height: 4),
        Text(
          'Lũy kế theo ngày · So với cùng số ngày liền trước',
          style: _mutedStyle,
        ),
        _DailyValues(data: data, money: false),
      ],
    ),
  );
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.data});
  final AdminDashboardHighlights data;

  @override
  Widget build(BuildContext context) => AdminHealthCard(
    title: 'Doanh thu & Dòng tiền',
    icon: Icons.account_balance_wallet_outlined,
    color: const Color(0xFF1A2B4C),
    backgroundColor: Colors.white,
    onOpen: () => context.go('/admin/finance'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Dòng tiền thu trong kỳ đã chọn.', style: _insightStyle),
        const Divider(height: 32),
        Text('Đã thu', style: _mutedStyle),
        const SizedBox(height: 6),
        Text(
          adminMoney(data.collected),
          style: GoogleFonts.montserrat(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AdminTokens.primaryBlue,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            const Icon(
              Icons.horizontal_rule_rounded,
              color: AdminTokens.primaryBlue,
              size: 18,
            ),
            Text(
              'Trung bình ${adminMoney(data.dailyAverage.round())}/ngày',
              style: _mutedStyle,
            ),
          ],
        ),
        const SizedBox(height: 20),
        AdminRevenueBarChart(points: data.points),
        const SizedBox(height: 12),
        Text('Theo ngày tạo đơn · VND', style: _mutedStyle),
        _DailyValues(data: data, money: true),
      ],
    ),
  );
}

final _insightStyle = GoogleFonts.montserrat(
  fontSize: 17,
  fontWeight: FontWeight.w600,
  height: 1.5,
  color: AdminTokens.text,
  letterSpacing: -0.3,
);
final _mutedStyle = GoogleFonts.montserrat(
  fontSize: 11,
  color: AdminTokens.muted,
  height: 1.5,
  fontWeight: FontWeight.w400,
  letterSpacing: -0.2,
);

class _ComparisonValue extends StatelessWidget {
  const _ComparisonValue({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });
  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text.rich(
        TextSpan(
          text: value,
          children: [
            TextSpan(
              text: ' $unit',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        style: GoogleFonts.montserrat(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.5,
          height: 1.2,
        ),
      ),
    ],
  );
}

class _DailyValues extends StatelessWidget {
  const _DailyValues({required this.data, required this.money});
  final AdminDashboardHighlights data;
  final bool money;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: PageStorageKey('admin-daily-${money ? 'money' : 'sos'}'),
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 8),
    shape: const Border(),
    collapsedShape: const Border(),
    title: Text(
      'Dữ liệu theo ngày',
      style: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    ),
    children: [
      for (final point in data.points)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('dd/MM').format(point.day), style: _mutedStyle),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  money
                      ? 'Thu: ${adminMoney(point.collected)}\n'
                            'Hoàn: ${adminMoney(point.refunded)}\n'
                            'Cộng ví thợ: ${adminMoney(point.credited)}'
                      : '${point.orders} ca',
                  textAlign: TextAlign.end,
                  style: AdminTypography.caption.copyWith(
                    color: AdminTokens.text,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
