import 'package:flutter/material.dart';

import '../../activity/models/order_details.dart';
import '../../activity/models/rescue_order.dart';
import '../models/tracking_mechanic.dart';
import '../models/tracking_snapshot.dart';
import '../theme/order_tracking_theme.dart';

class TrackingOrderHeader extends StatelessWidget {
  const TrackingOrderHeader({
    super.key,
    required this.order,
    required this.onCopy,
  });

  final RescueOrder order;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          color: Color(0xFFE0F2FE),
          shape: BoxShape.circle,
        ),
        child: Icon(
          switch (order.serviceType) {
            RescueServiceType.towing => Icons.local_shipping_rounded,
            RescueServiceType.batteryJump =>
              Icons.battery_charging_full_rounded,
            _ => Icons.two_wheeler_rounded,
          },
          color: OrderTrackingColors.route,
          size: 25,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mã đơn: #${order.orderCode.replaceFirst(RegExp(r'^#'), '')}',
              key: const ValueKey('tracking-order-code'),
              style: CustomerOrderTheme.text(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: OrderTrackingColors.muted,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              order.serviceType.label,
              style: CustomerOrderTheme.text(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        key: const ValueKey('tracking-copy'),
        tooltip: 'Sao chép mã đơn',
        onPressed: onCopy,
        style: IconButton.styleFrom(
          foregroundColor: CustomerOrderTheme.navy,
          backgroundColor: CustomerOrderTheme.background,
          minimumSize: const Size(44, 44),
          shape: const CircleBorder(),
        ),
        icon: const Icon(Icons.copy_rounded, size: 19),
      ),
    ],
  );
}

class TrackingOverviewCard extends StatelessWidget {
  const TrackingOverviewCard({
    super.key,
    required this.details,
    required this.snapshot,
  });

  final OrderDetails details;
  final TrackingSnapshot snapshot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: CustomerOrderTheme.background,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _OverviewValue(
            label: 'Vị trí sự cố',
            value: details.order.locationAddress,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OverviewValue(
            label: 'Khách hàng',
            value: details.requesterName,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trạng thái',
                style: CustomerOrderTheme.text(
                  fontSize: 11,
                  color: OrderTrackingColors.muted,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                key: const ValueKey('tracking-status'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: OrderTrackingColors.statusBlue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  snapshot.statusLabel,
                  style: CustomerOrderTheme.text(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _OverviewValue extends StatelessWidget {
  const _OverviewValue({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: CustomerOrderTheme.text(
          fontSize: 11,
          color: OrderTrackingColors.muted,
        ),
      ),
      const SizedBox(height: 7),
      Tooltip(
        message: value,
        child: Text(
          value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: CustomerOrderTheme.text(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class TrackingMechanicCard extends StatelessWidget {
  const TrackingMechanicCard({
    super.key,
    required this.mechanic,
    required this.onCall,
    required this.onChat,
  });

  final TrackingMechanic mechanic;
  final VoidCallback? onCall, onChat;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: CustomerOrderTheme.line),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 290 ||
            MediaQuery.textScalerOf(context).scale(13) > 17;
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ContactButton(
              key: const ValueKey('tracking-chat'),
              label: 'Nhắn tin',
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: onChat,
              secondary: true,
            ),
            const SizedBox(width: 8),
            _ContactButton(
              key: const ValueKey('tracking-call'),
              label: 'Gọi điện',
              icon: Icons.phone,
              onPressed: onCall,
            ),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _MechanicAvatar(mechanic: mechanic),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thợ cứu hộ',
                        style: CustomerOrderTheme.text(
                          fontSize: 11,
                          color: OrderTrackingColors.muted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        mechanic.name,
                        style: CustomerOrderTheme.text(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mechanic.plate,
                        style: CustomerOrderTheme.text(
                          fontSize: 11,
                          color: OrderTrackingColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!compact) ...[const SizedBox(width: 8), actions],
              ],
            ),
            if (compact) ...[
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          ],
        );
      },
    ),
  );
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.secondary = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    icon: Icon(icon, size: 21),
    style: IconButton.styleFrom(
      foregroundColor: secondary ? CustomerOrderTheme.navy : Colors.white,
      backgroundColor: secondary
          ? CustomerOrderTheme.background
          : CustomerOrderTheme.navy,
      disabledForegroundColor: OrderTrackingColors.muted,
      disabledBackgroundColor: CustomerOrderTheme.line,
      minimumSize: const Size(44, 44),
      shape: const CircleBorder(),
    ),
  );
}

class _MechanicAvatar extends StatelessWidget {
  const _MechanicAvatar({required this.mechanic});
  final TrackingMechanic mechanic;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox(
      width: 48,
      height: 48,
      child: mechanic.avatarUrl?.trim().isNotEmpty == true
          ? Image.network(
              mechanic.avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            )
          : _fallback(),
    ),
  );

  Widget _fallback() => ColoredBox(
    color: OrderTrackingColors.avatarTint,
    child: Center(
      child: Text(
        mechanic.initials,
        style: CustomerOrderTheme.text(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
