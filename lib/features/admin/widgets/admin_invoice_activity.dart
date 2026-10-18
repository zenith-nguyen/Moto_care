import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/admin_tokens.dart';
import '../models/admin_models.dart';
import 'admin_common.dart';
import 'admin_finance_cards.dart';

class AdminInvoiceActivity extends StatelessWidget {
  const AdminInvoiceActivity({super.key, required this.invoices});

  final List<AdminReconciliation> invoices;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('admin-invoice-activity'),
    decoration: AdminFinanceStyle.surface,
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Hoạt động hóa đơn',
          style: AdminFinanceStyle.text(16, FontWeight.bold, AdminTokens.text),
        ),
        const SizedBox(height: 20),
        if (invoices.isEmpty)
          const AdminStateView.empty()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: math.max(constraints.maxWidth, 310 * scale),
                  child: Column(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: _InvoiceColumns(
                            identity: _heading('Mã đơn'),
                            status: _heading('Trạng thái'),
                            amount: _heading('Số tiền', align: TextAlign.right),
                          ),
                        ),
                      ),
                      for (var index = 0; index < invoices.length; index++) ...[
                        if (index > 0)
                          const Divider(height: 1, color: Color(0xFFF0F2F4)),
                        _InvoiceRow(invoice: invoices[index]),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    ),
  );

  Widget _heading(String text, {TextAlign? align}) => Text(
    text,
    textAlign: align,
    style: AdminFinanceStyle.text(
      10,
      FontWeight.w500,
      AdminFinanceStyle.caption,
    ),
  );
}

class _InvoiceColumns extends StatelessWidget {
  const _InvoiceColumns({
    required this.identity,
    required this.status,
    required this.amount,
  });

  final Widget identity;
  final Widget status;
  final Widget amount;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(flex: 5, child: identity),
      const SizedBox(width: 8),
      Expanded(flex: 4, child: status),
      const SizedBox(width: 8),
      Expanded(flex: 4, child: amount),
    ],
  );
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice});

  final AdminReconciliation invoice;

  @override
  Widget build(BuildContext context) {
    final order = invoice.order;
    final (label, color, icon) = invoice.status == AdminMatchStatus.anomaly
        ? ('Cần đối soát', AdminTokens.primaryRed, Icons.priority_high_rounded)
        : switch (order.payment) {
            AdminPaymentStatus.settled => (
              'Đã thanh toán',
              AdminTokens.success,
              Icons.check_rounded,
            ),
            AdminPaymentStatus.held => (
              'Chờ quyết toán',
              AdminTokens.neutral,
              Icons.circle,
            ),
            AdminPaymentStatus.unpaid => (
              invoice.status == AdminMatchStatus.excluded
                  ? 'Không áp dụng'
                  : 'Chờ thanh toán',
              AdminTokens.neutral,
              Icons.circle,
            ),
            AdminPaymentStatus.refunded => (
              'Đã hoàn tiền',
              AdminTokens.primaryBlue,
              Icons.undo_rounded,
            ),
          };
    final iconColor = order.payment == AdminPaymentStatus.held
        ? AdminTokens.warning
        : color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('admin-invoice-${order.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: _InvoiceColumns(
            identity: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.09),
                  ),
                  child: Icon(
                    icon,
                    size: icon == Icons.circle ? 7 : 16,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.id,
                        style: AdminFinanceStyle.text(
                          13,
                          FontWeight.bold,
                          AdminTokens.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat('dd/MM/yyyy').format(order.createdAt),
                        style: AdminFinanceStyle.text(
                          10,
                          FontWeight.w400,
                          AdminFinanceStyle.caption,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            status: Text(
              label,
              style: AdminFinanceStyle.text(11, FontWeight.w500, color),
            ),
            amount: Text(
              adminMoney(order.finalPrice ?? order.estimatedPrice),
              textAlign: TextAlign.right,
              style: AdminFinanceStyle.text(
                14,
                FontWeight.bold,
                AdminTokens.text,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final order = invoice.order;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đối soát ${order.id}',
                      style: AdminFinanceStyle.text(
                        16,
                        FontWeight.bold,
                        AdminTokens.text,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng chi tiết đối soát',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final (label, value) in [
                ('Payment ID', order.paymentId ?? 'Không có'),
                (
                  'Tiền đơn',
                  adminMoney(order.finalPrice ?? order.estimatedPrice),
                ),
                ('Tổng thu', adminMoney(order.collected)),
                ('Tổng hoàn', adminMoney(order.refunded)),
                ('Tổng cộng ví thợ', adminMoney(order.credited)),
                ('Trạng thái thanh toán', order.payment.label),
                ('Trạng thái đối soát', invoice.status.label),
                ('Lý do / Ghi chú', invoice.reason ?? '—'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AdminFinanceStyle.text(
                          11,
                          FontWeight.w500,
                          AdminTokens.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: AdminFinanceStyle.text(
                          14,
                          FontWeight.w500,
                          AdminTokens.text,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
