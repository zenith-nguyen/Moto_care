import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/services/activity_actions.dart';
import '../../home/theme/home_theme.dart';
import '../providers/order_tracking_provider.dart';
import '../providers/tracking_chat_provider.dart';
import '../services/order_tracking_service.dart';
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
    duration: trackingInterval,
  );
  final _sheet = DraggableScrollableController();
  final _screenKey = Object();
  TrackingKey get _key => (_screenKey, widget.orderId);
  OrderTrackingController get _controller =>
      ref.read(orderTrackingProvider(_key).notifier);
  bool _foreground = true;
  bool _chatOpen = false;
  bool _cancelling = false;
  bool get _canMove =>
      mounted &&
      _foreground &&
      !_chatOpen &&
      !MediaQuery.disableAnimationsOf(context) &&
      TickerMode.valuesOf(context).enabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncMotion();
    });
  }

  @override
  void didUpdateWidget(OrderTrackingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      _stopMotion();
      _motion.value = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncMotion();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (mounted) _syncMotion();
  }

  void _stopMotion() {
    _motion.stop();
  }

  void _syncMotion() {
    _controller.setEnabled(_canMove);
    if (!_canMove || !_controller.canMove) {
      _stopMotion();
      return;
    }
    _motion.forward();
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
        mechanicName: order.hasProvider
            ? order.providerName!
            : ref.read(trackingMechanicProvider).name,
        orderCode: order.orderCode,
        sessionKey: _key,
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
    ref.watch(orderTrackingProvider(_key));
    ref.watch(trackingChatProvider(_key));
    ref.listen(orderTrackingProvider(_key), (previous, next) {
      if (previous?.step != next.step) {
        if (next.arrived) {
          _motion.stop();
        } else {
          _motion.forward(from: 0);
        }
      }
    });
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
    final state = ref.read(orderTrackingProvider(_key));
    final journey = state.journey;
    final snapshot = ref
        .read(orderTrackingServiceProvider)
        .snapshot(order, journey, state.step, _motion.value);
    final displayStep = snapshot.displayStep;
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
                      heading: snapshot.heading,
                      subtitle: snapshot.subtitle,
                      badge: snapshot.badge,
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
