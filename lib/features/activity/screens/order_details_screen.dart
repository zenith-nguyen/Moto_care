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
import '../widgets/order_summary.dart';
import '../widgets/order_timeline.dart';
import '../widgets/rescue_details_card.dart';
import '../widgets/rescue_progress_stepper.dart';

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
    return Theme(
      data: OrderDetailsTheme.light,
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: OrderDetailsTheme.background,
          appBar: AppBar(
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
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: details == null || order == null
                    ? const OrderEmptyState(
                        message: 'Không tìm thấy đơn hàng. Vui lòng quay lại Hoạt động.',
                      )
                    : SingleChildScrollView(
                        key: const ValueKey('order-details-scroll'),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OrderDetailsHeader(
                              details: details,
                              onCopy: () => _copy(context, order.orderCode),
                            ),
                            const SizedBox(height: 24),
                            RescueProgressStepper(steps: details.steps),
                            const SizedBox(height: 24),
                            FilledButton(
                              key: const ValueKey('order-details-tracking'),
                              onPressed: order.status.isActive
                                  ? () => context.push(
                                      '/order-tracking?id=${Uri.encodeQueryComponent(order.id)}',
                                    )
                                  : null,
                              child: const Row(
                                children: [
                                  Icon(Icons.map_outlined, size: 21),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Xem vị trí thợ trên bản đồ',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            RescueDetailsCard(details: details),
                            const SizedBox(height: 16),
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
                            const SizedBox(height: 16),
                            OrderTimeline(entries: details.timeline),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              key: const ValueKey('order-details-invoice'),
                              onPressed: () => context.push(
                                '/chi-tiet-don-hang?id=${Uri.encodeQueryComponent(order.id)}',
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.receipt_long_outlined,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      order.status ==
                                              RescueOrderStatus.completed
                                          ? 'Xem hóa đơn & đánh giá'
                                          : 'Xem chi phí & thông tin đơn',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (order.status.isActive)
                              TextButton(
                                key: const ValueKey('order-details-cancel'),
                                onPressed: () =>
                                    ActivityActions.cancel(context, ref, order),
                                child: Text(
                                  'Hủy đơn cứu hộ',
                                  style: CustomerOrderTheme.text(
                                    color: OrderDetailsTheme.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
