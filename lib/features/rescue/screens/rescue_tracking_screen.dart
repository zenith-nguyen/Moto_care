import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/services/activity_actions.dart';
import '../../home/theme/home_theme.dart';
import '../../partner/widgets/marketplace_widgets.dart';

class RescueTrackingScreen extends ConsumerWidget {
  const RescueTrackingScreen({super.key, required this.orderId});
  final String? orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(activityProvider).orderById(orderId);
    if (order == null) {
      return MarketplaceScaffold(
        title: 'Theo dõi cứu hộ',
        onBack: () => context.go('/trang-chu'),
        body: const Center(child: Text('Không tìm thấy đơn cứu hộ.')),
      );
    }
    final heading = switch (order.status) {
      RescueOrderStatus.pending => 'Đang chờ tiệm xác nhận',
      RescueOrderStatus.enRoute => 'Thợ đang đến vị trí của bạn',
      RescueOrderStatus.repairing => 'Thợ đang xử lý sự cố',
      RescueOrderStatus.completed => 'Cứu hộ đã hoàn tất',
      RescueOrderStatus.cancelled => 'Đơn cứu hộ đã hủy',
    };
    return MarketplaceScaffold(
      title: 'Theo dõi cứu hộ',
      onBack: () => context.go('/trang-chu'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),
          if (order.status == RescueOrderStatus.pending)
            const _RescueRadar()
          else
            Icon(
              order.status == RescueOrderStatus.completed
                  ? Icons.check_circle_outline
                  : Icons.two_wheeler,
              color: HomeColors.red,
              size: 100,
            ),
          const SizedBox(height: 28),
          Text(
            heading,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            order.partnerName ?? 'MotoCare',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            order.orderCode,
            textAlign: TextAlign.center,
            style: const TextStyle(color: HomeColors.secondary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Đơn trong phiên trải nghiệm. Chưa có thợ được điều phối và chưa phát sinh thanh toán.',
            textAlign: TextAlign.center,
            style: TextStyle(color: HomeColors.secondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.location_on, color: HomeColors.red),
            title: Text(order.locationAddress),
            subtitle: Text(
              order.incidentDescription.isEmpty
                  ? 'Địa điểm cứu hộ của bạn'
                  : order.incidentDescription,
            ),
          ),
          for (final item in order.items)
            ListTile(
              title: Text(item.name),
              trailing: Text('× ${item.quantity}'),
            ),
          if (order.hasProvider) ...[
            ListTile(
              leading: const Icon(Icons.person, color: HomeColors.red),
              title: Text(order.providerName!),
              subtitle: Text(order.status.label),
            ),
            TextButton.icon(
              onPressed: () => ActivityActions.call(context, ref, order),
              icon: const Icon(Icons.call),
              label: const Text('Gọi thợ'),
            ),
          ],
          OutlinedButton(
            onPressed: () => context.push(
              '/chi-tiet-don-hang?id=${Uri.encodeComponent(order.id)}',
            ),
            child: const Text('Xem chi tiết đơn'),
          ),
          if (order.status.isActive)
            TextButton(
              onPressed: () => ActivityActions.cancel(context, ref, order),
              child: const Text('Hủy đơn cứu hộ'),
            ),
        ],
      ),
      bottomBar: FilledButton(
        onPressed: () => context.go('/trang-chu'),
        child: const Text('VỀ TRANG CHỦ'),
      ),
    );
  }
}

class _RescueRadar extends StatefulWidget {
  const _RescueRadar();
  @override
  State<_RescueRadar> createState() => _RescueRadarState();
}

class _RescueRadarState extends State<_RescueRadar>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );
  @override
  void initState() {
    super.initState();
    _animation.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
    } else if (!_animation.isAnimating) {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Đang chờ xác nhận cứu hộ',
    child: SizedBox(
      height: 210,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            for (var index = 0; index < 3; index++)
              Container(
                width: 90 + ((_animation.value + index / 3) % 1) * 120,
                height: 90 + ((_animation.value + index / 3) % 1) * 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: HomeColors.red.withValues(
                      alpha: 0.35 * (1 - ((_animation.value + index / 3) % 1)),
                    ),
                    width: 2,
                  ),
                ),
              ),
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: HomeColors.redSelected,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.two_wheeler,
                size: 44,
                color: HomeColors.red,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
