import 'package:flutter/material.dart';

import '../models/order_details.dart';
import '../theme/order_details_theme.dart';

class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.entries});
  final List<OrderTimelineEntry> entries;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: CustomerOrderTheme.cardDecoration,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhật ký trạng thái',
          style: CustomerOrderTheme.text(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < entries.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: MediaQuery.textScalerOf(context).scale(12) > 16
                      ? 94
                      : 76,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entries[i].time,
                        style: CustomerOrderTheme.text(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entries[i].date,
                        style: CustomerOrderTheme.text(
                          fontSize: 9,
                          color: OrderDetailsTheme.muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 18,
                  child: Column(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Icon(
                          entries[i].isCancelled
                              ? Icons.cancel
                              : Icons.check_circle,
                          size: 18,
                          color: OrderDetailsTheme.text,
                        ),
                      ),
                      if (i < entries.length - 1)
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 1.5,
                              color: OrderDetailsTheme.text,
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
                      bottom: i == entries.length - 1 ? 0 : 24,
                    ),
                    child: Text(
                      entries[i].description,
                      style: CustomerOrderTheme.text(
                        fontSize: 12,
                        height: 1.65,
                      ),
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
