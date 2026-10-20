import 'package:flutter/material.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/map_views.dart';
import '../widgets/ui.dart';
import '../widgets/order_identity.dart';
import '../widgets/app_status.dart';
import 'order_arrived_screen.dart';
import 'order_chat_screen.dart';
import 'order_in_progress_screen.dart';

void openActiveOrder(BuildContext context, ActiveOrder order) {
  final Widget screen = switch (order.step) {
    OrderStep.received ||
    OrderStep.navigating =>
      OrderReceivedScreen(order: order),
    OrderStep.arrived => OrderArrivedScreen(order: order),
    _ => OrderInProgressScreen(order: order),
  };
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

void openOrderChat(BuildContext context, ActiveOrder order) =>
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OrderChatScreen(
            orderId: order.orderId,
            customerName: order.offer.customerName,
            customerPhone: order.offer.customerPhone,
            messages: order.messages)));
void callCustomer(BuildContext context, String name, String phone) =>
    showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text('Liên hệ $name',
                    style: appText(18, weight: FontWeight.w700)),
                content: Text('$phone\n\nCuộc gọi mô phỏng trong bản demo.',
                    style: appText(14)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Đóng'))
                ]));
List<Widget> customerActions(BuildContext context, ActiveOrder order) => [
      RoundIconButton(
          icon: Icons.alt_route,
          tooltip: 'Chỉ đường',
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => OrderReceivedScreen(order: order)))),
      RoundIconButton(
          icon: Icons.call_outlined,
          tooltip: 'Gọi khách',
          onTap: () => callCustomer(
              context, order.offer.customerName, order.offer.customerPhone)),
      RoundIconButton(
          icon: Icons.chat_bubble_outline,
          tooltip: 'Nhắn khách',
          onTap: () => openOrderChat(context, order)),
    ];

class OrderReceivedScreen extends StatefulWidget {
  const OrderReceivedScreen({super.key, required this.order});
  final ActiveOrder order;
  @override
  State<OrderReceivedScreen> createState() => _OrderReceivedScreenState();
}

class _OrderReceivedScreenState extends State<OrderReceivedScreen> {
  final _transform = TransformationController();
  bool get _navigating => widget.order.step == OrderStep.navigating;
  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _details() => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
          child: Padding(
              padding: AppSpace.pageInsets,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OrderIdentityCard(offer: widget.order.offer),
                    const SizedBox(height: 10),
                    Text(widget.order.offer.address, style: AppTypography.body),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: OutlineActionButton(
                              label: 'Gọi khách',
                              icon: Icons.call_outlined,
                              onPressed: () => callCustomer(
                                  context,
                                  widget.order.offer.customerName,
                                  widget.order.offer.customerPhone))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: PrimaryButton(
                              label: 'Nhắn khách',
                              icon: Icons.chat_bubble_outline,
                              onPressed: () {
                                Navigator.pop(ctx);
                                openOrderChat(context, widget.order);
                              }))
                    ]),
                  ]))));
  void _advance() {
    try {
      if (!_navigating) {
        appState.beginNavigation(orderId: widget.order.orderId);
        return;
      }
      appState.markArrived(orderId: widget.order.orderId);
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => OrderArrivedScreen(order: widget.order)));
    } on StateError catch (e) {
      showAppSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final o = widget.order.offer;
        final canNavigate =
            widget.order.step == OrderStep.received || _navigating;
        return Scaffold(body: LayoutBuilder(builder: (context, c) {
          final panelHeight = (c.maxHeight * .32).clamp(205.0, 285.0) +
              MediaQuery.paddingOf(context).bottom;
          return Stack(fit: StackFit.expand, children: [
            Positioned.fill(
                child: InteractiveViewer(
                    transformationController: _transform,
                    minScale: 1,
                    maxScale: 3,
                    child: const RouteMap(cornerRadius: 12, points: [
                      Offset(.27, .60),
                      Offset(.27, .46),
                      Offset(.47, .46),
                      Offset(.47, .33),
                      Offset(.72, .33),
                    ]))),
            SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RoundIconButton(
                              icon: Icons.chevron_left_rounded,
                              tooltip: 'Quay lại',
                              white: true,
                              onTap: () => Navigator.pop(context)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                      color: AppColors.ink,
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.turn_right_rounded,
                                            color: Colors.white, size: 30),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                              Text(
                                                  _navigating
                                                      ? '60 m · Rẽ phải'
                                                      : 'Tuyến đường đến khách',
                                                  style: appText(15,
                                                      weight: FontWeight.w700,
                                                      color: Colors.white)),
                                              const SizedBox(height: 4),
                                              Text(
                                                  'Nguyễn Thị Minh Khai\nChỉ dẫn mô phỏng',
                                                  style: appText(10,
                                                      color: Colors.white)),
                                            ])),
                                      ]))),
                        ]))),
            if (!appState.networkAvailable || !appState.gpsEnabled)
              Positioned(
                  left: 16,
                  right: 16,
                  top: MediaQuery.paddingOf(context).top + 138,
                  child: AppStatusView(
                      kind: !appState.networkAvailable
                          ? AppStatusKind.offline
                          : AppStatusKind.gpsOff,
                      compact: true,
                      onAction: appState.demoEnabled
                          ? () {
                              appState.setNetworkAvailable(true);
                              appState.setGps(true);
                            }
                          : null)),
            Positioned(
                left: 16,
                bottom: panelHeight + 14,
                child: RoundIconButton(
                    icon: Icons.my_location_outlined,
                    tooltip: 'Về vị trí của tôi',
                    white: true,
                    onTap: () {
                      _transform.value = Matrix4.identity();
                      showAppSnack(
                          context, 'Đã căn giữa tuyến đường mô phỏng.');
                    })),
            Positioned(
                right: 16,
                bottom: panelHeight + 14,
                child: RoundIconButton(
                    icon: Icons.person_outline,
                    tooltip: 'Thông tin khách hàng',
                    white: true,
                    onTap: _details)),
            Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: panelHeight,
                child: Material(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.sheet)),
                    child: SafeArea(
                        top: false,
                        child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Center(child: SheetHandle()),
                                  const SizedBox(height: 4),
                                  Expanded(
                                      child: SingleChildScrollView(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                        Row(children: [
                                          Expanded(
                                              child: Text(
                                                  '${o.etaMinutes} phút · ${o.distanceKm} km',
                                                  style: AppTypography.title)),
                                          TextButton(
                                              onPressed: _details,
                                              child: const Text('Liên hệ'))
                                        ]),
                                        Text('${o.customerName} · ${o.code}',
                                            style: AppTypography.label),
                                        const SizedBox(height: 5),
                                        Text(o.address,
                                            style: AppTypography.caption),
                                        const SizedBox(height: 5),
                                        Text(
                                            'Bản đồ demo · Tuyến đường và ETA mô phỏng',
                                            style: appText(10,
                                                color: AppColors.primaryDeep)),
                                      ]))),
                                  const SizedBox(height: 10),
                                  PrimaryButton(
                                      label: !canNavigate
                                          ? 'Quay lại công việc'
                                          : _navigating
                                              ? 'Tôi đã đến nơi'
                                              : 'Bắt đầu dẫn đường',
                                      onPressed: !canNavigate
                                          ? () => Navigator.pop(context)
                                          : !appState.networkAvailable ||
                                                  !appState.gpsEnabled
                                              ? null
                                              : _advance),
                                ]))))),
          ]);
        }));
      });
}
