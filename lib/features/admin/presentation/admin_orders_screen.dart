import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/revo_brand.dart';
import '../application/admin_operations_controller.dart';
import '../domain/admin_operation_models.dart';
import 'admin_formatters.dart';

/// Admin recent-orders list, wired to the real AdminOperationsController
/// (GET /admin/orders). Read-only overview; tapping an order shows details.
class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminOperationsControllerProvider);
    return Scaffold(
      backgroundColor: RevoBrandColors.bg,
      appBar: AppBar(
        backgroundColor: RevoBrandColors.bg,
        foregroundColor: RevoBrandColors.ink,
        title: const Text(
          'Đơn gần đây',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: () =>
                ref.read(adminOperationsControllerProvider.notifier).refresh(),
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
                  'Không tải được danh sách đơn: $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(adminOperationsControllerProvider),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final orders = data.recentOrders;
          if (orders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Chưa có đơn nào.'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(adminOperationsControllerProvider.notifier).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _OrderCard(order: orders[index]),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final AdminRecentOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RevoBrandColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RevoBrandColors.border),
      ),
      child: ListTile(
        onTap: () => context.push('/admin/orders/${order.id}'),
        title: Row(
          children: [
            Expanded(
              child: Text(
                order.code,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            _StatusChip(label: adminOrderStatusLabel(order.status)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${formatAdminDate(order.createdAt)} · '
            '${formatAdminMoney(order.finalPrice ?? order.estimatedPrice)}',
            style: const TextStyle(color: RevoBrandColors.textSubtle),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: RevoBrandColors.surfaceSoft,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: RevoBrandColors.primaryDeep,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),
  );
}
