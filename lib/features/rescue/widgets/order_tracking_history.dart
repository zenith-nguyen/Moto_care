import 'package:flutter/material.dart';

import '../../activity/models/order_details.dart';
import '../theme/order_tracking_theme.dart';

/// Uses confirmed order events, including their existing unknown-time labels.
class OrderTrackingHistory extends StatelessWidget {
  const OrderTrackingHistory({
    super.key,
    required this.entries,
    required this.address,
    required this.onViewAll,
  });

  final List<OrderTimelineEntry> entries;
  final String address;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Lịch sử lộ trình',
              style: CustomerOrderTheme.text(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            key: const ValueKey('tracking-view-history'),
            onPressed: onViewAll,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              side: const BorderSide(color: CustomerOrderTheme.line),
              shape: const StadiumBorder(),
            ),
            child: Text(
              'Xem tất cả',
              style: CustomerOrderTheme.text(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: OrderTrackingColors.muted,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      for (var i = 0; i < entries.length; i++)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 16,
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: entries[i].isCurrent
                            ? const Color(0xFFF59E0B)
                            : OrderTrackingColors.route,
                        boxShadow: [
                          BoxShadow(
                            color: entries[i].isCurrent
                                ? const Color(0x26F59E0B)
                                : OrderTrackingColors.routeHalo,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    if (i < entries.length - 1)
                      Expanded(
                        child: SizedBox(
                          width: 2,
                          child: CustomPaint(
                            painter: _HistoryConnector(
                              dashed: entries[i].isCurrent,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: i == entries.length - 1 ? 0 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entries[i].description,
                        style: CustomerOrderTheme.text(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        address,
                        style: CustomerOrderTheme.text(
                          fontSize: 11,
                          color: OrderTrackingColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: MediaQuery.textScalerOf(context).scale(12) > 16
                    ? 78
                    : 64,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      entries[i].time,
                      style: CustomerOrderTheme.text(
                        fontSize: 12,
                        color: OrderTrackingColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entries[i].date,
                      textAlign: TextAlign.end,
                      style: CustomerOrderTheme.text(
                        fontSize: 10,
                        color: OrderTrackingColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _HistoryConnector extends CustomPainter {
  const _HistoryConnector({required this.dashed});
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = OrderTrackingColors.route.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    if (dashed) {
      for (var y = 3.0; y < size.height; y += 8) {
        canvas.drawLine(
          Offset(size.width / 2, y),
          Offset(size.width / 2, (y + 4).clamp(0, size.height)),
          paint,
        );
      }
    } else {
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HistoryConnector oldDelegate) =>
      dashed != oldDelegate.dashed;
}
