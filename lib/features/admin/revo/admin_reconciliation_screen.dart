import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/admin_tokens.dart';
import '../application/admin_dashboard_controller.dart';
import '../application/admin_dashboard_state.dart';
import '../domain/admin_analytics_models.dart';
import '../presentation/admin_formatters.dart';
import 'revo_admin_style.dart';

/// "Thanh toán & đối soát" in the REVO prototype look. READ-ONLY: it only reads
/// the real dashboard money summary + reconciliation ledger and never mutates
/// any money state. No fake card number is shown for the escrow wallet.
class RevoAdminReconciliationScreen extends ConsumerWidget {
  const RevoAdminReconciliationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardControllerProvider);
    return ColoredBox(
      color: AdminTokens.background,
      child: Column(
        children: [
          _Header(),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _Retry(
                onRetry: () => ref.invalidate(adminDashboardControllerProvider),
              ),
              data: (data) => RefreshIndicator(
                onRefresh: () => ref
                    .read(adminDashboardControllerProvider.notifier)
                    .refresh(),
                child: _Body(data: data),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      16,
      MediaQuery.paddingOf(context).top + 14,
      16,
      12,
    ),
    child: Text(
      'Thanh toán & đối soát',
      textAlign: TextAlign.center,
      style: revoFont(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AdminTokens.text,
        letterSpacing: -0.3,
      ),
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.data});

  final AdminDashboardState data;

  @override
  Widget build(BuildContext context) {
    final money = data.summary.money;
    final items = data.reconciliation.items;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: revoCardDecoration(
            color: AdminTokens.surface,
            border: AdminTokens.border,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tổng tiền khách chuyển',
                textAlign: TextAlign.center,
                style: revoFont(fontSize: 13, color: AdminTokens.muted),
              ),
              const SizedBox(height: 6),
              Text(
                formatAdminMoney(money.collectedInPeriod),
                textAlign: TextAlign.center,
                style: revoFont(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AdminChartStyle.blue,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _WalletTile(
                      icon: Icons.south_west_rounded,
                      label: 'Khách chuyển',
                      value: formatAdminMoney(money.collectedInPeriod),
                      highlight: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _WalletTile(
                      icon: Icons.lock_clock_rounded,
                      label: 'Revo giữ',
                      value: formatAdminMoney(money.heldCurrent),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _WalletTile(
                      icon: Icons.build_rounded,
                      label: 'Ví thợ',
                      value: formatAdminMoney(
                        money.providerWalletBalanceCurrent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _EscrowCard(
          settled: formatAdminMoney(money.settledToProvidersInPeriod),
        ),
        const SizedBox(height: 20),
        Text(
          'Hoạt động hóa đơn',
          style: revoFont(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AdminTokens.text,
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Chưa có bản ghi đối soát trong kỳ.',
                style: revoFont(fontSize: 13, color: AdminTokens.muted),
              ),
            ),
          )
        else
          Container(
            decoration: revoCardDecoration(
              color: AdminTokens.surface,
              border: AdminTokens.border,
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      color: AdminTokens.border,
                      indent: 16,
                      endIndent: 16,
                    ),
                  _InvoiceRow(item: items[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: highlight ? AdminTokens.activePill : AdminTokens.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: highlight ? AdminTokens.primaryBlue : AdminTokens.border,
      ),
    ),
    child: Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: highlight ? AdminTokens.primaryBlue : AdminTokens.muted,
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: revoFont(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AdminTokens.text,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: revoFont(fontSize: 10, color: AdminTokens.muted)),
      ],
    ),
  );
}

class _EscrowCard extends StatelessWidget {
  const _EscrowCard({required this.settled});

  final String settled;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF14233B), Color(0xFF243B5A)],
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Ví đối soát hệ thống Admin',
              style: revoFont(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Đã chi cho thợ trong kỳ',
          style: revoFont(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          settled,
          style: revoFont(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Đối soát thủ công: chi tiền cho thợ bằng chuyển khoản tay rồi ghi '
          'nhận lại ở tab Xử lý yêu cầu.',
          style: revoFont(
            fontSize: 11,
            height: 1.45,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    ),
  );
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.item});

  final ReconciliationItem item;

  @override
  Widget build(BuildContext context) {
    final payment = item.payment;
    final amount = payment?.amount ?? item.order.finalPrice;
    final flagged = item.flags.isNotEmpty;
    final status = payment != null
        ? paymentStatusLabel(payment.status)
        : adminOrderStatusLabel(item.order.status);
    final (dotColor, statusBg, statusFg) = flagged
        ? (
            AdminTokens.primaryRed,
            const Color(0xFFFFEBEE),
            AdminTokens.primaryRed,
          )
        : (
            AdminTokens.success,
            AdminTokens.activePill,
            AdminTokens.primaryBlue,
          );
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.order.code,
                  style: revoFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AdminTokens.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatAdminDate(item.order.createdAt),
                  style: revoFont(fontSize: 11, color: AdminTokens.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: flagged ? statusBg : statusBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              flagged ? 'Cần đối soát' : status,
              style: revoFont(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusFg,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (amount != null)
            Text(
              formatAdminMoney(amount),
              style: revoFont(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AdminTokens.text,
              ),
            ),
        ],
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: AdminTokens.muted,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Không tải được dữ liệu đối soát.',
            style: revoFont(fontSize: 13, color: AdminTokens.muted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}
