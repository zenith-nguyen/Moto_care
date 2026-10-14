import '../../../core/money/money_amount.dart';
import '../../../core/network/json_reader.dart';
import 'geo_point.dart';
import 'order_pricing.dart';
import 'order_status.dart';

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.code,
    required this.status,
    required this.customerId,
    required this.providerId,
    required this.incidentTypeId,
    required this.estimatedPrice,
    required this.extraCost,
    required this.discountAmount,
    required this.finalPrice,
    required this.createdAt,
    required this.pricing,
  });

  final int id;
  final String code;
  final OrderStatus status;
  final int customerId;
  final int? providerId;
  final int incidentTypeId;
  final MoneyAmount estimatedPrice;
  final MoneyAmount extraCost;
  final MoneyAmount discountAmount;
  final MoneyAmount? finalPrice;
  final DateTime createdAt;
  final OrderPricing pricing;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return OrderSummary(
      id: reader.positiveInt('id'),
      code: reader.string('code'),
      status: OrderStatus.fromWire(reader.value('status')),
      customerId: reader.positiveInt('customerId'),
      providerId: reader.nullablePositiveInt('providerId'),
      incidentTypeId: reader.positiveInt('incidentTypeId'),
      estimatedPrice: MoneyAmount.parse(reader.value('estimatedPrice')),
      extraCost: MoneyAmount.parse(reader.value('extraCost')),
      discountAmount: MoneyAmount.parse(reader.value('discountAmount')),
      finalPrice: _nullableMoney(reader.value('finalPrice')),
      createdAt: reader.dateTime('createdAt'),
      pricing: OrderPricing.fromJson(reader.object('pricing')),
    );
  }
}

class OrderCreationResult {
  const OrderCreationResult({
    required this.id,
    required this.code,
    required this.status,
    required this.estimatedPrice,
    required this.pricing,
    required this.matched,
    required this.offerExpiresAt,
    required this.message,
  });

  final int id;
  final String code;
  final OrderStatus status;
  final MoneyAmount estimatedPrice;
  final OrderPricing pricing;
  final bool matched;
  final DateTime? offerExpiresAt;
  final String? message;

  factory OrderCreationResult.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return OrderCreationResult(
      id: reader.positiveInt('id'),
      code: reader.string('code'),
      status: OrderStatus.fromWire(reader.value('status')),
      estimatedPrice: MoneyAmount.parse(reader.value('estimatedPrice')),
      pricing: OrderPricing.fromJson(reader.object('pricing')),
      matched: reader.boolean('matched'),
      offerExpiresAt: reader.nullableDateTime('offerExpiresAt'),
      message: reader.nullableString('message'),
    );
  }
}

class IncidentSummary {
  const IncidentSummary({required this.id, required this.name});

  final int id;
  final String name;

  factory IncidentSummary.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return IncidentSummary(
      id: reader.positiveInt('id'),
      name: reader.string('name'),
    );
  }
}

class OrderPaymentSummary {
  const OrderPaymentSummary({
    required this.id,
    required this.amount,
    required this.status,
    required this.isDemo,
  });

  final int id;
  final MoneyAmount amount;
  final PaymentStatus status;
  final bool isDemo;

  factory OrderPaymentSummary.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return OrderPaymentSummary(
      id: reader.positiveInt('id'),
      amount: MoneyAmount.parse(reader.value('amount')),
      status: PaymentStatus.fromWire(reader.value('status')),
      isDemo: reader.boolean('isDemo'),
    );
  }
}

class PriceProposal {
  const PriceProposal({
    required this.id,
    required this.proposedFinalPrice,
    required this.reason,
    required this.status,
    required this.customerReason,
    required this.disputeReason,
    required this.resolutionReason,
  });

  final int id;
  final MoneyAmount proposedFinalPrice;
  final String reason;
  final PriceProposalStatus status;
  final String? customerReason;
  final String? disputeReason;
  final String? resolutionReason;

  factory PriceProposal.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return PriceProposal(
      id: reader.positiveInt('id'),
      proposedFinalPrice: MoneyAmount.parse(reader.value('proposedFinalPrice')),
      reason: reader.string('reason'),
      status: PriceProposalStatus.fromWire(reader.value('status')),
      customerReason: reader.nullableString('customerReason'),
      disputeReason: reader.nullableString('disputeReason'),
      resolutionReason: reader.nullableString('resolutionReason'),
    );
  }
}

class PaymentAdjustment {
  const PaymentAdjustment({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.isDemo,
    required this.settledAt,
  });

  final int id;
  final PaymentAdjustmentType type;
  final MoneyAmount amount;
  final PaymentAdjustmentStatus status;
  final bool isDemo;
  final DateTime? settledAt;

  factory PaymentAdjustment.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return PaymentAdjustment(
      id: reader.positiveInt('id'),
      type: PaymentAdjustmentType.fromWire(reader.value('type')),
      amount: MoneyAmount.parse(reader.value('amount')),
      status: PaymentAdjustmentStatus.fromWire(reader.value('status')),
      isDemo: reader.boolean('isDemo'),
      settledAt: reader.nullableDateTime('settledAt'),
    );
  }
}

class OrderDetails {
  const OrderDetails({
    required this.id,
    required this.code,
    required this.status,
    required this.customerId,
    required this.providerId,
    required this.incidentType,
    required this.customerLocation,
    required this.estimatedPrice,
    required this.pricing,
    required this.extraCost,
    required this.discountAmount,
    required this.finalPrice,
    required this.payment,
    required this.providerLocation,
    required this.message,
    required this.priceProposal,
    required this.paymentAdjustment,
  });

  final int id;
  final String code;
  final OrderStatus status;
  final int customerId;
  final int? providerId;
  final IncidentSummary incidentType;
  final GeoPoint customerLocation;
  final MoneyAmount estimatedPrice;
  final OrderPricing pricing;
  final MoneyAmount extraCost;
  final MoneyAmount discountAmount;
  final MoneyAmount? finalPrice;
  final OrderPaymentSummary? payment;
  final GeoPoint? providerLocation;
  final String? message;
  final PriceProposal? priceProposal;
  final PaymentAdjustment? paymentAdjustment;

  OrderDetails copyWith({
    OrderStatus? status,
    Object? providerLocation = _unchanged,
  }) {
    return OrderDetails(
      id: id,
      code: code,
      status: status ?? this.status,
      customerId: customerId,
      providerId: providerId,
      incidentType: incidentType,
      customerLocation: customerLocation,
      estimatedPrice: estimatedPrice,
      pricing: pricing,
      extraCost: extraCost,
      discountAmount: discountAmount,
      finalPrice: finalPrice,
      payment: payment,
      providerLocation: identical(providerLocation, _unchanged)
          ? this.providerLocation
          : providerLocation as GeoPoint?,
      message: message,
      priceProposal: priceProposal,
      paymentAdjustment: paymentAdjustment,
    );
  }

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final payment = reader.nullableObject('payment');
    final providerLocation = reader.nullableObject('providerLocation');
    final priceProposal = reader.nullableObject('priceProposal');
    final paymentAdjustment = reader.nullableObject('paymentAdjustment');
    return OrderDetails(
      id: reader.positiveInt('id'),
      code: reader.string('code'),
      status: OrderStatus.fromWire(reader.value('status')),
      customerId: reader.positiveInt('customerId'),
      providerId: reader.nullablePositiveInt('providerId'),
      incidentType: IncidentSummary.fromJson(reader.object('incidentType')),
      customerLocation: GeoPoint.fromGeoJson(reader.object('customerLocation')),
      estimatedPrice: MoneyAmount.parse(reader.value('estimatedPrice')),
      pricing: OrderPricing.fromJson(reader.object('pricing')),
      extraCost: MoneyAmount.parse(reader.value('extraCost')),
      discountAmount: MoneyAmount.parse(reader.value('discountAmount')),
      finalPrice: _nullableMoney(reader.value('finalPrice')),
      payment: payment == null ? null : OrderPaymentSummary.fromJson(payment),
      providerLocation: providerLocation == null
          ? null
          : GeoPoint.fromGeoJson(providerLocation),
      message: reader.nullableString('message'),
      priceProposal: priceProposal == null
          ? null
          : PriceProposal.fromJson(priceProposal),
      paymentAdjustment: paymentAdjustment == null
          ? null
          : PaymentAdjustment.fromJson(paymentAdjustment),
    );
  }
}

MoneyAmount? _nullableMoney(Object? raw) {
  return raw == null ? null : MoneyAmount.parse(raw);
}

const _unchanged = Object();
