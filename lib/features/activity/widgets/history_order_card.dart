import 'package:flutter/material.dart';

import '../models/rescue_order.dart';
import '../theme/activity_theme.dart';
import 'order_summary.dart';

class HistoryOrderCard extends StatelessWidget {
  const HistoryOrderCard({
    super.key,
    required this.order,
    required this.onInvoice,
    required this.onRebook,
  });
  final RescueOrder order;
  final VoidCallback onInvoice;
  final VoidCallback onRebook;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onInvoice,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: ActivityTheme.background,
                  child: Icon(
                    serviceIcon(order.serviceType),
                    color: ActivityTheme.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.serviceType.label,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatOrderDate(order.createdAt),
                        style: const TextStyle(
                          color: ActivityTheme.mutedText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              order.orderCode,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              order.providerName ?? 'Chưa có thợ nhận đơn',
              style: const TextStyle(color: ActivityTheme.mutedText),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OrderStatusBadge(status: order.status),
                Text(
                  formatOrderPrice(order.totalPrice),
                  style: const TextStyle(
                    color: ActivityTheme.orange,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onInvoice,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Xem hóa đơn'),
                ),
                FilledButton.icon(
                  onPressed: onRebook,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Đặt lại'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
