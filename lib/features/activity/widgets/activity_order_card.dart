import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../home/theme/home_theme.dart';
import '../models/rescue_order.dart';
import 'order_summary.dart';

class ActivityOrderCard extends StatelessWidget {
  const ActivityOrderCard({
    super.key,
    required this.order,
    required this.onDetails,
    required this.onRebook,
  });
  final RescueOrder order;
  final VoidCallback onDetails;
  final VoidCallback onRebook;

  @override
  Widget build(BuildContext context) {
    final cancelled = order.status == RescueOrderStatus.cancelled;
    final active = order.status.isActive;
    final statusColor = cancelled
        ? HomeColors.red
        : active
        ? HomeColors.primary
        : HomeColors.text;
    return Container(
      decoration: BoxDecoration(
        color: HomeColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [HomeColors.shadow],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  DateFormat('HH:mm, dd/MM').format(order.createdAt.toLocal()),
                  style: const TextStyle(
                    color: HomeColors.secondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.status == RescueOrderStatus.completed
                        ? 'Hoàn thành'
                        : order.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HomeColors.selected,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  serviceIcon(order.serviceType),
                  size: 30,
                  color: HomeColors.primary,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.providerName ??
                          (active
                              ? 'Đang tìm thợ gần bạn'
                              : 'Chưa có thợ nhận đơn'),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      order.locationAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: HomeColors.secondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  order.orderCode,
                  style: const TextStyle(
                    color: HomeColors.secondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  cancelled
                      ? 'Chưa thanh toán'
                      : '${active ? 'Dự kiến: ' : ''}${formatOrderPrice(order.totalPrice)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onDetails,
                  style: TextButton.styleFrom(
                    foregroundColor: HomeColors.text,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Chi tiết đơn',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: active ? null : onRebook,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Gọi lại đơn này',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
