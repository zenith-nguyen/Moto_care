import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/map_views.dart';
import '../widgets/app_status.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import '../widgets/order_identity.dart';
import 'order_received_screen.dart';

Future<void> showIncomingOrder(
  BuildContext context,
  OrderOffer offer, {
  bool reconnecting = false,
}) async {
  HapticFeedback.mediumImpact();
  final accepted = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Đơn khẩn cấp',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) =>
        IncomingOrderPopup(offer: offer, startReconnecting: reconnecting),
    transitionBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
  if (accepted == true && context.mounted) {
    try {
      final order = appState.acceptOffer(offer);
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderReceivedScreen(order: order)),
      );
    } on StateError catch (error) {
      if (context.mounted) showAppSnack(context, error.message);
    }
  }
}

class IncomingOrderPopup extends StatefulWidget {
  const IncomingOrderPopup({
    super.key,
    required this.offer,
    this.startReconnecting = false,
  });
  final OrderOffer offer;
  final bool startReconnecting;
  static const timeout = Duration(seconds: 30);
  @override
  State<IncomingOrderPopup> createState() => _IncomingOrderPopupState();
}

class _IncomingOrderPopupState extends State<IncomingOrderPopup> {
  late final Timer _timer;
  int _seconds = 30;
  late bool _reconnecting = widget.startReconnecting;
  @override
  void initState() {
    super.initState();
    final expiry = widget.offer.expiresAt;
    if (expiry != null) {
      _seconds = (expiry.difference(DateTime.now()).inMilliseconds / 1000)
          .ceil()
          .clamp(0, 30);
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_reconnecting) {
        setState(() => _reconnecting = false);
        return;
      }
      if (_seconds > 0) setState(() => _seconds--);
      if (_seconds == 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final o = widget.offer;
        final expired = _seconds == 0 ||
            (o.expiresAt != null && !DateTime.now().isBefore(o.expiresAt!));
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Scaffold(
              backgroundColor: AppColors.mapBase,
              body: Stack(children: [
                const Positioned.fill(
                    child: RouteMap(points: [
                  Offset(.28, .65),
                  Offset(.28, .45),
                  Offset(.64, .45),
                  Offset(.64, .25)
                ])),
                Positioned.fill(
                    child: ColoredBox(
                        color: AppColors.ink.withValues(alpha: .06))),
                SafeArea(
                    child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.sizeOf(context).height * .88),
                          decoration: const BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(AppRadius.sheet)),
                              boxShadow: AppShadows.modal),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                child: Column(children: [
                                  Container(
                                      width: 36,
                                      height: 4,
                                      decoration: BoxDecoration(
                                          color: AppColors.border,
                                          borderRadius:
                                              BorderRadius.circular(9))),
                                  const SizedBox(height: 14),
                                  Row(children: [
                                    const Icon(Icons.emergency_share_outlined,
                                        color: AppColors.dangerDark, size: 22),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(
                                            expired
                                                ? 'Đơn đã hết hạn'
                                                : 'Đơn cứu hộ khẩn cấp',
                                            style: appText(17,
                                                weight: FontWeight.w700))),
                                    const SizedBox(width: 8),
                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                            color: AppColors.dangerSoft,
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.sm)),
                                        child: Text(
                                            '00:${(expired ? 0 : _seconds).toString().padLeft(2, '0')}',
                                            style: appText(20,
                                                weight: FontWeight.w700,
                                                color: AppColors.dangerDark))),
                                  ]),
                                  const SizedBox(height: 5),
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('${o.orderId} · Yêu cầu demo',
                                          style: AppTypography.caption)),
                                ])),
                            Flexible(
                                child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (_reconnecting ||
                                              !appState.networkAvailable)
                                            const Padding(
                                                padding:
                                                    EdgeInsets.only(bottom: 10),
                                                child: AppStatusView(
                                                    kind: AppStatusKind.offline,
                                                    compact: true)),
                                          SurfaceCard(
                                              child: Row(children: [
                                            AvatarCircle(
                                                initials:
                                                    initialsOf(o.customerName),
                                                size: 44,
                                                dark: false),
                                            const SizedBox(width: 12),
                                            Expanded(
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                  Text(o.customerName,
                                                      style:
                                                          AppTypography.label),
                                                  if (o.customerRating != null)
                                                    Text(
                                                        '★ ${o.customerRating}${o.customerRatingCount == null ? '' : ' (${o.customerRatingCount})'}',
                                                        style: AppTypography
                                                            .caption),
                                                  Text(
                                                      maskPhone(
                                                          o.customerPhone),
                                                      style: AppTypography
                                                          .caption),
                                                  Text(
                                                      'Liên hệ sau khi nhận đơn',
                                                      style: appText(11,
                                                          color: AppColors
                                                              .primary)),
                                                ])),
                                            if (o.customerVerified == true)
                                              const Icon(Icons.verified_rounded,
                                                  size: 20,
                                                  color: AppColors.successDark)
                                            else
                                              const Icon(
                                                  Icons.lock_outline_rounded,
                                                  size: 18,
                                                  color: AppColors.textSub),
                                          ])),
                                          const SizedBox(height: 10),
                                          SurfaceCard(
                                              child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                VehicleThumbnail(
                                                    vehicle: o.vehicle),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                    child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                      Text(
                                                          '${vehicleLabel(o.vehicle)} · ${o.vehicle}',
                                                          style: AppTypography
                                                              .label),
                                                      if (o.plate.isNotEmpty)
                                                        Text(o.plate,
                                                            style: AppTypography
                                                                .caption),
                                                      const SizedBox(height: 4),
                                                      Text(o.issue,
                                                          style: AppTypography
                                                              .label
                                                              .copyWith(
                                                                  color: AppColors
                                                                      .primaryDeep)),
                                                      Text(o.description,
                                                          style: appText(12,
                                                              color: AppColors
                                                                  .textSub),
                                                          maxLines: 3,
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ])),
                                              ])),
                                          const SizedBox(height: 10),
                                          SurfaceCard(
                                              child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                const Icon(
                                                    Icons.location_on_outlined),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                    child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                      Text(o.address,
                                                          style: appText(12,
                                                              weight: FontWeight
                                                                  .w500)),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                          '${o.distanceKm} km · ~${o.etaMinutes} phút (mô phỏng)',
                                                          style: AppTypography
                                                              .caption),
                                                    ])),
                                              ])),
                                          const SizedBox(height: 10),
                                          SurfaceCard(
                                              color: AppColors.surfaceSoft,
                                              child: Row(children: [
                                                Expanded(
                                                    child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                      const Text(
                                                          'Thu nhập dự kiến',
                                                          style: AppTypography
                                                              .caption),
                                                      Text(
                                                          formatVnd(o.price -
                                                              o.platformFee),
                                                          style: appText(24,
                                                              weight: FontWeight
                                                                  .w700,
                                                              color: AppColors
                                                                  .primaryDeep)),
                                                    ])),
                                                Flexible(
                                                    child: Text(
                                                        'Phí nền tảng\n${formatVnd(o.platformFee)}',
                                                        textAlign:
                                                            TextAlign.right,
                                                        style: AppTypography
                                                            .caption)),
                                              ])),
                                          if (expired)
                                            const Padding(
                                                padding:
                                                    EdgeInsets.only(top: 10),
                                                child: AppStatusView(
                                                    kind: AppStatusKind.expired,
                                                    compact: true)),
                                        ]))),
                            Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                child: expired
                                    ? PrimaryButton(
                                        label: 'Quay lại trang chủ',
                                        onPressed: () =>
                                            Navigator.pop(context, false))
                                    : Row(children: [
                                        Expanded(
                                            child: OutlineActionButton(
                                                label: 'Từ chối',
                                                onPressed: () => Navigator.pop(
                                                    context, false))),
                                        const SizedBox(width: 12),
                                        Expanded(
                                            child: PrimaryButton(
                                                label: 'Nhận đơn',
                                                onPressed: _reconnecting ||
                                                        !appState
                                                            .networkAvailable
                                                    ? null
                                                    : () => Navigator.pop(
                                                        context, true))),
                                      ])),
                          ]),
                        ))),
              ])),
        );
      });
}
