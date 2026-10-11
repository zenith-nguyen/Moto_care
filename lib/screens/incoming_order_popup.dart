import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/countdown_ring.dart';
import '../widgets/map_views.dart';
import '../widgets/ui.dart';
import 'order_received_screen.dart';

/// Mở popup offer toàn màn hình. Hoàn tất khi thợ từ chối, hết giờ, hoặc chấp nhận
/// (khi chấp nhận, popup được thay bằng màn "Đã nhận đơn").
Future<void> showIncomingOrder(BuildContext context, OrderOffer offer) {
  HapticFeedback.heavyImpact();
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => IncomingOrderPopup(offer: offer),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}

class IncomingOrderPopup extends StatefulWidget {
  const IncomingOrderPopup({super.key, required this.offer});

  final OrderOffer offer;

  static const Duration timeout = Duration(seconds: 15);

  @override
  State<IncomingOrderPopup> createState() => _IncomingOrderPopupState();
}

class _IncomingOrderPopupState extends State<IncomingOrderPopup> {
  bool _closed = false;

  void _decline({bool timedOut = false}) {
    if (_closed) return;
    _closed = true;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(timedOut
            ? 'Offer ${widget.offer.code} đã hết hạn. Đang tìm đơn khác cho bạn.'
            : 'Đã từ chối ${widget.offer.code}. Đang tìm đơn khác cho bạn.'),
      ));
  }

  void _accept() {
    if (_closed) return;
    _closed = true;
    final order = appState.acceptOffer(widget.offer);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OrderReceivedScreen(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _decline();
      },
      child: Scaffold(
        body: Column(
          children: [
            // Thanh đếm ngược phẳng trên cùng, chạy song song với vòng tròn.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: IncomingOrderPopup.timeout,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                color: AppColors.danger,
                backgroundColor: AppColors.surface,
              ),
            ),
            Expanded(
              child: SafeArea(
                top: true,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.bolt_outlined, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'ĐƠN KHẨN CẤP',
                                      style: appText(13.5,
                                          weight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.4),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              CountdownRing(
                                total: IncomingOrderPopup.timeout,
                                color: AppColors.danger,
                                size: 76,
                                strokeWidth: 6,
                                fontSize: 22,
                                labelBuilder: (r) => '${r.inSeconds}s',
                                onFinished: () => _decline(timedOut: true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text('Thu nhập nhận được', style: appText(15, color: AppColors.textSub)),
                          FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatVnd(offer.price),
                              style: appText(58,
                                  weight: FontWeight.w900, height: 1.1, letterSpacing: -1.5),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${offer.issue} — ${offer.vehicle}',
                            style: appText(18, weight: FontWeight.w800, height: 1.3),
                          ),
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: SizedBox(
                              height: 170,
                              child: Stack(
                                children: [
                                  const Positioned.fill(
                                    child: RouteMap(
                                      cell: 66,
                                      cornerRadius: 70,
                                      points: [
                                        Offset(0.09, 0.85),
                                        Offset(0.3, 0.8),
                                        Offset(0.42, 0.5),
                                        Offset(0.8, 0.5),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: AppColors.ink,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '${offer.distanceKm} km · ~${offer.etaMinutes} phút',
                                        style: appText(13.5,
                                            weight: FontWeight.w800, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(offer.address,
                                    style: appText(16.5, weight: FontWeight.w700)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const PhotoPlaceholder(width: 116, height: 84),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ảnh hiện trường',
                                        style: appText(16.5, weight: FontWeight.w800)),
                                    const SizedBox(height: 4),
                                    Text('Khách gửi lúc báo sự cố.',
                                        style: appText(14, color: AppColors.textSub)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '- ${formatVnd(offer.platformFee)} chiết khấu sàn',
                            style: appText(14, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: OutlineActionButton(label: 'Từ chối', onPressed: _decline),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: PrimaryButton(label: 'Chấp nhận đơn', onPressed: _accept),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
