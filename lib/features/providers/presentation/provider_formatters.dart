import 'package:intl/intl.dart';

import '../../../core/money/money_amount.dart';
import '../../orders/domain/order_status.dart';

final _providerCurrency = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: 'đ',
  decimalDigits: 0,
);

final _providerDateTime = DateFormat('dd/MM/yyyy • HH:mm');

String formatProviderMoney(MoneyAmount amount) {
  final value = int.parse(amount.value.split('.').first);
  return _providerCurrency.format(value);
}

String formatProviderDateTime(DateTime value) {
  return _providerDateTime.format(value.toLocal());
}

String providerOrderStatusLabel(OrderStatus status) => switch (status) {
  OrderStatus.awaitingPrepayment => 'Chờ thanh toán trước',
  OrderStatus.pendingMatch => 'Đang tìm thợ',
  OrderStatus.offered => 'Đang chờ phản hồi',
  OrderStatus.accepted => 'Đang đến khách',
  OrderStatus.arrived => 'Đã đến nơi',
  OrderStatus.inProgress => 'Đang sửa chữa',
  OrderStatus.awaitingPriceApproval => 'Chờ khách duyệt giá',
  OrderStatus.priceDisputed => 'Đang xử lý tranh chấp',
  OrderStatus.awaitingPayment => 'Chờ quyết toán',
  OrderStatus.paid => 'Đã thanh toán',
  OrderStatus.completed => 'Hoàn tất',
  OrderStatus.cancelled => 'Đã hủy',
  OrderStatus.refundPending => 'Chờ hoàn tiền',
  OrderStatus.refunded => 'Đã hoàn tiền',
};

bool providerOrderIsActive(OrderStatus status) => switch (status) {
  OrderStatus.accepted ||
  OrderStatus.arrived ||
  OrderStatus.inProgress ||
  OrderStatus.awaitingPriceApproval ||
  OrderStatus.priceDisputed ||
  OrderStatus.awaitingPayment ||
  OrderStatus.paid => true,
  _ => false,
};
