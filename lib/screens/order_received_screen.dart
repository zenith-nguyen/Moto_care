import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/map_views.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/ui.dart';
import 'order_arrived_screen.dart';
import 'order_chat_screen.dart';
import 'order_in_progress_screen.dart';

/// Mở lại đơn đang thực hiện đúng ở bước hiện tại (từ Trang chủ / Lịch sử đơn).
void openActiveOrder(BuildContext context, ActiveOrder order) {
  final Widget screen = switch (order.step) {
    OrderStep.received => OrderReceivedScreen(order: order),
    OrderStep.arrived => OrderArrivedScreen(order: order),
    _ => OrderInProgressScreen(order: order),
  };
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

void openOrderChat(BuildContext context, ActiveOrder order) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => OrderChatScreen(
        customerName: order.offer.customerName,
        customerPhone: order.offer.customerPhone,
        messages: order.messages,
      ),
    ),
  );
}

void callCustomer(BuildContext context, String name, String phone) =>
    showAppSnack(context, 'Đang gọi $name (${maskPhone(phone)})...');

/// Bước 1/5: Đã nhận đơn — đang di chuyển tới khách.
class OrderReceivedScreen extends StatelessWidget {
  const OrderReceivedScreen({super.key, required this.order});

  final ActiveOrder order;

  @override
  Widget build(BuildContext context) {
    final offer = order.offer;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: RouteMap(
              cell: 160,
              road: 18,
              markerAtEnd: false,
              points: [
                Offset(0.09, 0.62),
                Offset(0.09, 0.46),
                Offset(0.5, 0.46),
                Offset(0.5, 0.2),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        shadowColor: Colors.black26,
                        child: IconButton(
                          tooltip: 'Về Trang chủ',
                          iconSize: 26,
                          padding: const EdgeInsets.all(12),
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            boxShadow: AppShadows.soft,
                          ),
                          child: Row(
                            children: [
                              Text(offer.code, style: appText(16, weight: FontWeight.w900)),
                              Container(
                                width: 1,
                                height: 22,
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                                color: AppColors.border,
                              ),
                              Expanded(
                                child: Text(
                                  'Còn ${offer.distanceKm} km · ~${offer.etaMinutes} phút',
                                  overflow: TextOverflow.ellipsis,
                                  style: appText(15,
                                      weight: FontWeight.w600, color: AppColors.textSub),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconCircle(icon: offer.service.icon, size: 38),
                            const SizedBox(width: 12),
                            Expanded(
                              child:
                                  Text(offer.issue, style: appText(15.5, weight: FontWeight.w800)),
                            ),
                          ],
                        ),
                        const Divider(height: 26),
                        Row(
                          children: [
                            const IconCircle(icon: Icons.person_outline, size: 52),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    offer.customerName,
                                    maxLines: 2,
                                    style: appText(17, weight: FontWeight.w800, height: 1.2),
                                  ),
                                  Text(
                                    '${offer.vehicle} · ${offer.plate}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: appText(13.5, color: AppColors.textSub),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            RoundIconButton(
                              icon: Icons.near_me_outlined,
                              tooltip: 'Chỉ đường',
                              onTap: () =>
                                  showAppSnack(context, 'Mở chỉ đường tới ${offer.address}'),
                            ),
                            const SizedBox(width: 8),
                            RoundIconButton(
                              icon: Icons.call_outlined,
                              tooltip: 'Gọi khách',
                              filled: true,
                              onTap: () =>
                                  callCustomer(context, offer.customerName, offer.customerPhone),
                            ),
                            const SizedBox(width: 8),
                            RoundIconButton(
                              icon: Icons.chat_bubble_outline,
                              tooltip: 'Nhắn khách',
                              onTap: () => openOrderChat(context, order),
                            ),
                          ],
                        ),
                        const Divider(height: 26),
                        KeyValueRow(
                          'Giá tạm tính',
                          formatVnd(offer.price),
                          valueStyle: appText(18, weight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                boxShadow: [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -4))
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StepProgressBar(
                      title: orderStepLabels[0],
                      current: 1,
                      steps: orderStepLabels,
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Tôi đã đến nơi',
                      onPressed: () {
                        appState.markArrived();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => OrderArrivedScreen(order: order)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
