import 'package:intl/intl.dart';

import '../../../core/money/money_amount.dart';
import '../../orders/domain/order_status.dart';

final _adminCurrency = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: 'đ',
  decimalDigits: 0,
);

final _adminDate = DateFormat('dd/MM/yyyy');

String formatAdminMoney(MoneyAmount amount) {
  final value = int.tryParse(amount.value.split('.').first) ?? 0;
  return _adminCurrency.format(value);
}

String formatAdminDate(DateTime value) => _adminDate.format(value.toLocal());

String adminOrderStatusLabel(OrderStatus status) => switch (status) {
  OrderStatus.awaitingPrepayment => 'Chờ thanh toán',
  OrderStatus.pendingMatch => 'Đang tìm thợ',
  OrderStatus.offered => 'Đã gửi offer',
  OrderStatus.accepted => 'Đã nhận',
  OrderStatus.arrived => 'Đã đến nơi',
  OrderStatus.inProgress => 'Đang xử lý',
  OrderStatus.awaitingPriceApproval => 'Chờ duyệt giá',
  OrderStatus.priceDisputed => 'Tranh chấp giá',
  OrderStatus.awaitingPayment => 'Chờ quyết toán',
  OrderStatus.paid => 'Đã thanh toán',
  OrderStatus.completed => 'Hoàn tất',
  OrderStatus.cancelled => 'Đã hủy',
  OrderStatus.refundPending => 'Chờ hoàn tiền',
  OrderStatus.refunded => 'Đã hoàn tiền',
};
