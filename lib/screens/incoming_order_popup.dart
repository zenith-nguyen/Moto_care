import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/countdown_ring.dart';
import '../widgets/map_views.dart';
import '../widgets/order_widgets.dart';
import '../widgets/ui.dart';
import 'order_received_screen.dart';

/// Mở popup offer dạng bottom sheet. Hoàn tất khi thợ từ chối, đóng sau khi hết giờ,
/// hoặc chấp nhận (khi chấp nhận, popup được thay bằng màn "Đã nhận đơn").
/// [reconnecting]: mô phỏng mất kết nối tạm thời — hiện trạng thái tải lại trước khi hiện đơn.
Future<void> showIncomingOrder(
  BuildContext context,
  OrderOffer offer, {
  bool reconnecting = false,
}) {
  HapticFeedback.heavyImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    showDragHandle: false,
    useSafeArea: true,
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => IncomingOrderPopup(offer: offer, startReconnecting: reconnecting),
  );
}

enum _Phase { reconnecting, active, expired }

class IncomingOrderPopup extends StatefulWidget {
  const IncomingOrderPopup({super.key, required this.offer, this.startReconnecting = false});

  final OrderOffer offer;
  final bool startReconnecting;

  static const Duration timeout = Duration(seconds: 15);
  static const Duration reconnectDelay = Duration(milliseconds: 2500);

  @override
  State<IncomingOrderPopup> createState() => _IncomingOrderPopupState();
}

class _IncomingOrderPopupState extends State<IncomingOrderPopup> {
  late _Phase _phase = widget.startReconnecting ? _Phase.reconnecting : _Phase.active;
  Timer? _reconnectTimer;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    if (_phase == _Phase.reconnecting) {
      _reconnectTimer = Timer(IncomingOrderPopup.reconnectDelay, () {
        if (mounted) setState(() => _phase = _Phase.active);
      });
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    super.dispose();
  }

  void _close({String? message}) {
    if (_closed) return;
    _closed = true;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    if (message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_phase == _Phase.active) {
          _close(message: 'Đã từ chối ${widget.offer.code}. Đang tìm đơn khác cho bạn.');
        } else if (_phase == _Phase.expired) {
          _close();
        }
      },
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: switch (_phase) {
            _Phase.reconnecting => const _Reconnecting(),
            _Phase.active => _ActiveOffer(
                offer: widget.offer,
                onAccept: _accept,
                onDecline: () => _close(
                  message: 'Đã từ chối ${widget.offer.code}. Đang tìm đơn khác cho bạn.',
                ),
                onTimeout: () {
                  HapticFeedback.mediumImpact();
                  if (mounted) setState(() => _phase = _Phase.expired);
                },
              ),
            _Phase.expired => _Expired(offer: widget.offer, onClose: () => _close()),
          },
        ),
      ),
    );
  }
}

class _ActiveOffer extends StatelessWidget {
  const _ActiveOffer({
    required this.offer,
    required this.onAccept,
    required this.onDecline,
    required this.onTimeout,
  });

  final OrderOffer offer;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onTimeout;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetHandle(),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const _UrgentBadge(),
                    const Spacer(),
                    CountdownRing(
                      total: IncomingOrderPopup.timeout,
                      color: AppColors.danger,
                      size: 64,
                      strokeWidth: 5,
                      fontSize: 17,
                      labelBuilder: (r) => '${r.inSeconds}s',
                      onFinished: onTimeout,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Thu nhập nhận được', style: appText(14.5, color: AppColors.textSub)),
                const SizedBox(height: 2),
                Text(
                  formatVnd(offer.price),
                  style: appText(34, weight: FontWeight.w700, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '- ${formatVnd(offer.platformFee)} chiết khấu sàn',
                  style: appText(14, color: AppColors.textSub),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                IssueRow(issue: offer.issue, subtitle: '${offer.vehicle} · ${offer.plate}'),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: SizedBox(
                    height: 136,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: RouteMap(
                            cornerRadius: 56,
                            points: [Offset(0.12, 0.8), Offset(0.4, 0.55), Offset(0.78, 0.4)],
                          ),
                        ),
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: MapChip(
                            icon: Icons.alt_route,
                            label: '${offer.distanceKm} km • ${offer.etaMinutes} phút',
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: RoundIconButton(
                            icon: Icons.navigation_outlined,
                            tooltip: 'Xem chỉ đường',
                            white: true,
                            size: 40,
                            onTap: () => showAppSnack(context, 'Mở chỉ đường tới ${offer.address}'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 22, color: AppColors.textSub),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(offer.address, style: appText(14.5, color: AppColors.textSub)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Stack(
                  children: [
                    const PhotoPlaceholder(height: 96),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.28),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.open_in_full, size: 17, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Ảnh hiện trường khách gửi lúc báo sự cố',
                    style: appText(12.5, color: AppColors.textMuted)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Expanded(flex: 4, child: OutlineActionButton(label: 'Từ chối', onPressed: onDecline)),
            const SizedBox(width: 12),
            Expanded(flex: 5, child: PrimaryButton(label: 'Chấp nhận đơn', onPressed: onAccept)),
          ],
        ),
      ],
    );
  }
}

class _UrgentBadge extends StatelessWidget {
  const _UrgentBadge({this.faded = false});
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final color = faded ? AppColors.danger.withValues(alpha: 0.4) : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft.withValues(alpha: faded ? 0.5 : 1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_outlined, color: color, size: 18),
          const SizedBox(width: 6),
          Text('ĐƠN KHẨN CẤP', style: appText(13, weight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

/// Mất kết nối tạm thời: chặn Nhận/Từ chối cho tới khi tải lại xong để tránh xử lý trùng.
class _Reconnecting extends StatelessWidget {
  const _Reconnecting();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetHandle(),
        const SizedBox(height: 14),
        const IconCircle(icon: Icons.wifi_off, size: 104, color: AppColors.textSub),
        const SizedBox(height: 22),
        Text('Đang tải lại dữ liệu đơn...', style: appText(19, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(
          'Mất kết nối tạm thời — không bấm Nhận/Từ chối cho đến khi tải lại xong để tránh xử lý trùng',
          textAlign: TextAlign.center,
          style: appText(14.5, color: AppColors.textSub, height: 1.5),
        ),
        const SizedBox(height: 22),
        const SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            color: AppColors.ink,
            backgroundColor: AppColors.border,
          ),
        ),
        const SizedBox(height: 24),
        const OutlineActionButton(label: 'Từ chối', onPressed: null),
      ],
    );
  }
}

/// Hết 15 giây không phản hồi: đơn được chuyển cho thợ khác.
class _Expired extends StatelessWidget {
  const _Expired({required this.offer, required this.onClose});
  final OrderOffer offer;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetHandle(),
        Opacity(
          opacity: 0.45,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _UrgentBadge(faded: true),
                  const Spacer(),
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 5),
                    ),
                    child: Text('0s', style: appText(16, weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Thu nhập nhận được', style: appText(14.5, color: AppColors.textSub)),
              Text(formatVnd(offer.price), style: appText(34, weight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const IconCircle(icon: Icons.schedule, size: 96, color: AppColors.textMuted),
        const SizedBox(height: 18),
        Text('Đơn đã được chuyển cho thợ khác', style: appText(18.5, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'Bạn chưa phản hồi trong 15 giây — hẹn đơn sau nhé',
          textAlign: TextAlign.center,
          style: appText(14.5, color: AppColors.textSub, height: 1.45),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: onClose,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.ink,
              shape: const StadiumBorder(),
            ),
            child: Text('Đóng', style: appText(16, weight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
