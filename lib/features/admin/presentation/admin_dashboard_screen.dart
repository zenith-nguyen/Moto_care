import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/revo_brand.dart';
import '../application/admin_dashboard_controller.dart';
import '../application/admin_dashboard_state.dart';
import 'admin_formatters.dart';

/// Admin dashboard wired to the real AdminDashboardController
/// (GET /admin/dashboard/summary + timeseries + reconciliation). Design follows
/// the REVO admin reference; all figures are live backend data.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardControllerProvider);
    return Scaffold(
      backgroundColor: RevoBrandColors.bg,
      appBar: AppBar(
        backgroundColor: RevoBrandColors.bg,
        foregroundColor: RevoBrandColors.ink,
        title: const Text(
          'Quản trị REVO',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: () =>
                ref.read(adminDashboardControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: RevoBrandColors.dangerDark,
                ),
                const SizedBox(height: 8),
                Text(
                  'Không tải được bảng điều khiển: $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(adminDashboardControllerProvider),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (data) => _DashboardBody(state: data),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.state});

  final AdminDashboardState state;

  @override
  Widget build(BuildContext context) {
    final summary = state.summary;
    final money = summary.money;
    final providers = summary.providers;
    final orders = summary.orders;
    final users = summary.users;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Kỳ: ${formatAdminDate(summary.period.from)} - '
                '${formatAdminDate(summary.period.to)}',
                style: const TextStyle(
                  color: RevoBrandColors.textSubtle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (summary.sandboxOnly) const _Badge(text: 'SANDBOX'),
          ],
        ),
        const SizedBox(height: 16),
        const _SectionLabel('Tài chính'),
        const SizedBox(height: 10),
        _MetricGrid(
          tiles: [
            _Metric(
              'Đã thu (kỳ)',
              formatAdminMoney(money.collectedInPeriod),
              Icons.south_west_rounded,
              RevoBrandColors.success,
            ),
            _Metric(
              'Đang giữ',
              formatAdminMoney(money.heldCurrent),
              Icons.lock_clock_rounded,
              RevoBrandColors.warning,
            ),
            _Metric(
              'Đã chi cho thợ (kỳ)',
              formatAdminMoney(money.settledToProvidersInPeriod),
              Icons.north_east_rounded,
              RevoBrandColors.primary,
            ),
            _Metric(
              'Chờ rút',
              formatAdminMoney(money.pendingWithdrawalAmountCurrent),
              Icons.account_balance_rounded,
              RevoBrandColors.primaryDeep,
            ),
            _Metric(
              'Hoàn tiền chờ',
              formatAdminMoney(money.refundPendingCurrent),
              Icons.replay_rounded,
              RevoBrandColors.danger,
            ),
            _Metric(
              'Hoàn tiền (kỳ)',
              formatAdminMoney(money.refundedInPeriod),
              Icons.history_rounded,
              RevoBrandColors.textSubtle,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Vận hành'),
        const SizedBox(height: 10),
        _MetricGrid(
          tiles: [
            _Metric(
              'Người dùng',
              '${users.total}',
              Icons.group_rounded,
              RevoBrandColors.primary,
            ),
            _Metric(
              'Thợ chờ duyệt',
              '${providers.pending}',
              Icons.how_to_reg_rounded,
              RevoBrandColors.warning,
            ),
            _Metric(
              'Thợ trực tuyến',
              '${providers.online}',
              Icons.bolt_rounded,
              RevoBrandColors.success,
            ),
            _Metric(
              'Đơn (kỳ)',
              '${orders.total}',
              Icons.receipt_long_rounded,
              RevoBrandColors.primaryDeep,
            ),
            _Metric(
              'Tỉ lệ hoàn tất',
              '${(orders.completionRate * 100).toStringAsFixed(0)}%',
              Icons.task_alt_rounded,
              RevoBrandColors.success,
            ),
            _Metric(
              'Bản ghi đối soát',
              '${state.reconciliation.total}',
              Icons.fact_check_rounded,
              RevoBrandColors.navy,
            ),
          ],
        ),
        if (state.lastFailure != null) ...[
          const SizedBox(height: 16),
          Text(
            'Thao tác gần nhất lỗi: ${state.lastFailure}',
            style: const TextStyle(color: RevoBrandColors.dangerDark),
          ),
        ],
      ],
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.tiles});

  final List<_Metric> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = (box.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: width,
                child: _MetricCard(metric: tile),
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RevoBrandColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RevoBrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(metric.icon, color: metric.color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: RevoBrandColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.label,
            style: const TextStyle(
              fontSize: 12,
              color: RevoBrandColors.textSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: RevoBrandColors.ink,
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: RevoBrandColors.warningSoft,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: RevoBrandColors.warningDark,
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
    ),
  );
}
