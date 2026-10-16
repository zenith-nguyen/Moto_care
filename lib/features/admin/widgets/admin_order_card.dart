import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/admin_tokens.dart';
import '../models/admin_models.dart';
import '../theme/admin_order_theme.dart';
import 'admin_common.dart';
import 'admin_order_common.dart';

class AdminOrderCard extends StatelessWidget {
  const AdminOrderCard({super.key, required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) => AdminOrderSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminOrderIdentity(order: order),
        const SizedBox(height: 20),
        _FieldRow(
          left: _OrderField('Khách hàng', order.customer),
          right: _OrderField('Loại sự cố', order.incident),
        ),
        const SizedBox(height: 16),
        _FieldRow(
          left: _OrderField(
            'Thợ phân công',
            order.provider ?? 'Chưa phân công',
          ),
          right: _OrderField(
            'Giá cuối',
            order.finalPrice == null
                ? 'Chưa chốt'
                : adminMoney(order.finalPrice!),
            note: 'Tạm tính: ${adminMoney(order.estimatedPrice)}',
          ),
        ),
        const SizedBox(height: 16),
        _FieldRow(
          left: _OrderField('Thời gian tạo', adminDate(order.createdAt)),
          right: _OrderField('Thanh toán', order.payment.label),
        ),
        if (order.warning case final warning?) ...[
          const SizedBox(height: 16),
          Text(
            'Cảnh báo: $warning',
            style: AdminOrderTheme.label.copyWith(
              color: AdminTokens.primaryRed,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go('/admin/orders/${order.id}'),
            style: TextButton.styleFrom(
              backgroundColor: AdminTokens.card,
              foregroundColor: AdminTokens.text,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: const StadiumBorder(),
              textStyle: AdminOrderTheme.value.copyWith(fontSize: 12),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Chi tiết'),
          ),
        ),
      ],
    ),
  );
}

class AdminOrderCardList extends StatelessWidget {
  const AdminOrderCardList({super.key, required this.orders});
  final List<AdminOrder> orders;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth >= 900 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.2
          ? 2
          : 1;
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final order in orders)
            SizedBox(
              width: width,
              child: AdminOrderCard(
                key: ValueKey('admin-order-card-${order.id}'),
                order: order,
              ),
            ),
        ],
      );
    },
  );
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      const SizedBox(width: 16),
      Expanded(child: right),
    ],
  );
}

class _OrderField extends StatelessWidget {
  const _OrderField(this.label, this.value, {this.note});
  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AdminOrderTheme.label),
      const SizedBox(height: 4),
      Text(value, style: AdminOrderTheme.value),
      if (note != null) ...[
        const SizedBox(height: 4),
        Text(note!, style: AdminOrderTheme.label),
      ],
    ],
  );
}
