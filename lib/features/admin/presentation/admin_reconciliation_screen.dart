import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/revo_brand.dart';
import '../../orders/domain/order_status.dart';
import '../application/admin_dashboard_controller.dart';
import '../application/admin_dashboard_state.dart';
import '../domain/admin_analytics_models.dart';
import 'admin_formatters.dart';

/// Admin reconciliation ledger: the per-order view behind the dashboard's
/// "Bản ghi đối soát" count. Read-only; it surfaces mismatches (flags) between
/// orders, payments and provider wallet credits, with a payment-status filter
/// and pagination. It never changes any money state.
class AdminReconciliationScreen extends ConsumerWidget {
  const AdminReconciliationScreen({super.key});

  static const _filters = <PaymentStatus?>[
    null,
    PaymentStatus.paid,
    PaymentStatus.refunded,
    PaymentStatus.refundPending,
    PaymentStatus.pending,
    PaymentStatus.failed,
    PaymentStatus.cancelled,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardControllerProvider);

    ref.listen(adminDashboardControllerProvider, (previous, next) {
      final failure = next.value?.lastFailure;
      if (failure != null && previous?.value?.lastFailure != failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: RevoBrandColors.dangerDark,
              content: Text('Thao tác không thành công: $failure'),
            ),
          );
      }
    });

    return Scaffold(
      backgroundColor: RevoBrandColors.bg,
      appBar: AppBar(
        backgroundColor: RevoBrandColors.bg,
        foregroundColor: RevoBrandColors.ink,
        title: const Text(
          'Sổ đối soát',
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
                  'Không tải được sổ đối soát: $error',
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
        data: (data) => _Body(data: data),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.data});

  final AdminDashboardState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = data.reconciliation;
    final notifier = ref.read(adminDashboardControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FilterBar(
          selected: data.paymentFilter,
          busy: data.isBusy,
          onSelect: (status) =>
              notifier.changeReconciliation(paymentStatus: status),
        ),
        if (data.isBusy) const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            '${page.total} bản ghi · trang ${page.page}/'
            '${page.totalPages == 0 ? 1 : page.totalPages}',
            style: const TextStyle(
              color: RevoBrandColors.textSubtle,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: page.items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Không có bản ghi đối soát nào khớp bộ lọc.'),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: page.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _ReconciliationCard(item: page.items[index]),
                ),
        ),
        if (page.totalPages > 1)
          _Pagination(
            page: page.page,
            totalPages: page.totalPages,
            busy: data.isBusy,
            onPage: (value) => notifier.changeReconciliation(
              paymentStatus: data.paymentFilter,
              page: value,
            ),
          ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.busy,
    required this.onSelect,
  });

  final PaymentStatus? selected;
  final bool busy;
  final ValueChanged<PaymentStatus?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          for (final status in AdminReconciliationScreen._filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  status == null ? 'Tất cả' : paymentStatusLabel(status),
                ),
                selected: selected == status,
                onSelected: busy ? null : (_) => onSelect(status),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReconciliationCard extends StatelessWidget {
  const _ReconciliationCard({required this.item});

  final ReconciliationItem item;

  @override
  Widget build(BuildContext context) {
    final order = item.order;
    final payment = item.payment;
    final hasFlags = item.flags.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RevoBrandColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFlags ? RevoBrandColors.warning : RevoBrandColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.code,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              _Chip(
                label: adminOrderStatusLabel(order.status),
                color: RevoBrandColors.primaryDeep,
                background: RevoBrandColors.surfaceSoft,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _kv('Khách', '#${order.customer.id} · ${order.customer.name}'),
          _kv(
            'Thợ',
            order.provider == null
                ? 'Chưa gán'
                : '#${order.provider!.id} · ${order.provider!.name}',
          ),
          if (order.finalPrice != null)
            _kv('Giá cuối', formatAdminMoney(order.finalPrice!)),
          if (payment != null)
            _kv(
              'Thanh toán',
              '${formatAdminMoney(payment.amount)} · '
                  '${paymentStatusLabel(payment.status)}'
                  '${payment.isDemo ? " · SANDBOX" : ""}'
                  '${payment.paymentCount > 1 ? " · ${payment.paymentCount} lần" : ""}',
            ),
          _kv(
            'Ghi có ví thợ',
            '${formatAdminMoney(item.settlement.creditedAmount)}'
                '${item.settlement.creditCount != 1 ? " · ${item.settlement.creditCount} lần" : ""}',
          ),
          _kv('Tạo lúc', formatAdminDate(order.createdAt)),
          if (hasFlags) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final flag in item.flags)
                  _Chip(
                    label: reconciliationFlagLabel(flag),
                    color: RevoBrandColors.warningDark,
                    background: RevoBrandColors.warningSoft,
                    icon: Icons.flag_rounded,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: RevoBrandColors.textSubtle),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.totalPages,
    required this.busy,
    required this.onPage,
  });

  final int page;
  final int totalPages;
  final bool busy;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: busy || page <= 1 ? null : () => onPage(page - 1),
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Trước'),
            ),
            Text(
              'Trang $page/$totalPages',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            OutlinedButton.icon(
              onPressed: busy || page >= totalPages
                  ? null
                  : () => onPage(page + 1),
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('Sau'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
