import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/services/activity_actions.dart';
import '../../home/theme/home_theme.dart';
import '../../partner/providers/partner_provider.dart';
import '../models/order_tracking_journey.dart';
import '../widgets/order_tracking_chat_sheet.dart';
import '../widgets/order_tracking_map.dart';
import '../widgets/order_tracking_status_card.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key, required this.orderId});
  final String? orderId;
  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  final _sheet = DraggableScrollableController();
  final _messages = <String>[];
  Timer? _timer;
  OrderTrackingJourney? _journey;
  int _step = 0;
  bool _foreground = true;
  bool _chatOpen = false;
  bool _cancelling = false;

  RescueOrder? get _order =>
      ref.read(activityProvider).orderById(widget.orderId);
  bool get _arrived =>
      _journey != null &&
      (_step >= _journey!.lastStep || _journey!.distanceKm < .001);
  bool get _canMove =>
      mounted &&
      _foreground &&
      !_chatOpen &&
      !_arrived &&
      _journey != null &&
      (_order?.status == RescueOrderStatus.pending ||
          _order?.status == RescueOrderStatus.enRoute) &&
      !MediaQuery.disableAnimationsOf(context) &&
      TickerMode.valuesOf(context).enabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadJourney();
  }

  void _loadJourney() {
    final order = _order;
    final shops = ref
        .read(partnerShopsProvider)
        .where((shop) => shop.id == order?.partnerId);
    _journey = order == null
        ? null
        : OrderTrackingJourney.fromOrder(
            order,
            shops.isEmpty ? null : shops.first,
          );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(OrderTrackingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      _stopMotion();
      _step = 0;
      _motion.value = 0;
      _messages.clear();
      _loadJourney();
      _syncMotion();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (mounted) _syncMotion();
  }

  void _stopMotion() {
    _timer?.cancel();
    _timer = null;
    _motion.stop();
  }

  void _syncMotion() {
    if (!_canMove) {
      _stopMotion();
      return;
    }
    if (_timer?.isActive == true) return;
    _motion.forward();
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!_canMove) {
        _stopMotion();
        return;
      }
      setState(() => _step++);
      if (_arrived) {
        _stopMotion();
      } else {
        _motion.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopMotion();
    _motion.dispose();
    _sheet.dispose();
    super.dispose();
  }

  Future<void> _call(RescueOrder order) async {
    if (order.providerPhone?.trim().isNotEmpty == true) {
      await ActivityActions.call(context, ref, order);
    } else {
      ActivityActions.feedback(
        context,
        'Thợ mô phỏng chưa có số điện thoại. Cuộc gọi sẽ khả dụng khi có thông tin thợ thực tế.',
      );
    }
  }

  Future<void> _chat(RescueOrder order) async {
    if (_chatOpen) return;
    setState(() => _chatOpen = true);
    _syncMotion();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => OrderTrackingChatSheet(
        mechanicName: order.hasProvider ? order.providerName! : 'Nguyễn Văn A',
        orderCode: order.orderCode,
        messages: _messages,
      ),
    );
    if (!mounted) return;
    setState(() => _chatOpen = false);
    _syncMotion();
  }

  Future<void> _cancel(RescueOrder order) async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    await ActivityActions.cancel(context, ref, order);
    if (!mounted) return;
    setState(() => _cancelling = false);
    _syncMotion();
  }

  void _back() => context.canPop() ? context.pop() : context.go('/hoat-dong');

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(activityProvider).orderById(widget.orderId);
    ref.listen(activityProvider, (_, next) {
      final status = next.orderById(widget.orderId)?.status;
      if (status != RescueOrderStatus.pending &&
          status != RescueOrderStatus.enRoute) {
        _stopMotion();
      }
    });
    return Theme(
      data: HomeTheme.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: BackButton(onPressed: _back),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Theo dõi đơn hàng',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              if (order != null)
                Text(
                  order.orderCode,
                  style: const TextStyle(
                    color: HomeColors.secondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          actions: [
            if (order != null)
              IconButton(
                tooltip: 'Chi tiết đơn hàng',
                onPressed: () => context.push(
                  '/chi-tiet-don-hang?id=${Uri.encodeComponent(order.id)}',
                ),
                icon: const Icon(Icons.receipt_long_outlined),
              ),
          ],
        ),
        body: order == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: HomeColors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text('Không tìm thấy đơn cứu hộ.'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/hoat-dong'),
                      child: const Text('Xem đơn hàng'),
                    ),
                  ],
                ),
              )
            : SafeArea(
                top: false,
                child: AnimatedBuilder(
                  animation: _motion,
                  builder: (context, _) => _trackingBody(context, order),
                ),
              ),
      ),
    );
  }

  Widget _trackingBody(BuildContext context, RescueOrder order) {
    final journey = _journey;
    final displayStep =
        journey != null &&
            (order.status == RescueOrderStatus.repairing ||
                order.status == RescueOrderStatus.completed)
        ? journey.lastStep
        : _step;
    final remaining = journey?.remainingKm(_step, _motion.value);
    final minutes = journey == null || journey.distanceKm == 0
        ? 0
        : math.max(1, (5 * (remaining ?? 0) / journey.distanceKm).ceil());
    final (heading, badge, subtitle) = switch (order.status) {
      RescueOrderStatus.cancelled => (
        'Đơn cứu hộ đã hủy',
        'ĐÃ HỦY',
        'Lộ trình đã dừng. Bạn có thể đặt một đơn mới.',
      ),
      RescueOrderStatus.completed => (
        'Cứu hộ đã hoàn tất',
        'HOÀN TẤT',
        'Cảm ơn bạn đã sử dụng MotoCare.',
      ),
      RescueOrderStatus.repairing => (
        'Thợ đang xử lý sự cố',
        'ĐANG SỬA',
        'Thợ đã đến và đang kiểm tra xe của bạn.',
      ),
      _ when journey == null => (
        'Đang chuẩn bị lộ trình',
        'CHỜ VỊ TRÍ',
        'Vị trí sự cố chưa có tọa độ để theo dõi.',
      ),
      _ when _arrived => (
        'Thợ đã đến vị trí của bạn',
        'ĐÃ ĐẾN',
        'Đã đến điểm SOS • 0.0 km',
      ),
      _ => (
        'Thợ đang trên đường đến',
        'ĐANG ĐẾN',
        'Dự kiến đến trong $minutes phút • ${remaining!.toStringAsFixed(1)} km',
      ),
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final initial = ((490 + (scale - 1) * 180) / constraints.maxHeight)
            .clamp(.5, .68);
        return Stack(
          children: [
            AnimatedBuilder(
              animation: _sheet,
              builder: (context, _) => Positioned(
                top: 0,
                left: 0,
                right: 0,
                height:
                    constraints.maxHeight *
                    (1 - (_sheet.isAttached ? _sheet.size : initial)),
                child: journey == null
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Chưa có tọa độ sự cố. Địa chỉ đơn hàng vẫn được giữ bên dưới.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ref.read(orderTrackingMapBuilderProvider)(
                        context,
                        OrderTrackingMapData(
                          customer: journey.customer,
                          mechanic: journey.positionAt(
                            displayStep,
                            _motion.value,
                          ),
                          route: journey.remainingRoute(
                            displayStep,
                            _motion.value,
                          ),
                          fullRoute: journey.points,
                        ),
                      ),
              ),
            ),
            DraggableScrollableSheet(
              key: const ValueKey('order-tracking-sheet'),
              controller: _sheet,
              initialChildSize: initial,
              minChildSize: .38,
              maxChildSize: .96,
              builder: (context, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  children: [
                    OrderTrackingStatusCard(
                      order: order,
                      heading: heading,
                      subtitle: subtitle,
                      badge: badge,
                      onCall: order.status.isActive ? () => _call(order) : null,
                      onChat: order.status.isActive ? () => _chat(order) : null,
                      onCancel: order.status.isActive && !_cancelling
                          ? () => _cancel(order)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
