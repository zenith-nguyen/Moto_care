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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Về Trang chủ',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 104,
                        height: 104,
                        decoration:
                            const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 52),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Hoàn thành đơn',
                      textAlign: TextAlign.center,
                      style: appText(26, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.code} · ${item.issue}',
                      textAlign: TextAlign.center,
                      style: appText(15.5, color: AppColors.textSub),
                    ),
                    const SizedBox(height: 26),
                    SurfaceCard(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        children: [
                          Text('Giá cuối', style: appText(15, color: AppColors.textSub)),
                          const SizedBox(height: 4),
                          Text(
                            formatVnd(item.finalPrice),
                            style: appText(40, weight: FontWeight.w900, letterSpacing: -1),
                          ),
                          const Divider(height: 30),
                          Row(
                            children: [
                              Expanded(
                                child: Text('Trạng thái thanh toán',
                                    style: appText(15, color: AppColors.textSub)),
                              ),
                              const StatusBadge.success('Đã thanh toán', icon: Icons.check),
                            ],
                          ),
                          const SizedBox(height: 8),
                          KeyValueRow(
                            'Đã cộng vào Ví của bạn',
                            '+${formatVnd(item.earning)}',
                            valueStyle:
                                appText(17, weight: FontWeight.w900, color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
      ),
    );
  }
}
