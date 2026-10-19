import 'package:flutter/material.dart';

import '../models/order_details.dart';
import '../theme/order_details_theme.dart';

class OrderDetailsHeader extends StatelessWidget {
  const OrderDetailsHeader({
    super.key,
    required this.details,
    required this.onCopy,
  });
  final OrderDetails details;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(14) > 18;
      final statusColors = CustomerOrderTheme.statusColors(
        details.order.status,
      );
      final badge = Container(
        key: const ValueKey('order-details-status'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: statusColors.background,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          details.statusLabel,
          style: CustomerOrderTheme.text(
            color: statusColors.foreground,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: OrderDetailsTheme.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.two_wheeler_rounded,
                  color: OrderDetailsTheme.text,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mã đơn cứu hộ',
                      style: CustomerOrderTheme.text(
                        color: OrderDetailsTheme.muted,
                        fontSize: 11,
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            details.order.orderCode,
                            style: CustomerOrderTheme.text(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('order-details-copy'),
                          tooltip: 'Sao chép mã đơn',
                          onPressed: onCopy,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(44, 44),
                          ),
                          icon: const Icon(
                            Icons.copy_rounded,
                            color: OrderDetailsTheme.muted,
                            size: 17,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!compact) ...[const SizedBox(width: 4), badge],
            ],
          ),
          if (compact) ...[const SizedBox(height: 8), badge],
        ],
      );
    },
  );
}
