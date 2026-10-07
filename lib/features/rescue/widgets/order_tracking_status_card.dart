import 'package:flutter/material.dart';

import '../../activity/models/rescue_order.dart';
import '../../activity/widgets/order_summary.dart';
import '../../home/theme/home_theme.dart';

class OrderTrackingStatusCard extends StatelessWidget {
  const OrderTrackingStatusCard({
    super.key,
    required this.order,
    required this.heading,
    required this.subtitle,
    required this.badge,
    required this.onCall,
    required this.onChat,
    required this.onCancel,
    this.rating = 4.9,
  });
  final RescueOrder order;
  final String heading, subtitle, badge;
  final double rating;
  final VoidCallback? onCall, onChat, onCancel;

  @override
  Widget build(BuildContext context) {
    final name = order.hasProvider ? order.providerName! : 'Nguyễn Văn A';
    final shop = order.partnerName ?? 'Tiệm sửa xe Siêu Tốc';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: HomeColors.redSelected,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: HomeColors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Text(
              'Lộ trình mô phỏng',
              style: TextStyle(color: HomeColors.secondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          heading,
          key: const ValueKey('tracking-heading'),
          style: const TextStyle(
            color: HomeColors.text,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          key: const ValueKey('tracking-eta'),
          style: const TextStyle(
            color: HomeColors.secondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const Divider(height: 26),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 25,
              backgroundColor: HomeColors.redSelected,
              child: Icon(
                Icons.engineering_rounded,
                color: HomeColors.red,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shop,
                    style: const TextStyle(
                      color: HomeColors.secondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${order.providerPlate ?? '59-P1 688.99'} (Honda Wave)',
                    style: const TextStyle(
                      color: HomeColors.secondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 3,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: HomeColors.red, size: 16),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: HomeColors.red,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final call = OutlinedButton.icon(
              key: const ValueKey('tracking-call'),
              onPressed: onCall,
              style: OutlinedButton.styleFrom(
                foregroundColor: HomeColors.red,
                side: const BorderSide(color: HomeColors.red),
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.phone_outlined),
              label: const Text('Gọi điện'),
            );
            final chat = FilledButton.icon(
              key: const ValueKey('tracking-chat'),
              onPressed: onChat,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Nhắn tin'),
            );
            if (constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(14) > 18) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [call, const SizedBox(height: 10), chat],
              );
            }
            return Row(
              children: [
                Expanded(child: call),
                const SizedBox(width: 12),
                Expanded(child: chat),
              ],
            );
          },
        ),
        const Divider(height: 30),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 8,
          spacing: 12,
          children: [
            const Text(
              'Dịch vụ cứu hộ',
              style: TextStyle(color: HomeColors.secondary, fontSize: 13),
            ),
            Text(
              formatOrderPrice(order.totalPrice),
              key: const ValueKey('tracking-total'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: HomeColors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final item in order.items)
          Text(
            '${item.name}${item.quantity > 1 ? ' × ${item.quantity}' : ''}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        if (order.items.isEmpty)
          Text(
            order.serviceOption.isNotEmpty
                ? order.serviceOption
                : order.serviceType.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 18,
              color: HomeColors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                order.locationAddress,
                style: const TextStyle(
                  color: HomeColors.secondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        if (onCancel != null) ...[
          const SizedBox(height: 8),
          TextButton(
            key: const ValueKey('tracking-cancel'),
            onPressed: onCancel,
            style: TextButton.styleFrom(foregroundColor: HomeColors.secondary),
            child: const Text('Hủy đơn hàng'),
          ),
        ],
      ],
    );
  }
}
