import '../../../core/network/json_reader.dart';
import 'order_models.dart';
import 'order_status.dart';

class PriceDecisionResult {
  const PriceDecisionResult({
    required this.orderId,
    required this.orderStatus,
    required this.proposal,
    required this.paymentAdjustment,
  });

  final int orderId;
  final OrderStatus orderStatus;
  final PriceProposal proposal;
  final PaymentAdjustment? paymentAdjustment;

  factory PriceDecisionResult.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final adjustment = reader.nullableObject('paymentAdjustment');
    return PriceDecisionResult(
      orderId: reader.positiveInt('orderId'),
      orderStatus: OrderStatus.fromWire(reader.value('orderStatus')),
      proposal: PriceProposal.fromJson(reader.object('proposal')),
      paymentAdjustment: adjustment == null
          ? null
          : PaymentAdjustment.fromJson(adjustment),
    );
  }
}
