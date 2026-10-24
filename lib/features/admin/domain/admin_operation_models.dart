import '../../../core/money/money_amount.dart';
import '../../../core/network/json_reader.dart';
import '../../auth/domain/app_user.dart';
import '../../orders/domain/order_status.dart';
import '../../wallet/domain/wallet_models.dart';

enum ProviderApprovalStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED');

  const ProviderApprovalStatus(this.wireValue);
  final String wireValue;

  static ProviderApprovalStatus fromWire(Object? raw) {
    return values.firstWhere(
      (status) => status.wireValue == raw,
      orElse: () => throw FormatException('Unknown approval status: $raw'),
    );
  }
}

enum AdminDecision {
  approve('APPROVE'),
  reject('REJECT');

  const AdminDecision(this.wireValue);
  final String wireValue;
}

class AdminRecentOrder {
  const AdminRecentOrder({
    required this.id,
    required this.code,
    required this.status,
    required this.customerId,
    required this.providerId,
    required this.estimatedPrice,
    required this.finalPrice,
    required this.createdAt,
  });
  final int id;
  final String code;
  final OrderStatus status;
  final int customerId;
  final int? providerId;
  final MoneyAmount estimatedPrice;
  final MoneyAmount? finalPrice;
  final DateTime createdAt;

  factory AdminRecentOrder.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return AdminRecentOrder(
      id: reader.positiveInt('id'),
      code: reader.string('code'),
      status: OrderStatus.fromWire(reader.value('status')),
      customerId: reader.positiveInt('customerId'),
      providerId: reader.nullablePositiveInt('providerId'),
      estimatedPrice: MoneyAmount.parse(reader.value('estimatedPrice')),
      finalPrice: _nullableMoney(reader.value('finalPrice')),
      createdAt: reader.dateTime('createdAt'),
    );
  }
}

class PendingProviderApplication {
  const PendingProviderApplication({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.approvalStatus,
    required this.documentUrl,
  });
  final int id;
  final int userId;
  final String name;
  final String? email;
  final String? phone;
  final ProviderApprovalStatus approvalStatus;
  final String? documentUrl;

  factory PendingProviderApplication.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return PendingProviderApplication(
      id: reader.positiveInt('id'),
      userId: reader.positiveInt('userId'),
      name: reader.string('name'),
      email: reader.nullableString('email'),
      phone: reader.nullableString('phone'),
      approvalStatus: ProviderApprovalStatus.fromWire(
        reader.value('approvalStatus'),
      ),
      documentUrl: reader.nullableString('documentUrl'),
    );
  }
}

class ProviderReviewResult {
  const ProviderReviewResult({
    required this.id,
    required this.userId,
    required this.approvalStatus,
    required this.accountStatus,
  });
  final int id;
  final int userId;
  final ProviderApprovalStatus approvalStatus;
  final AppUserStatus accountStatus;

  factory ProviderReviewResult.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return ProviderReviewResult(
      id: reader.positiveInt('id'),
      userId: reader.positiveInt('userId'),
      approvalStatus: ProviderApprovalStatus.fromWire(
        reader.value('approvalStatus'),
      ),
      accountStatus: AppUserStatus.fromWire(reader.value('accountStatus')),
    );
  }
}

class PendingFullRefund {
  const PendingFullRefund({
    required this.orderId,
    required this.code,
    required this.customerId,
    required this.amount,
    required this.isDemo,
    required this.reason,
    required this.createdAt,
  });
  final int orderId;
  final String code;
  final int customerId;
  final MoneyAmount? amount;
  final bool isDemo;
  final String? reason;
  final DateTime createdAt;

  factory PendingFullRefund.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return PendingFullRefund(
      orderId: reader.positiveInt('orderId'),
      code: reader.string('code'),
      customerId: reader.positiveInt('customerId'),
      amount: _nullableMoney(reader.value('amount')),
      isDemo: reader.boolean('isDemo'),
      reason: reader.nullableString('reason'),
      createdAt: reader.dateTime('createdAt'),
    );
  }
}

class DemoRefundResult {
  const DemoRefundResult({
    required this.orderId,
    required this.status,
    required this.paymentStatus,
    required this.amount,
  });
  final int orderId;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final MoneyAmount amount;

  factory DemoRefundResult.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return DemoRefundResult(
      orderId: reader.positiveInt('orderId'),
      status: OrderStatus.fromWire(reader.value('status')),
      paymentStatus: PaymentStatus.fromWire(reader.value('paymentStatus')),
      amount: MoneyAmount.parse(reader.value('amount')),
    );
  }
}

class AdminPriceDispute {
  const AdminPriceDispute({
    required this.id,
    required this.orderId,
    required this.orderStatus,
    required this.providerId,
    required this.proposedFinalPrice,
    required this.reason,
    required this.status,
    required this.customerReason,
    required this.disputeReason,
    required this.resolutionReason,
    required this.decidedById,
    required this.decidedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  final int id;
  final int orderId;
  final OrderStatus orderStatus;
  final int providerId;
  final MoneyAmount proposedFinalPrice;
  final String reason;
  final PriceProposalStatus status;
  final String? customerReason;
  final String? disputeReason;
  final String? resolutionReason;
  final int? decidedById;
  final DateTime? decidedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AdminPriceDispute.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return AdminPriceDispute(
      id: reader.positiveInt('id'),
      orderId: reader.positiveInt('orderId'),
      orderStatus: OrderStatus.fromWire(reader.value('orderStatus')),
      providerId: reader.positiveInt('providerId'),
      proposedFinalPrice: MoneyAmount.parse(reader.value('proposedFinalPrice')),
      reason: reader.string('reason'),
      status: PriceProposalStatus.fromWire(reader.value('status')),
      customerReason: reader.nullableString('customerReason'),
      disputeReason: reader.nullableString('disputeReason'),
      resolutionReason: reader.nullableString('resolutionReason'),
      decidedById: reader.nullablePositiveInt('decidedById'),
      decidedAt: reader.nullableDateTime('decidedAt'),
      createdAt: reader.dateTime('createdAt'),
      updatedAt: reader.dateTime('updatedAt'),
    );
  }
}

class PendingRefundAdjustment {
  const PendingRefundAdjustment({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.isDemo,
    required this.settledAt,
    required this.order,
  });
  final int id;
  final PaymentAdjustmentType type;
  final MoneyAmount amount;
  final PaymentAdjustmentStatus status;
  final bool isDemo;
  final DateTime? settledAt;
  final RefundAdjustmentOrder order;

  factory PendingRefundAdjustment.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return PendingRefundAdjustment(
      id: reader.positiveInt('id'),
      type: PaymentAdjustmentType.fromWire(reader.value('type')),
      amount: MoneyAmount.parse(reader.value('amount')),
      status: PaymentAdjustmentStatus.fromWire(reader.value('status')),
      isDemo: reader.boolean('isDemo'),
      settledAt: reader.nullableDateTime('settledAt'),
      order: RefundAdjustmentOrder.fromJson(reader.object('order')),
    );
  }
}

class RefundAdjustmentOrder {
  const RefundAdjustmentOrder({
    required this.id,
    required this.code,
    required this.customerId,
    required this.providerId,
    required this.estimatedPrice,
    required this.finalPrice,
  });
  final int id;
  final String code;
  final int customerId;
  final int? providerId;
  final MoneyAmount estimatedPrice;
  final MoneyAmount? finalPrice;

  factory RefundAdjustmentOrder.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return RefundAdjustmentOrder(
      id: reader.positiveInt('id'),
      code: reader.string('code'),
      customerId: reader.positiveInt('customerId'),
      providerId: reader.nullablePositiveInt('providerId'),
      estimatedPrice: MoneyAmount.parse(reader.value('estimatedPrice')),
      finalPrice: _nullableMoney(reader.value('finalPrice')),
    );
  }
}

class AdminWithdrawal {
  const AdminWithdrawal({required this.request, required this.provider});
  final WithdrawalRequest request;
  final AdminWithdrawalProvider provider;

  factory AdminWithdrawal.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return AdminWithdrawal(
      request: WithdrawalRequest.fromJson(json),
      provider: AdminWithdrawalProvider.fromJson(reader.object('provider')),
    );
  }
}

class AdminWithdrawalProvider {
  const AdminWithdrawalProvider({
    required this.id,
    required this.userId,
    required this.name,
  });
  final int id;
  final int userId;
  final String name;

  factory AdminWithdrawalProvider.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return AdminWithdrawalProvider(
      id: reader.positiveInt('id'),
      userId: reader.positiveInt('userId'),
      name: reader.string('name'),
    );
  }
}

enum WithdrawalPayoutStatus {
  awaitingTransfer('AWAITING_TRANSFER'),
  manualReview('MANUAL_REVIEW'),
  reconciled('RECONCILED');

  const WithdrawalPayoutStatus(this.wireValue);
  final String wireValue;

  static WithdrawalPayoutStatus fromWire(Object? raw) {
    return values.firstWhere(
      (status) => status.wireValue == raw,
      orElse: () =>
          throw FormatException('Unknown withdrawal payout status: $raw'),
    );
  }
}

enum PayoutReconciliationDecision {
  confirm('CONFIRM'),
  flag('FLAG');

  const PayoutReconciliationDecision(this.wireValue);
  final String wireValue;
}

/// A provider payout that is waiting for the owner's manual bank transfer to be
/// confirmed. This is the RECONCILED stage of the money guardrail: the owner
/// transfers money by hand, then records the bank transaction here. The app
/// never moves money on its own.
class AdminWithdrawalPayout {
  const AdminWithdrawalPayout({
    required this.id,
    required this.withdrawalId,
    required this.payoutCode,
    required this.expectedAmount,
    required this.status,
    required this.externalTransactionId,
    required this.externalReferenceCode,
    required this.observedAmount,
    required this.reviewReason,
    required this.reconciledById,
    required this.reconciledAt,
    required this.bankTransferConfirmed,
    required this.createdAt,
    required this.updatedAt,
    required this.provider,
  });

  final int id;
  final int withdrawalId;
  final String payoutCode;
  final MoneyAmount expectedAmount;
  final WithdrawalPayoutStatus status;
  final String? externalTransactionId;
  final String? externalReferenceCode;
  final MoneyAmount? observedAmount;
  final String? reviewReason;
  final int? reconciledById;
  final DateTime? reconciledAt;
  final bool bankTransferConfirmed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AdminWithdrawalProvider? provider;

  factory AdminWithdrawalPayout.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final providerJson = reader.nullableObject('provider');
    return AdminWithdrawalPayout(
      id: reader.positiveInt('id'),
      withdrawalId: reader.positiveInt('withdrawalId'),
      payoutCode: reader.string('payoutCode'),
      expectedAmount: MoneyAmount.parse(reader.value('expectedAmount')),
      status: WithdrawalPayoutStatus.fromWire(reader.value('status')),
      externalTransactionId: reader.nullableString('externalTransactionId'),
      externalReferenceCode: reader.nullableString('externalReferenceCode'),
      observedAmount: _nullableMoney(reader.value('observedAmount')),
      reviewReason: reader.nullableString('reviewReason'),
      reconciledById: reader.nullablePositiveInt('reconciledById'),
      reconciledAt: reader.nullableDateTime('reconciledAt'),
      bankTransferConfirmed: reader.boolean('bankTransferConfirmed'),
      createdAt: reader.dateTime('createdAt'),
      updatedAt: reader.dateTime('updatedAt'),
      provider: providerJson == null
          ? null
          : AdminWithdrawalProvider.fromJson(providerJson),
    );
  }
}

MoneyAmount? _nullableMoney(Object? raw) {
  return raw == null ? null : MoneyAmount.parse(raw);
}
