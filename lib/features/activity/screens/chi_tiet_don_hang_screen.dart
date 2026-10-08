import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/main_navigation.dart';
import '../../home/models/home_destination.dart';
import '../../home/widgets/home_bottom_navigation.dart';

import '../models/rescue_order.dart';
import '../providers/activity_provider.dart';
import '../services/activity_actions.dart';
import '../theme/activity_theme.dart';
import '../widgets/order_rating_card.dart';
import '../widgets/active_order_card.dart';
import '../widgets/order_summary.dart';

class ChiTietDonHangScreen extends ConsumerWidget {
  const ChiTietDonHangScreen({super.key, this.orderId});
  final String? orderId;

  void _back(BuildContext context, [bool? created]) {
    if (context.canPop()) {
      context.pop(created);
    } else {
      context.go('/hoat-dong');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(activityProvider).orderById(orderId);
    return Theme(
      data: ActivityTheme.light,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Quay lại',
            onPressed: () => _back(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Chi tiết đơn hàng'),
          actions: [
            if (order?.status.isActive == true)
              IconButton(
                tooltip: 'Theo dõi lộ trình thợ',
                onPressed: () => context.push(
                  '/order-tracking?id=${Uri.encodeComponent(order!.id)}',
                ),
                icon: const Icon(Icons.route_rounded, color: ActivityTheme.red),
              ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: order == null
                  ? const OrderEmptyState(
                      message: 'Không tìm thấy đơn hàng. Vui lòng quay lại Hoạt động.',
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Dữ liệu mẫu',
                          style: TextStyle(
                            color: ActivityTheme.mutedText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (order.status.isActive) ...[
                          ActiveOrderCard(
                            order: order,
                            onMap: () =>
                                ActivityActions.openMap(context, ref, order),
                            onCall: () =>
                                ActivityActions.call(context, ref, order),
                            onChat: () => ActivityActions.chat(context, order),
                            onCancel: () =>
                                ActivityActions.cancel(context, ref, order),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _OrderInvoice(order: order),
                        const SizedBox(height: 16),
                        OrderRatingCard(key: ValueKey(order.id), order: order),
                        const SizedBox(height: 20),
                        Builder(
                          builder: (context) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () =>
                                    ActivityActions.report(context, ref, order),
                                icon: const Icon(Icons.report_problem_outlined),
                                label: const Text('Báo cáo / Khiếu nại'),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: order.status.isActive
                                    ? null
                                    : () async {
                                        final created =
                                            await ActivityActions.rebook(
                                              context,
                                              ref,
                                              order,
                                            );
                                        if (context.mounted && created) {
                                          _back(context, true);
                                        }
                                      },
                                icon: const Icon(Icons.replay_rounded),
                                label: const Text('Đặt cứu hộ lại'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        bottomNavigationBar: HomeBottomNavigation(
          selectedDestination: HomeDestination.activity,
          onSelected: (destination) => navigateMainTab(context, destination),
        ),
      ),
    );
  }
}

class _OrderInvoice extends StatelessWidget {
  const _OrderInvoice({required this.order});
  final RescueOrder order;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Color(0xFF171717), height: 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: ActivityTheme.red,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.status == RescueOrderStatus.completed
                        ? 'HÓA ĐƠN'
                        : 'CHI PHÍ DỰ KIẾN',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              order.orderCode,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              formatOrderDate(order.createdAt),
              style: const TextStyle(color: Color(0xFF595959)),
            ),
            const SizedBox(height: 8),
            Text(
              order.status.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Divider(height: 32, color: Color(0xFFDDDDDD)),
            Text('Dịch vụ: ${order.serviceType.label}'),
            if (order.partnerName != null) ...[
              const SizedBox(height: 8),
              Text('Tiệm: ${order.partnerName}'),
              const SizedBox(height: 8),
              Text('Thanh toán: ${order.paymentMethod.label}'),
              for (final item in order.items) ...[
                const SizedBox(height: 8),
                Text(
                  '${item.name} × ${item.quantity} • ${formatOrderPrice(item.total)}',
                ),
              ],
            ],
            const SizedBox(height: 8),
            Text('Xe: ${order.userVehicle}'),
            const SizedBox(height: 8),
            Text('Địa chỉ: ${order.locationAddress}'),
            if (order.locationLandmark.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Điểm nhận diện: ${order.locationLandmark}'),
            ],
            if (order.incidentDescription.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Mô tả sự cố: ${order.incidentDescription}'),
            ],
            const SizedBox(height: 8),
            Text('Thợ: ${order.providerName ?? 'Chưa có thợ nhận đơn'}'),
            const Divider(height: 32, color: Color(0xFFDDDDDD)),
            _CostLine(
              label: 'Phí di chuyển',
              value: formatOrderPrice(order.travelFee),
            ),
            _CostLine(
              label: order.items.isEmpty ? 'Phí công sửa' : 'Tiền dịch vụ',
              value: formatOrderPrice(order.laborFee),
            ),
            _CostLine(
              label: 'Phụ tùng phát sinh',
              value: formatOrderPrice(order.extraPartPrice),
            ),
            if (order.discount > 0)
              _CostLine(
                label: 'Điều chỉnh giá',
                value: '- ${formatOrderPrice(order.discount)}',
              ),
            const Divider(height: 24, color: Color(0xFFDDDDDD)),
            _CostLine(
              label: order.status == RescueOrderStatus.completed
                  ? 'Tổng thanh toán'
                  : 'Tổng dự kiến',
              value: formatOrderPrice(order.totalPrice),
              isTotal: true,
            ),
          ],
        ),
      ),
    ),
  );
}

class _CostLine extends StatelessWidget {
  const _CostLine({
    required this.label,
    required this.value,
    this.isTotal = false,
  });
  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 17 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
    ),
  );
}
