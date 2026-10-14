import '../../../core/network/json_reader.dart';
import '../../../core/money/money_amount.dart';
import '../../orders/domain/geo_point.dart';
import '../../orders/domain/order_models.dart';
import '../../orders/domain/order_pricing.dart';

class ProviderPresence {
  const ProviderPresence({
    required this.providerId,
    required this.isOnline,
    required this.lastSeenAt,
  });

  final int providerId;
  final bool isOnline;
  final DateTime? lastSeenAt;

  factory ProviderPresence.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return ProviderPresence(
      providerId: reader.positiveInt('id'),
      isOnline: reader.boolean('isOnline'),
      lastSeenAt: reader.nullableDateTime('lastSeenAt'),
    );
  }
}

class PendingOffer {
  const PendingOffer({
    required this.id,
    required this.orderId,
    required this.expiresAt,
    required this.order,
  });

  final int id;
  final int orderId;
  final DateTime expiresAt;
  final PendingOfferOrder order;

  bool get isExpired => !expiresAt.isAfter(DateTime.now().toUtc());

  factory PendingOffer.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return PendingOffer(
      id: reader.positiveInt('id'),
      orderId: reader.positiveInt('orderId'),
      expiresAt: reader.dateTime('expiresAt'),
      order: PendingOfferOrder.fromJson(reader.object('order')),
    );
  }
}

class PendingOfferOrder {
  const PendingOfferOrder({
    required this.code,
    required this.incidentType,
    required this.estimatedPrice,
    required this.pricing,
    required this.customerLocation,
  });

  final String code;
  final IncidentSummary incidentType;
  final MoneyAmount estimatedPrice;
  final OrderPricing pricing;
  final GeoPoint customerLocation;

  factory PendingOfferOrder.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return PendingOfferOrder(
      code: reader.string('code'),
      incidentType: IncidentSummary.fromJson(reader.object('incidentType')),
      estimatedPrice: MoneyAmount.parse(reader.value('estimatedPrice')),
      pricing: OrderPricing.fromJson(reader.object('pricing')),
      customerLocation: GeoPoint.fromGeoJson(reader.object('customerLocation')),
    );
  }
}
