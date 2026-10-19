import 'package:flutter/material.dart';

import '../../activity/models/rescue_order.dart';
import '../../activity/models/order_details.dart';
import '../../activity/widgets/order_summary.dart';
import '../models/tracking_snapshot.dart';
import '../theme/order_tracking_theme.dart';
import 'order_tracking_summary_cards.dart';
import 'order_tracking_history.dart';

/// Presentation only. Tracking/contact values are resolved by the service.
class OrderTrackingStatusCard extends StatelessWidget {
  const OrderTrackingStatusCard({
    super.key,
    required this.order,
    required this.snapshot,
    required this.details,
    required this.onCopy,
    required this.onDetails,
    required this.onCall,
    required this.onChat,
    required this.onCancel,
  });
  final RescueOrder order;
  final TrackingSnapshot snapshot;
  final OrderDetails details;
  final VoidCallback onCopy, onDetails;
  final VoidCallback? onCall, onChat, onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: CustomerOrderTheme.line,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 18),
        TrackingOrderHeader(order: order, onCopy: onCopy),
        const SizedBox(height: 16),
        TrackingOverviewCard(details: details, snapshot: snapshot),
        const SizedBox(height: 12),
        TrackingMechanicCard(
          mechanic: snapshot.mechanic,
          onCall: onCall,
          onChat: onChat,
        ),
        if (snapshot.isSimulated || snapshot.feedNotice != null) ...[
          const SizedBox(height: 12),
          Text(
            snapshot.feedNotice ?? 'Lộ trình mô phỏng',
            style: CustomerOrderTheme.text(
              fontSize: 11,
              color: OrderTrackingColors.muted,
            ),
          ),
        ],
        const SizedBox(height: 20),
        OrderTrackingHistory(
          entries: details.timeline,
          address: order.locationAddress,
          onViewAll: onDetails,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CustomerOrderTheme.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TrackingMetric(
                  label: 'Dịch vụ',
                  value: snapshot.serviceLabel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TrackingMetric(
                  label: 'Khoảng cách',
                  value: snapshot.distanceLabel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TrackingMetric(
                  label: 'Dự kiến',
                  value: snapshot.etaLabel,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Divider(height: 1, color: OrderTrackingColors.border),
        const SizedBox(height: 18),
        Text(
          snapshot.heading,
          key: const ValueKey('tracking-heading'),
          style: CustomerOrderTheme.text(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          snapshot.subtitle,
          key: const ValueKey('tracking-eta'),
          style: CustomerOrderTheme.text(
            color: OrderTrackingColors.muted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        if (snapshot.mechanic.shop.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            snapshot.mechanic.shop,
            style: CustomerOrderTheme.text(
              fontSize: 12,
              color: OrderTrackingColors.muted,
            ),
          ),
        ],
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              'Dịch vụ cứu hộ',
              style: CustomerOrderTheme.text(
                color: OrderTrackingColors.muted,
                fontSize: 13,
              ),
            ),
            Text(
              formatOrderPrice(order.totalPrice),
              key: const ValueKey('tracking-total'),
              style: CustomerOrderTheme.text(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CustomerOrderTheme.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final item in order.items)
          Text(
            '${item.name}${item.quantity > 1 ? ' × ${item.quantity}' : ''}',
            style: CustomerOrderTheme.text(fontSize: 13, height: 1.5),
          ),
        if (order.items.isEmpty)
          Text(
            order.serviceOption.isNotEmpty
                ? order.serviceOption
                : order.serviceType.label,
            style: CustomerOrderTheme.text(fontSize: 13, height: 1.5),
          ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 18,
              color: Colors.black,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                order.locationAddress,
                style: CustomerOrderTheme.text(
                  color: OrderTrackingColors.muted,
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
            style: TextButton.styleFrom(
              foregroundColor: OrderTrackingColors.muted,
            ),
            child: const Text('Hủy đơn hàng'),
          ),
        ],
      ],
    );
  }
}

class _TrackingMetric extends StatelessWidget {
  const _TrackingMetric({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: CustomerOrderTheme.text(
          fontSize: 12,
          color: OrderTrackingColors.muted,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: CustomerOrderTheme.text(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    ],
  );
}
