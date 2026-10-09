import '../../../core/money/money_amount.dart';
import '../../../core/network/json_reader.dart';
import 'order_status.dart';

class OrderCancellationResult {
  const OrderCancellationResult({
    required this.orderId,
    required this.status,
    required this.refundAmount,
  });

  final int orderId;
  final OrderStatus status;
  final MoneyAmount? refundAmount;

  factory OrderCancellationResult.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final refundAmount = reader.value('refundAmount');
    return OrderCancellationResult(
      orderId: reader.positiveInt('orderId'),
      status: OrderStatus.fromWire(reader.value('status')),
      refundAmount: refundAmount == null
          ? null
          : MoneyAmount.parse(refundAmount),
    );
  }
}

class ServiceStartToken {
  const ServiceStartToken({
    required this.orderId,
    required this.token,
    required this.expiresAt,
  });

  final int orderId;
  final String token;
  final DateTime expiresAt;

  factory ServiceStartToken.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return ServiceStartToken(
      orderId: reader.positiveInt('orderId'),
      token: reader.string('token'),
      expiresAt: reader.dateTime('expiresAt'),
    );
  }
}
