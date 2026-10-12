import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/order_widgets.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/ui.dart';
import 'order_completed_screen.dart';
import 'order_final_quote_screen.dart';
import 'order_received_screen.dart';

/// Bước 3/5: Đang sửa chữa — đồng hồ đếm giờ, có thể đề xuất giá khác hoặc hoàn thành.
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
        showAppSnack(
          context,
          'Khách đã đồng ý giá mới ${formatVnd(widget.order.proposedPrice!)}',
        );
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

  void _complete() {
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
                ScreenHeader(title: 'Đơn ${offer.code}'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    children: [
                      const StepProgressBar(current: 3, steps: orderStepLabels),
                      const SizedBox(height: 22),
                      Text(
                        'Thời gian đã sửa',
                        textAlign: TextAlign.center,
                        style: appText(14.5, weight: FontWeight.w500, color: AppColors.textSub),
                      ),
                      const SizedBox(height: 18),
                      Center(child: _TimerRing(text: formatMmSs(_elapsed))),
                      const SizedBox(height: 22),
                      CustomerCard(
                        name: offer.customerName,
                        subtitle: '${offer.vehicle} · ${offer.plate}',
                        actions: customerActions(context, order),
                      ),
                      const SizedBox(height: 16),
                      SurfaceCard(
                        radius: AppRadius.md,
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nội dung sự cố', style: appText(15.5, weight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text(
                              offer.description,
                              style: appText(14.5, color: AppColors.textSub, height: 1.55),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            KeyValueRow(
                              'Giá ban đầu',
                              formatVnd(offer.price),
                              valueStyle: appText(16.5, weight: FontWeight.w700),
                            ),
                            if (pending)
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Giá đề xuất ${formatVnd(order.proposedPrice!)}',
                                      style: appText(14.5, color: AppColors.textSub),
                                    ),
                                  ),
                                  const StatusBadge.pending('Đang chờ khách duyệt'),
                                ],
                              ),
                            if (accepted)
                              KeyValueRow(
                                'Giá cuối (khách đã duyệt)',
                                formatVnd(order.finalPrice),
                                valueStyle: appText(16.5,
                                    weight: FontWeight.w700, color: AppColors.success),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: OutlineActionButton(
                          label: pending ? 'Xem đề xuất giá' : 'Đề xuất giá khác',
                          onPressed: _openQuote,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: PrimaryButton(
                          label: 'Hoàn thành',
                          onPressed: pending ? null : _complete,
                        ),
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

/// Đồng hồ đếm giờ sửa: vòng đỏ nhạt bao quanh, số mm:ss màu đỏ.
class _TimerRing extends StatelessWidget {
  const _TimerRing({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Thời gian đã sửa $text',
      child: Container(
        width: 190,
        height: 190,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.danger.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.28), width: 7),
          boxShadow: [
            BoxShadow(
              color: AppColors.danger.withValues(alpha: 0.18),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          width: 160,
          height: 160,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppColors.danger, width: 3),
          ),
          child: Text(text, style: appText(36, weight: FontWeight.w600, color: AppColors.danger)),
        ),
      ),
    );
  }
}
