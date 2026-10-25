import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/services/activity_actions.dart';
import '../../chat/services/chat_service.dart';
import '../../home/theme/home_theme.dart';
import '../providers/order_tracking_provider.dart';
import '../providers/tracking_chat_provider.dart';
import '../services/order_tracking_service.dart';
import '../widgets/order_tracking_chat_sheet.dart';
import '../widgets/order_tracking_header.dart';
import '../widgets/order_tracking_map.dart';
import '../widgets/order_tracking_status_card.dart';
import '../widgets/service_start_code_card.dart';

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
  Timer? _runtimeRefresh;
  TrackingKey get _key => (_screenKey, widget.orderId);
  OrderTrackingController get _controller =>
      ref.read(orderTrackingProvider(_key).notifier);
  bool _foreground = true;
  bool _chatOpen = false;
  bool _cancelling = false;
  bool _redirectingToPayment = false;
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
    if (ref.read(runtimeApiIntegrationProvider) && _runtimeRefresh == null) {
      _runtimeRefresh = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted && _foreground && !_chatOpen) {
          ref.read(activityProvider.notifier).refreshFromApi();
        }
      });
    }
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
    _runtimeRefresh?.cancel();
    _sheet.dispose();
    super.dispose();
  }

  Future<void> _call(TrackingSnapshot snapshot) async {
    final phone = snapshot.mechanic.phoneNumber?.trim();
    if (phone != null && phone.isNotEmpty) {
      final opened = await ref
          .read(chatServiceProvider)
          .call(phone, launcher: ref.read(activityUrlLauncherProvider));
      if (mounted && !opened) {
        ActivityActions.feedback(
          context,
          'Không thể mở ứng dụng gọi điện. Số thợ: $phone',
        );
      }
    } else {
      ActivityActions.feedback(
        context,
        snapshot.isSimulated
            ? 'Thợ mô phỏng chưa có số điện thoại. Cuộc gọi sẽ khả dụng khi có thông tin thợ thực tế.'
            : 'Thợ chưa cập nhật số điện thoại.',
      );
    }
  }

  Future<void> _chat(RescueOrder order, TrackingSnapshot snapshot) async {
    if (_chatOpen) return;
    setState(() => _chatOpen = true);
    _syncMotion();
    if (order.hasProvider || !snapshot.isSimulated) {
      await context.push(
        '/chat-detail',
        extra: ref
            .read(orderTrackingServiceProvider)
            .conversation(order, snapshot),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        builder: (context) => OrderTrackingChatSheet(
          mechanicName: snapshot.mechanic.name,
          orderCode: order.orderCode,
          sessionKey: _key,
        ),
      );
    }
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
    if (order?.awaitingPrepayment == true) {
      if (!_redirectingToPayment) {
        _redirectingToPayment = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/bank-transfer?id=${order!.id}');
        });
      }
      return Theme(
        data: HomeTheme.light,
        child: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    ref.watch(orderTrackingProvider(_key));
    ref.watch(trackingChatProvider(_key));
    ref.watch(trackingMechanicProvider);
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
        body: order == null
            ? Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          color: HomeColors.text,
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
                  ),
                  OrderTrackingHeader(onBack: _back),
                ],
              )
            : AnimatedBuilder(
                animation: _motion,
                builder: (context, _) => _trackingBody(context, order),
              ),
      ),
    );
  }

  Widget _trackingBody(BuildContext context, RescueOrder order) {
    final runtimeIntegration = ref.watch(runtimeApiIntegrationProvider);
    final state = ref.read(orderTrackingProvider(_key));
    final snapshot = ref
        .read(orderTrackingServiceProvider)
        .snapshot(
          order,
          state.journey,
          state.step,
          _motion.value,
          liveMode: state.liveMode,
          update: state.update,
          feedError: state.feedError,
          fallbackMechanic: ref.read(trackingMechanicProvider),
        );
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final safe = MediaQuery.paddingOf(context);
        final initial =
            ((282 + (scale - 1) * 220 + safe.bottom) / constraints.maxHeight)
                .clamp(.32, .64);
        return Stack(
          children: [
            Positioned.fill(
              key: const ValueKey('tracking-map-layer'),
              child: AnimatedBuilder(
                animation: _sheet,
                builder: (context, _) {
                  final route = snapshot.map;
                  if (route == null) {
                    return Align(
                      alignment: const Alignment(0, -.45),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: const Text(
                          'Chưa có tọa độ sự cố. Địa chỉ đơn hàng vẫn được giữ bên dưới.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  // Map stays full size; padding keeps markers and attribution above the card.
                  final bottom =
                      constraints.maxHeight *
                      (_sheet.isAttached ? _sheet.size : initial);
                  return ref.read(orderTrackingMapBuilderProvider)(
                    context,
                    OrderTrackingMapData(
                      customer: route.customer,
                      mechanic: route.mechanic,
                      route: route.points,
                      fullRoute: route.fullRoute,
                      isSimulated: snapshot.isSimulated,
                      padding: EdgeInsets.only(
                        top: safe.top + 78,
                        bottom: bottom + 12,
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xEFFFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
                child: OrderTrackingHeader(
                  onBack: _back,
                  onDetails: () => context.push(
                    '/order-details?id=${Uri.encodeComponent(order.id)}',
                  ),
                ),
              ),
            ),
            DraggableScrollableSheet(
              key: const ValueKey('order-tracking-sheet'),
              controller: _sheet,
              initialChildSize: initial,
              minChildSize: initial,
              maxChildSize: .94,
              builder: (context, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x16000000),
                      blurRadius: 24,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + safe.bottom),
                  children: [
                    OrderTrackingStatusCard(
                      order: order,
                      snapshot: snapshot,
                      onCall:
                          order.status.isActive &&
                              (runtimeIntegration
                                  ? order.hasProvider
                                  : snapshot.isSimulated ||
                                        state.update != null ||
                                        order.hasProvider)
                          ? () => _call(snapshot)
                          : null,
                      onChat:
                          order.status.isActive &&
                              (runtimeIntegration
                                  ? order.hasProvider
                                  : snapshot.isSimulated ||
                                        state.update != null ||
                                        order.hasProvider)
                          ? () => _chat(order, snapshot)
                          : null,
                      onCancel: order.status.isActive && !_cancelling
                          ? () => _cancel(order)
                          : null,
                    ),
                    if (runtimeIntegration &&
                        order.hasProvider &&
                        order.status == RescueOrderStatus.enRoute &&
                        int.tryParse(order.id) != null)
                      ServiceStartCodeCard(orderId: int.parse(order.id)),
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
