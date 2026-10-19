/// Admin-side processing state of a payout request (not the order status).
enum PayoutStatus { received, processing, paid, rejected }

/// A payout request the mechanic sent to Admin for a completed order.
/// There is no Admin backend yet, so instances come from demo fixtures only.
class PayoutRequest {
  const PayoutRequest({
    required this.id,
    required this.orderCode,
    required this.amount,
    required this.serviceName,
    required this.status,
    required this.receivedAt,
    this.processingAt,
    this.resolvedAt,
    this.rejectReason,
  });

  final String id;
  final String orderCode;
  final int amount;
  final String serviceName;
  final PayoutStatus status;
  final DateTime receivedAt;
  final DateTime? processingAt;
  final DateTime? resolvedAt;
  final String? rejectReason;
}
