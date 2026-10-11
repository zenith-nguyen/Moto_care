import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'order_completed_screen.dart';
import 'order_final_quote_screen.dart';
import 'order_received_screen.dart';

/// Bước 3/5: Đang sửa chữa — đồng hồ đếm giờ, có thể đề xuất giá cuối hoặc hoàn thành.
class OrderInProgressScreen extends StatefulWidget {
  const OrderInProgressScreen({super.key, required this.order});

  final ActiveOrder order;

  @override
  State<OrderInProgressScreen> createState() => _OrderInProgressScreenState();
}

class _OrderInProgressScreenState extends State<OrderInProgressScreen> {
  late final Timer _ticker;
  Duration _elapsed = Duration.zero;
  QuoteStatus _lastQuoteStatus = QuoteStatus.none;

  @override
  void initState() {
    super.initState();
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _lastQuoteStatus = widget.order.quoteStatus;
    appState.addListener(_onStateChanged);
  }

  void _tick() {
    final start = widget.order.repairStartedAt ?? DateTime.now();
    setState(() => _elapsed = DateTime.now().difference(start));
  }

  /// Báo cho thợ khi khách đồng ý giá mới (mock phản hồi từ app khách).
  void _onStateChanged() {
    final status = widget.order.quoteStatus;
    if (status == QuoteStatus.accepted && _lastQuoteStatus == QuoteStatus.pending && mounted) {
      final isTop = ModalRoute.of(context)?.isCurrent ?? false;
      if (isTop) {
        showAppSnack(context, 'Khách đã đồng ý giá mới ${formatVnd(widget.order.proposedPrice!)}');
      }
    }
    _lastQuoteStatus = status;
  }

  @override
  void dispose() {
    _ticker.cancel();
    appState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _openQuote() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderFinalQuoteScreen(order: widget.order)),
    );
  }

  Future<void> _complete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hoàn thành công việc?', style: appText(19, weight: FontWeight.w800)),
        content: Text(
          'Khách sẽ được yêu cầu thanh toán ${formatVnd(widget.order.finalPrice)} qua Ví MotoCare.',
          style: appText(15, color: AppColors.textSub, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Chưa xong',
                style: appText(15, weight: FontWeight.w700, color: AppColors.textSub)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
            child: Text('Hoàn thành',
                style: appText(15, weight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final item = appState.completeOrder();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => OrderCompletedScreen(item: item)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final offer = order.offer;
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final pending = order.quoteStatus == QuoteStatus.pending;
        final accepted = order.quoteStatus == QuoteStatus.accepted;
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                const ScreenHeader(title: 'Đang sửa chữa'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    children: [
                      Text(
                        'Thời gian sửa chữa',
                        textAlign: TextAlign.center,
                        style: appText(15, weight: FontWeight.w700, color: AppColors.textSub),
                      ),
                      Text(
                        formatMmSs(_elapsed),
                        textAlign: TextAlign.center,
                        style:
                            appText(64, weight: FontWeight.w900, letterSpacing: -2, height: 1.15),
                      ),
                      const SizedBox(height: 18),
                      SurfaceCard(
                        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                        child: Row(
                          children: [
                            const AvatarCircle(dark: false, size: 52),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(offer.customerName,
                                      style: appText(17, weight: FontWeight.w800)),
                                  Text(
                                    '${offer.vehicle} · ${offer.plate}',
                                    style: appText(14, color: AppColors.textSub, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            RoundIconButton(
                              icon: Icons.chat_bubble_outline,
                              tooltip: 'Nhắn khách',
                              size: 52,
                              onTap: () => openOrderChat(context, order),
                            ),
                            const SizedBox(width: 10),
                            RoundIconButton(
                              icon: Icons.call_outlined,
                              tooltip: 'Gọi khách',
                              size: 52,
                              filled: true,
                              onTap: () =>
                                  callCustomer(context, offer.customerName, offer.customerPhone),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text('Nội dung sự cố', style: appText(17, weight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(
                        offer.description,
                        style: appText(15, color: AppColors.textSub, height: 1.55),
                      ),
                      const Divider(height: 36),
                      KeyValueRow(
                        'Giá ban đầu',
                        formatVnd(offer.price),
                        valueStyle: appText(19, weight: FontWeight.w900),
                      ),
                      if (pending)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('Giá đề xuất ${formatVnd(order.proposedPrice!)}',
                                    style: appText(15, color: AppColors.textSub)),
                              ),
                              const StatusBadge.pending('Đang chờ khách duyệt'),
                            ],
                          ),
                        ),
                      if (accepted)
                        KeyValueRow(
                          'Giá cuối (khách đã duyệt)',
                          formatVnd(order.finalPrice),
                          valueStyle:
                              appText(19, weight: FontWeight.w900, color: AppColors.success),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      OutlineActionButton(
                        label: pending ? 'Xem đề xuất giá' : 'Đề xuất giá cuối khác',
                        onPressed: _openQuote,
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Hoàn thành công việc',
                        onPressed: pending ? null : _complete,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
