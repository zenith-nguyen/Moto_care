import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/admin_tokens.dart';
import '../application/admin_operations_controller.dart';
import '../presentation/admin_formatters.dart';
import 'admin_dashboard_data.dart';
import 'admin_health_card.dart';
import 'revo_admin_style.dart';

/// Active rescue cases (real recent orders that are not yet terminal).
class AdminDashboardUrgentOrders extends ConsumerWidget {
  const AdminDashboardUrgentOrders({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(adminUrgentOrdersProvider);
    return AdminHealthCard(
      title: 'SOS Đơn hàng khẩn cấp',
      icon: Icons.sos_rounded,
      color: AdminTokens.primaryRed,
      onOpen: () => context.go('/admin/orders'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _QueueIntro(
            title: 'Ưu tiên hỗ trợ kịp thời',
            description: 'Các ca đang tìm thợ hoặc vừa được phân công.',
          ),
          orders.when(
            loading: () => const _QueueLoading(),
            error: (_, _) => _QueueError(
              onRetry: () => ref.invalidate(adminUrgentOrdersProvider),
            ),
            data: (list) => list.isEmpty
                ? const _QueueEmpty(message: 'Không có ca khẩn cấp nào.')
                : Column(
                    children: [
                      for (final order in list.take(3))
                        _QueueRow(
                          title: order.code,
                          subtitle: adminOrderStatusLabel(order.status),
                          icon: Icons.emergency_outlined,
                          color: AdminTokens.primaryRed,
                          onTap: () => context.go('/admin/orders/${order.id}'),
                        ),
                      _QueueLink(
                        label: 'Xem đơn hàng (${list.length})',
                        onTap: () => context.go('/admin/orders'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Pending money requests (real withdrawals + full refunds awaiting action).
class AdminDashboardMoneyRequests extends ConsumerWidget {
  const AdminDashboardMoneyRequests({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ops = ref.watch(adminOperationsControllerProvider);
    return AdminHealthCard(
      title: 'Yêu cầu Rút tiền / Hoàn tiền',
      icon: Icons.account_balance_outlined,
      color: AdminTokens.primaryBlue,
      onOpen: () => context.go('/admin/finance'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _QueueIntro(
            title: 'Theo dõi các khoản đang chờ',
            description: 'Kiểm tra yêu cầu và đối chiếu thông tin thanh toán.',
          ),
          ops.when(
            loading: () => const _QueueLoading(),
            error: (_, _) => _QueueError(
              onRetry: () => ref.invalidate(adminOperationsControllerProvider),
            ),
            data: (data) {
              final total =
                  data.pendingWithdrawals.length +
                  data.pendingFullRefunds.length;
              if (total == 0) {
                return const _QueueEmpty(
                  message: 'Không có yêu cầu nào đang chờ.',
                );
              }
              return Column(
                children: [
                  for (final w in data.pendingWithdrawals.take(2))
                    _QueueRow(
                      title: 'Rút tiền · ${w.provider.name}',
                      subtitle:
                          '#${w.request.id} · ${formatAdminMoney(w.request.amount)}',
                      icon: Icons.south_west_rounded,
                      color: AdminTokens.primaryBlue,
                      onTap: () => context.go('/admin/finance'),
                    ),
                  for (final r in data.pendingFullRefunds.take(2))
                    _QueueRow(
                      title: 'Hoàn tiền · ${r.code}',
                      subtitle: r.amount == null
                          ? 'Khách #${r.customerId}'
                          : formatAdminMoney(r.amount!),
                      icon: Icons.replay_rounded,
                      color: AdminTokens.primaryRed,
                      onTap: () => context.go('/admin/finance'),
                    ),
                  _QueueLink(
                    label: 'Xem yêu cầu ($total)',
                    onTap: () => context.go('/admin/finance'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QueueIntro extends StatelessWidget {
  const _QueueIntro({required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        style: revoFont(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.4,
          letterSpacing: -0.3,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        description,
        style: revoFont(
          fontSize: 12,
          height: 1.6,
          color: AdminTokens.muted,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Divider(height: 1),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: revoFont(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: revoFont(
                        fontSize: 11,
                        height: 1.5,
                        color: AdminTokens.muted,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AdminTokens.muted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _QueueLink extends StatelessWidget {
  const _QueueLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        textStyle: revoFont(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: -0.3,
        ),
      ),
      child: Text(label),
    ),
  );
}

class _QueueLoading extends StatelessWidget {
  const _QueueLoading();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _QueueEmpty extends StatelessWidget {
  const _QueueEmpty({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Text(
      message,
      style: revoFont(fontSize: 12, color: AdminTokens.muted),
    ),
  );
}

class _QueueError extends StatelessWidget {
  const _QueueError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Không tải được dữ liệu.',
            style: revoFont(fontSize: 12, color: AdminTokens.muted),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}
