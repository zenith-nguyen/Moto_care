import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'order_history_detail_screen.dart';

/// Bước 5/5: Hoàn thành đơn — giá cuối, trạng thái thanh toán, tiền cộng vào ví.
class OrderCompletedScreen extends StatelessWidget {
  const OrderCompletedScreen({super.key, required this.item});

  final OrderHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Hoàn thành đơn',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                children: [
                  const Center(
                    child: IconCircle(
                      icon: Icons.check,
                      size: 112,
                      background: AppColors.successSoft,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Hoàn thành đơn ${item.code}',
                    textAlign: TextAlign.center,
                    style: appText(23, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.issue} · ${item.vehicle}',
                    textAlign: TextAlign.center,
                    style: appText(15, color: AppColors.textSub),
                  ),
                  const SizedBox(height: 26),
                  ShadowCard(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Giá cuối',
                                style:
                                    appText(15, weight: FontWeight.w500, color: AppColors.textSub),
                              ),
                            ),
                            const StatusBadge.success('Đã thanh toán'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatVnd(item.finalPrice),
                          style: appText(34, weight: FontWeight.w700, letterSpacing: -0.5),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Đã cộng vào Ví',
                                style: appText(15, color: AppColors.textSub),
                              ),
                            ),
                            Text(
                              formatSignedVnd(item.earning, plus: true),
                              style:
                                  appText(16.5, weight: FontWeight.w700, color: AppColors.success),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Đánh giá khách',
                    onPressed: () => showRateCustomerSheet(context, item),
                  ),
                  const SizedBox(height: 12),
                  OutlineActionButton(
                    label: 'Xem chi tiết đơn',
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => OrderHistoryDetailScreen(item: item)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
