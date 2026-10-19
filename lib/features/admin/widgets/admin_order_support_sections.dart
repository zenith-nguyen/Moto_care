import 'package:flutter/material.dart';

import '../../../core/theme/admin_tokens.dart';
import '../models/admin_models.dart';
import '../theme/admin_order_theme.dart';
import 'admin_common.dart';
import 'admin_order_common.dart';
import 'admin_order_map.dart';

class AdminOrderSupportSections extends StatelessWidget {
  const AdminOrderSupportSections({super.key, required this.order});
  final AdminOrder order;
  @override
  Widget build(BuildContext context) => AdminOrderSurface(
    color: AdminTokens.card,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Thông tin bổ sung', style: AdminOrderTheme.title),
        const SizedBox(height: 8),
        _Section(
          title: 'Vị trí khách & thợ',
          child: AdminOrderMap(order: order),
        ),
        _Section(
          title: 'Danh sách offer',
          child: order.offers.isEmpty
              ? const AdminStateView.empty()
              : Column(
                  children: [
                    for (final offer in order.offers)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          offer.provider,
                          style: AdminOrderTheme.value,
                        ),
                        subtitle: Text(
                          '${adminMoney(offer.price)} • ${offer.label}',
                        ),
                      ),
                  ],
                ),
        ),
        _Section(
          title: 'Chi tiết giá & thời tiết',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Dịch vụ: ${adminMoney(order.servicePrice)}'),
              Text(
                'Hệ số thời tiết: ×${order.weatherFactor.toStringAsFixed(1)} (áp dụng phí dịch vụ)',
              ),
              Text('Di chuyển: ${adminMoney(order.travelPrice)}'),
              const SizedBox(height: 12),
              Text('Giá tạm tính: ${adminMoney(order.estimatedPrice)}'),
              Text(
                'Giá cuối: ${order.finalPrice == null ? 'Chưa chốt' : adminMoney(order.finalPrice!)}',
                style: AdminOrderTheme.value,
              ),
            ],
          ),
        ),
        _Section(
          title: 'Lịch sử thanh toán / hoàn tiền',
          child: order.payments.isEmpty
              ? const AdminStateView.empty()
              : Column(
                  children: [
                    for (final payment in order.payments)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${payment.label} • ${adminMoney(payment.amount)}',
                          style: AdminOrderTheme.value,
                        ),
                        subtitle: Text(
                          '${payment.id}\n${adminDate(payment.at)}',
                        ),
                      ),
                  ],
                ),
        ),
        _Section(
          title: 'Nội dung tranh chấp',
          child: order.dispute == null
              ? const AdminStateView.empty()
              : Text(order.dispute!),
        ),
        _Section(
          title: 'Chat history • Chỉ xem',
          child: AdminOrderChatLog(order: order),
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: PageStorageKey('admin-order-section-$title'),
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 16),
    shape: const RoundedRectangleBorder(),
    collapsedShape: const RoundedRectangleBorder(),
    iconColor: AdminTokens.text,
    collapsedIconColor: AdminTokens.muted,
    title: Text(title, style: AdminOrderTheme.value),
    children: [child],
  );
}

class AdminOrderChatLog extends StatelessWidget {
  const AdminOrderChatLog({super.key, required this.order});
  final AdminOrder order;
  @override
  Widget build(BuildContext context) => order.chat.isEmpty
      ? const AdminStateView.empty()
      : Column(
          children: [
            for (final message in order.chat)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.chat_bubble_outline,
                  color: AdminTokens.text,
                ),
                title: Text(message.message, style: AdminOrderTheme.value),
                subtitle: Text('${message.sender} • ${adminDate(message.at)}'),
              ),
          ],
        );
}
