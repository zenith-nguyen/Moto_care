import '../../../core/network/json_reader.dart';
import '../../orders/domain/order_models.dart';
import '../../orders/domain/order_status.dart';

class DemoPrepaymentResult {
  const DemoPrepaymentResult({
    required this.orderId,
    required this.orderStatus,
    required this.paymentStatus,
    required this.matched,
  });

  final int orderId;
  final OrderStatus orderStatus;
  final PaymentStatus paymentStatus;
  final bool matched;

  factory DemoPrepaymentResult.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return DemoPrepaymentResult(
      orderId: reader.positiveInt('orderId'),
      orderStatus: OrderStatus.fromWire(reader.value('status')),
      paymentStatus: PaymentStatus.fromWire(reader.value('paymentStatus')),
      matched: reader.boolean('matched'),
    );
  }
}

class DemoAdjustmentResult {
  const DemoAdjustmentResult({
    required this.orderId,
    required this.orderStatus,
    required this.adjustment,
  });

  final int orderId;
  final OrderStatus orderStatus;
  final PaymentAdjustment adjustment;

  factory DemoAdjustmentResult.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return DemoAdjustmentResult(
      orderId: reader.positiveInt('orderId'),
      orderStatus: OrderStatus.fromWire(reader.value('status')),
      adjustment: PaymentAdjustment.fromJson(
        reader.object('paymentAdjustment'),
      ),
    );
  }
}
