enum OrderStatus {
  awaitingPrepayment('AWAITING_PREPAYMENT'),
  pendingMatch('PENDING_MATCH'),
  offered('OFFERED'),
  accepted('ACCEPTED'),
  arrived('ARRIVED'),
  inProgress('IN_PROGRESS'),
  awaitingPriceApproval('AWAITING_PRICE_APPROVAL'),
  priceDisputed('PRICE_DISPUTED'),
  awaitingPayment('AWAITING_PAYMENT'),
  paid('PAID'),
  completed('COMPLETED'),
  cancelled('CANCELLED'),
  refundPending('REFUND_PENDING'),
  refunded('REFUNDED');

  const OrderStatus(this.wireValue);

  final String wireValue;

  static OrderStatus fromWire(Object? raw) {
    return values.firstWhere(
      (status) => status.wireValue == raw,
      orElse: () => throw FormatException('Unsupported order status: $raw'),
    );
  }

  bool get isTerminal => switch (this) {
    completed || cancelled || refunded => true,
    _ => false,
  };
}

enum PaymentStatus {
  pending('PENDING'),
  paid('PAID'),
  failed('FAILED'),
  cancelled('CANCELLED'),
  refundPending('REFUND_PENDING'),
  refunded('REFUNDED');

  const PaymentStatus(this.wireValue);

  final String wireValue;

  static PaymentStatus fromWire(Object? raw) {
    return values.firstWhere(
      (status) => status.wireValue == raw,
      orElse: () => throw FormatException('Unsupported payment status: $raw'),
    );
  }
}

enum PriceProposalStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED'),
  disputed('DISPUTED'),
  resolvedApproved('RESOLVED_APPROVED'),
  resolvedRejected('RESOLVED_REJECTED');

  const PriceProposalStatus(this.wireValue);

  final String wireValue;

  static PriceProposalStatus fromWire(Object? raw) {
    return values.firstWhere(
      (status) => status.wireValue == raw,
      orElse: () =>
          throw FormatException('Unsupported price proposal status: $raw'),
    );
  }
}

enum PaymentAdjustmentType {
  charge('CHARGE'),
  refund('REFUND');

  const PaymentAdjustmentType(this.wireValue);

  final String wireValue;

  static PaymentAdjustmentType fromWire(Object? raw) {
    return values.firstWhere(
      (type) => type.wireValue == raw,
      orElse: () =>
          throw FormatException('Unsupported payment adjustment type: $raw'),
    );
  }
}

enum PaymentAdjustmentStatus {
  pending('PENDING'),
  settled('SETTLED');

  const PaymentAdjustmentStatus(this.wireValue);

  final String wireValue;

  static PaymentAdjustmentStatus fromWire(Object? raw) {
    return values.firstWhere(
      (status) => status.wireValue == raw,
      orElse: () =>
          throw FormatException('Unsupported payment adjustment status: $raw'),
    );
  }
}
