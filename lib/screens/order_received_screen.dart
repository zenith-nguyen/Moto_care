import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/map_views.dart';
import '../widgets/order_widgets.dart';
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

/// 3 nút hành động với khách: chỉ đường, gọi, nhắn tin (nền xám nhạt).
List<Widget> customerActions(BuildContext context, ActiveOrder order) {
  final offer = order.offer;
  return [
    RoundIconButton(
      icon: Icons.alt_route,
      tooltip: 'Chỉ đường',
      onTap: () => showAppSnack(context, 'Mở chỉ đường tới ${offer.address}'),
    ),
    RoundIconButton(
      icon: Icons.call_outlined,
      tooltip: 'Gọi khách',
      onTap: () => callCustomer(context, offer.customerName, offer.customerPhone),
    ),
    RoundIconButton(
      icon: Icons.chat_bubble_outline,
      tooltip: 'Nhắn khách',
      onTap: () => openOrderChat(context, order),
    ),
  ];
}

/// Bước 1/5: Đã nhận đơn — đang di chuyển tới khách.
class OrderReceivedScreen extends StatelessWidget {
  const OrderReceivedScreen({super.key, required this.order});

  final ActiveOrder order;

  @override
  Widget build(BuildContext context) {
    final offer = order.offer;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Đơn ${offer.code}',
              trailing: StatusBadge.pending('${offer.etaMinutes} phút', icon: Icons.schedule),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                children: [
                  const StepProgressBar(current: 1, steps: orderStepLabels),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: SizedBox(
                      height: 230,
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: RouteMap(
                              cornerRadius: 64,
                              points: [Offset(0.14, 0.78), Offset(0.4, 0.58), Offset(0.78, 0.36)],
                            ),
                          ),
                          Positioned(
                            left: 14,
                            bottom: 14,
                            child: MapChip(
                              icon: Icons.alt_route,
                              label: '${offer.distanceKm} km • ${offer.etaMinutes} phút',
                            ),
                          ),
                          Positioned(
                            right: 14,
                            top: 14,
                            child: RoundIconButton(
                              icon: Icons.navigation_outlined,
                              tooltip: 'Chỉ đường',
                              white: true,
                              onTap: () =>
                                  showAppSnack(context, 'Mở chỉ đường tới ${offer.address}'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SurfaceCard(
                    radius: AppRadius.md,
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_outlined, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(offer.issue, style: appText(17, weight: FontWeight.w600)),
                        ),
                        Text(formatVnd(offer.price), style: appText(17, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomerCard(
                    name: offer.customerName,
                    subtitle: '${offer.vehicle} · ${offer.plate}',
                    actions: customerActions(context, order),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(
                label: 'Tôi đã đến nơi',
                onPressed: () {
                  appState.markArrived();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => OrderArrivedScreen(order: order)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
