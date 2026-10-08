import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common_widgets.dart';

/// Chip card đơn khẩn cấp gần đó (dùng trong ListView ngang ở Trang chủ).
class UrgentOrderChip extends StatelessWidget {
  const UrgentOrderChip({super.key, required this.order, required this.onTap});

  final OrderRequest order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 248,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const UrgentBadge(compact: true),
                const Spacer(),
                const Icon(Icons.near_me_outlined, size: 14, color: AppColors.textSub),
                const SizedBox(width: 4),
                Text(formatKm(order.distanceKm),
                    style: appText(12, weight: FontWeight.w600, color: AppColors.textSub)),
              ],
            ),
            const SizedBox(height: 10),
            Text(order.issue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: appText(14.5, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(order.vehicle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: appText(12.5, color: AppColors.textSub)),
            const Spacer(),
            Row(
              children: [
                Text(formatVnd(order.earning),
                    style: appText(16, weight: FontWeight.w800, color: AppColors.primary)),
                const Spacer(),
                Text('Xem đơn', style: appText(12, weight: FontWeight.w600, color: AppColors.textSub)),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textSub),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
