import 'package:flutter/material.dart';

import '../../activity/models/rescue_order.dart';
import '../../activity/widgets/order_summary.dart';
import '../../home/theme/home_theme.dart';
import '../models/tracking_snapshot.dart';
import '../theme/order_tracking_theme.dart';

/// Presentation only. Tracking/contact values are resolved by the service.
class OrderTrackingStatusCard extends StatelessWidget {
  const OrderTrackingStatusCard({
    super.key,
    required this.order,
    required this.snapshot,
    required this.onCall,
    required this.onChat,
    required this.onCancel,
  });
  final RescueOrder order;
  final TrackingSnapshot snapshot;
  final VoidCallback? onCall, onChat, onCancel;

  @override
  Widget build(BuildContext context) {
    final mechanic = snapshot.mechanic;
    final largeText = MediaQuery.textScalerOf(context).scale(13) > 17;
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ContactButton(
          key: const ValueKey('tracking-chat'),
          label: 'Nhắn tin',
          icon: Icons.chat_bubble_outline_rounded,
          onPressed: onChat,
        ),
        const SizedBox(width: 8),
        _ContactButton(
          key: const ValueKey('tracking-call'),
          label: 'Gọi điện',
          icon: Icons.phone_outlined,
          onPressed: onCall,
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD7D7DC),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            Text(
              'Mã đơn: #${order.orderCode.replaceFirst(RegExp(r'^#'), '')}',
              key: const ValueKey('tracking-order-code'),
              style: const TextStyle(
                color: OrderTrackingColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: OrderTrackingColors.badge,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                snapshot.statusLabel,
                style: const TextStyle(
                  color: OrderTrackingColors.badgeText,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _TrackingMetric(
                label: 'Dịch vụ',
                value: snapshot.serviceLabel,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _TrackingMetric(
                label: 'Khoảng cách',
                value: snapshot.distanceLabel,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _TrackingMetric(
                label: 'Dự kiến',
                value: snapshot.etaLabel,
              ),
            ),
          ],
        ),
        const Divider(height: 32, color: OrderTrackingColors.border),
        Row(
          children: [
            _MechanicAvatar(
              initials: mechanic.initials,
              url: mechanic.avatarUrl,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mechanic.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    mechanic.plate,
                    style: const TextStyle(
                      fontSize: 11,
                      color: OrderTrackingColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (!largeText) ...[const SizedBox(width: 8), actions],
          ],
        ),
        if (largeText) ...[
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: actions),
        ],
        if (snapshot.isSimulated || snapshot.feedNotice != null) ...[
          const SizedBox(height: 12),
          Text(
            snapshot.feedNotice ?? 'Lộ trình mô phỏng',
            style: const TextStyle(
              fontSize: 11,
              color: OrderTrackingColors.muted,
            ),
          ),
        ],
        const SizedBox(height: 18),
        const Divider(height: 1, color: OrderTrackingColors.border),
        const SizedBox(height: 18),
        Text(
          snapshot.heading,
          key: const ValueKey('tracking-heading'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          snapshot.subtitle,
          key: const ValueKey('tracking-eta'),
          style: const TextStyle(
            color: HomeColors.secondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        if (mechanic.shop.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            mechanic.shop,
            style: const TextStyle(fontSize: 12, color: HomeColors.secondary),
          ),
        ],
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 8,
          children: [
            const Text(
              'Dịch vụ cứu hộ',
              style: TextStyle(color: HomeColors.secondary, fontSize: 13),
            ),
            Text(
              formatOrderPrice(order.totalPrice),
              key: const ValueKey('tracking-total'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final item in order.items)
          Text(
            '${item.name}${item.quantity > 1 ? ' × ${item.quantity}' : ''}',
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        if (order.items.isEmpty)
          Text(
            order.serviceOption.isNotEmpty
                ? order.serviceOption
                : order.serviceType.label,
            style: const TextStyle(fontSize: 13, height: 1.5),
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

class _TrackingMetric extends StatelessWidget {
  const _TrackingMetric({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: OrderTrackingColors.muted),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    ],
  );
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    icon: Icon(icon, size: 21),
    style: IconButton.styleFrom(
      foregroundColor: OrderTrackingColors.route,
      backgroundColor: OrderTrackingColors.actionTint,
      disabledForegroundColor: HomeColors.secondary,
      disabledBackgroundColor: const Color(0xFFF2F2F4),
      minimumSize: const Size(44, 44),
      shape: const CircleBorder(),
    ),
  );
}

class _MechanicAvatar extends StatelessWidget {
  const _MechanicAvatar({required this.initials, this.url});
  final String initials;
  final String? url;
  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox(
      width: 44,
      height: 44,
      child: url?.trim().isNotEmpty == true
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            )
          : _fallback(),
    ),
  );
  Widget _fallback() => ColoredBox(
    color: const Color(0xFFF0F0F2),
    child: Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: HomeColors.text,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
