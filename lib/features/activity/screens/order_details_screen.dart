import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/rescue_order.dart';
import '../providers/order_details_provider.dart';
import '../services/activity_actions.dart';
import '../theme/order_details_theme.dart';
import '../widgets/mechanic_contact_card.dart';
import '../widgets/order_details_header.dart';
import '../widgets/order_details_map_preview.dart';
import '../widgets/order_summary.dart';
import '../widgets/order_timeline.dart';
import '../widgets/rescue_details_card.dart';
import '../widgets/rescue_progress_stepper.dart';
import '../../orders/presentation/final_price_approval_card.dart';

class OrderDetailsScreen extends ConsumerWidget {
  const OrderDetailsScreen({super.key, this.orderId});
  final String? orderId;

  Future<void> _copy(BuildContext context, String code) async {
    try {
      await Clipboard.setData(ClipboardData(text: code));
      if (context.mounted) {
        ActivityActions.feedback(context, 'Đã sao chép mã đơn.');
      }
    } on PlatformException {
      if (context.mounted) {
        ActivityActions.feedback(
          context,
          'Không thể sao chép mã đơn. Vui lòng thử lại.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(orderDetailsProvider(orderId));
    final order = details?.order;
    // When a mechanic accepts (order gains a provider while still active),
    // move the customer straight to live tracking.
    ref.listen(orderDetailsProvider(orderId), (previous, next) {
      if (previous != null &&
          !previous.order.hasProvider &&
          next?.order.hasProvider == true &&
          next!.order.status.isActive &&
          !next.order.awaitingPrepayment) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
            context.pushReplacement(
              '/order-tracking?id=${Uri.encodeQueryComponent(next.order.id)}',
            );
          }
        });
      }
    });
    return Theme(
      data: OrderDetailsTheme.light,
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: OrderDetailsTheme.background,
          appBar: AppBar(
            backgroundColor: OrderDetailsTheme.background,
            toolbarHeight: MediaQuery.textScalerOf(context).scale(18) > 23
                ? 76
                : 56,
            leading: IconButton(
              tooltip: 'Quay lại',
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: OrderDetailsTheme.muted,
              ),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/hoat-dong'),
            ),
            title: const Text(
              'Chi tiết đơn cứu hộ',
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
            ),
            actions: [
              IconButton(
                key: const ValueKey('order-details-support'),
                tooltip: 'Trung tâm hỗ trợ',
                onPressed: () => context.push('/faq'),
                icon: const Icon(Icons.headset_mic_outlined, size: 20),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: details == null || order == null
                    ? const OrderEmptyState(
                        message: 'Không tìm thấy đơn hàng. Vui lòng quay lại Hoạt động.',
                      )
                    : SingleChildScrollView(
                        key: const ValueKey('order-details-scroll'),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  OrderDetailsHeader(
                                    details: details,
                                    onCopy: () =>
                                        _copy(context, order.orderCode),
                                  ),
                                  const SizedBox(height: 18),
                                  RescueProgressStepper(steps: details.steps),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Keep price approval beside the progress stepper.
                            FinalPriceApprovalCard(orderId: order.id),
                            OrderDetailsMapPreview(
                              details: details,
                              onTracking: order.status.isActive
                                  ? () => context.push(
                                      order.awaitingPrepayment
                                          ? '/bank-transfer?id=${Uri.encodeQueryComponent(order.id)}'
                                          : '/order-tracking?id=${Uri.encodeQueryComponent(order.id)}',
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            MechanicContactCard(
                              details: details,
                              onChat: order.hasProvider
                                  ? () => ActivityActions.chat(context, order)
                                  : null,
                              onCall:
                                  order.providerPhone?.trim().isNotEmpty == true
                                  ? () => ActivityActions.call(
                                      context,
                                      ref,
                                      order,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            RescueDetailsCard(details: details),
                            const SizedBox(height: 14),
                            OrderTimeline(entries: details.timeline),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          bottomNavigationBar: order == null
              ? null
              : _BottomActions(
                  order: order,
                  onInvoice: () => context.push(
                    '/chi-tiet-don-hang?id=${Uri.encodeQueryComponent(order.id)}',
                  ),
                  onCancel: order.status.isActive
                      ? () => ActivityActions.cancel(context, ref, order)
                      : null,
                ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OrderDetailsTheme.border),
      ),
      child: child,
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.order,
    required this.onInvoice,
    this.onCancel,
  });

  final RescueOrder order;
  final VoidCallback onInvoice;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final completed = order.status == RescueOrderStatus.completed;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: OrderDetailsTheme.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              key: const ValueKey('order-details-invoice'),
              onPressed: onInvoice,
              style: FilledButton.styleFrom(
                backgroundColor: OrderDetailsTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.receipt_long_rounded, size: 20),
              label: Text(
                completed
                    ? 'Xem hóa đơn & đánh giá'
                    : 'Xem chi phí & thông tin đơn',
              ),
            ),
            if (onCancel != null)
              TextButton(
                key: const ValueKey('order-details-cancel'),
                onPressed: onCancel,
                child: const Text(
                  'Hủy đơn cứu hộ',
                  style: TextStyle(
                    color: OrderDetailsTheme.muted,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
