import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/admin_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../models/admin_dashboard_models.dart';
import 'admin_common.dart';
import 'admin_health_card.dart';
import 'admin_timeseries_chart.dart';

class AdminDashboardHighlightsView extends StatelessWidget {
  const AdminDashboardHighlightsView({
    super.key,
    required this.data,
    required this.period,
    required this.selectedFilterIndex,
  });
  final AdminDashboardHighlights data;
  final String period;
  final int selectedFilterIndex;

  @override
  Widget build(BuildContext context) => switch (selectedFilterIndex) {
    1 => _SosCard(data: data, period: period),
    2 => _PeopleCard(data: data),
    3 => _RevenueCard(data: data),
    _ => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SosCard(data: data, period: period, compact: true),
        const SizedBox(height: 16),
        _PeopleCard(data: data, compact: true),
        const SizedBox(height: 16),
        _RevenueCard(data: data, compact: true),
      ],
    ),
  };
}

class _SosCard extends StatelessWidget {
  const _SosCard({
    required this.data,
    required this.period,
    this.compact = false,
  });
  final AdminDashboardHighlights data;
  final String period;
  final bool compact;

  @override
  Widget build(BuildContext context) => AdminHealthCard(
    title: 'Ca cứu hộ SOS & Đơn hàng',
    icon: Icons.local_fire_department_rounded,
    color: AdminTokens.primaryRed,
    onOpen: () => context.go('/admin/orders'),
    child: compact
        ? Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: '${data.orders}',
                    children: const [
                      TextSpan(
                        text: ' ca',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AdminTokens.primaryRed,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(period, style: _mutedStyle),
            ],
          )
        : Column(
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
              const Text(
                'Lũy kế theo ngày · So với cùng số ngày liền trước',
                style: _mutedStyle,
              ),
              _DailyValues(data: data, money: false),
            ],
          ),
  );
}

class _PeopleCard extends StatelessWidget {
  const _PeopleCard({required this.data, this.compact = false});
  final AdminDashboardHighlights data;
  final bool compact;

  @override
  Widget build(BuildContext context) => AdminHealthCard(
    title: 'Trạng thái Thợ & Khách hàng',
    icon: Icons.people_alt_outlined,
    color: AdminTokens.primaryBlue,
    onOpen: () => context.go('/admin/providers'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          const Text(
            'Kết nối sẵn sàng, hỗ trợ kịp thời.',
            style: _insightStyle,
          ),
          const Divider(height: 32),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 800 ? 4 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 20,
              children: [
                SizedBox(
                  width: width,
                  child: _RegistryValue(
                    label: 'Tổng khách',
                    value: NumberFormat.decimalPattern('vi_VN')
                        .format(data.metric('Tổng khách')),
                    icon: Icons.person_outline_rounded,
                    compact: compact,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _RegistryValue(
                    label: 'Thợ online',
                    value: '${data.metric('Thợ online')}',
                    suffix: '/${data.metric('Tổng thợ')}',
                    icon: Icons.engineering_outlined,
                    color: AdminTokens.primaryBlue,
                    compact: compact,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _RegistryValue(
                    label: 'Thợ chờ duyệt',
                    value: '${data.metric('Thợ chờ duyệt')}',
                    icon: Icons.verified_user_outlined,
                    color: AdminTokens.primaryRed,
                    compact: compact,
                    onTap: () => context.go('/admin/providers'),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _RegistryValue(
                    label: 'Đơn đang làm',
                    value: '${data.metric('Đơn đang làm')}',
                    icon: Icons.handyman_outlined,
                    compact: compact,
                  ),
                ),
              ],
            );
          },
        ),
        if (!compact) ...[
          const SizedBox(height: 20),
          const Text(
            'Khách và thợ: số hiện tại · Đơn đang làm: trong kỳ đã chọn',
            style: _mutedStyle,
          ),
        ],
      ],
    ),
  );
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.data, this.compact = false});
  final AdminDashboardHighlights data;
  final bool compact;

  @override
  Widget build(BuildContext context) => AdminHealthCard(
    title: 'Doanh thu & Dòng tiền',
    icon: Icons.account_balance_wallet_outlined,
    color: AdminTokens.primaryBlue,
    onOpen: () => context.go('/admin/finance'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          const Text('Dòng tiền thu trong kỳ đã chọn.', style: _insightStyle),
          const Divider(height: 32),
        ],
        const Text('Đã thu', style: _mutedStyle),
        const SizedBox(height: 6),
        Text(
          adminMoney(data.collected),
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AdminTokens.primaryBlue,
            letterSpacing: -.8,
            height: 1.2,
          ),
        ),
        if (!compact) ...[
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
          const Text('Theo ngày tạo đơn · VND', style: _mutedStyle),
          _DailyValues(data: data, money: true),
        ],
      ],
    ),
  );
}

const _insightStyle = TextStyle(
  fontSize: 17,
  fontWeight: FontWeight.w600,
  height: 1.5,
  color: AdminTokens.text,
);
const _mutedStyle = TextStyle(
  fontSize: 11,
  color: AdminTokens.muted,
  height: 1.5,
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -1,
          height: 1.2,
        ),
      ),
    ],
  );
}

class _RegistryValue extends StatelessWidget {
  const _RegistryValue({
    required this.label,
    required this.value,
    required this.icon,
    this.suffix = '',
    this.color = AdminTokens.text,
    this.compact = false,
    this.onTap,
  });
  final String label;
  final String value;
  final String suffix;
  final IconData icon;
  final Color color;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) ...[
            Icon(icon, size: 19, color: color),
            const SizedBox(height: 8),
          ],
          Text.rich(
            TextSpan(
              text: value,
              children: [
                TextSpan(
                  text: suffix,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AdminTokens.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: 24,
              color: color,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: _mutedStyle),
        ],
      ),
    ),
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
    title: const Text(
      'Dữ liệu theo ngày',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
                  style: AppTextStyles.caption.copyWith(
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
