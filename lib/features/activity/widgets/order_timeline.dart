import 'package:flutter/material.dart';

import '../models/order_details.dart';
import '../theme/order_details_theme.dart';

class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.entries});
  final List<OrderTimelineEntry> entries;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: OrderDetailsTheme.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nhật ký trạng thái',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entries[i].date,
                        style: const TextStyle(
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
                          color: entries[i].isCurrent
                              ? OrderDetailsTheme.red
                              : OrderDetailsTheme.text,
                        ),
                        child: Icon(
                          entries[i].isCancelled
                              ? Icons.close_rounded
                              : Icons.check_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      if (i < entries.length - 1)
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 1.5,
                              color: OrderDetailsTheme.line,
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
                      style: const TextStyle(fontSize: 12, height: 1.65),
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
