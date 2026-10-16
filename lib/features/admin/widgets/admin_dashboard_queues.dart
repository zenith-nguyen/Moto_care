import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/admin_tokens.dart';
import '../providers/admin_providers.dart';
import 'admin_common.dart';
import 'admin_health_card.dart';

class AdminDashboardUrgentOrders extends ConsumerWidget {
  const AdminDashboardUrgentOrders({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminHealthCard(
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
        AdminAsyncSection(
          value: ref.watch(adminDashboardUrgentOrdersProvider),
          onRetry: () => ref.invalidate(adminOrdersProvider),
          isEmpty: (orders) => orders.isEmpty,
          builder: (orders) => Column(
            children: [
              for (final order in orders.take(3))
                _QueueRow(
                  title: '${order.id} · ${order.customer}',
                  subtitle: '${order.incident}\n${order.status.label}',
                  icon: Icons.emergency_outlined,
                  color: AdminTokens.primaryRed,
                  onTap: () => context.go('/admin/orders/${order.id}'),
                ),
              _QueueLink(
                label: 'Xem đơn hàng (${orders.length})',
                onTap: () => context.go('/admin/orders'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class AdminDashboardMoneyRequests extends ConsumerWidget {
  const AdminDashboardMoneyRequests({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminHealthCard(
    title: 'Yêu cầu Rút tiền / Hoàn tiền',
    icon: Icons.account_balance_outlined,
    color: AdminTokens.primaryBlue,
    onOpen: () => context.go('/admin/requests'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _QueueIntro(
          title: 'Theo dõi các khoản đang chờ',
          description: 'Kiểm tra yêu cầu và đối chiếu thông tin thanh toán.',
        ),
        AdminAsyncSection(
          value: ref.watch(adminDashboardMoneyQueueProvider),
          onRetry: () {
            ref.invalidate(adminRefundsProvider);
            ref.invalidate(adminWithdrawalsProvider);
          },
          isEmpty: (queue) => queue.isEmpty,
          builder: (queue) => Column(
            children: [
              for (final request in queue.withdrawals.take(2))
                _QueueRow(
                  title: 'Rút tiền · ${request.providerName}',
                  subtitle: '${request.id} · ${adminMoney(request.amount)}',
                  icon: Icons.south_west_rounded,
                  color: AdminTokens.primaryBlue,
                  onTap: () => context.go('/admin/requests?tab=withdrawals'),
                ),
              for (final request in queue.refunds.take(2))
                _QueueRow(
                  title: 'Hoàn tiền · ${request.customer}',
                  subtitle:
                      '${request.orderId} · ${adminMoney(request.amount)}',
                  icon: Icons.replay_rounded,
                  color: AdminTokens.primaryRed,
                  onTap: () => context.go('/admin/requests'),
                ),
              _QueueLink(
                label: 'Xem yêu cầu (${queue.total})',
                onTap: () => context.go('/admin/requests'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
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
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        description,
        style: const TextStyle(
          fontSize: 12,
          height: 1.6,
          color: AdminTokens.muted,
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: AdminTokens.muted,
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
        textStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      child: Text(label),
    ),
  );
}
