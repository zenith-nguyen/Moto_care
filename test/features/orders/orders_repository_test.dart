import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/orders/data/orders_repository.dart';
import 'package:moto_care/features/orders/domain/geo_point.dart';
import 'package:moto_care/features/orders/domain/order_status.dart';

import '../../support/recording_json_api.dart';

void main() {
  test('creates an order with the exact backend snake-case contract', () async {
    final api = RecordingJsonApi()..objectResponse = creationJson();
    final repository = HttpOrdersRepository(api);

    final result = await repository.create(
      incidentTypeId: 3,
      customerLocation: GeoPoint(latitude: 10.7769, longitude: 106.7009),
    );

    expect(api.lastMethod, 'POST');
    expect(api.lastPath, '/orders');
    expect(api.lastData, {
      'incident_type_id': 3,
      'customer_location': {'latitude': 10.7769, 'longitude': 106.7009},
    });
    expect(result.status, OrderStatus.awaitingPrepayment);
    expect(result.estimatedPrice.value, '110000.00');
    expect(result.pricing.weatherMultiplier, '1.1000');
  });

  test('parses own order list without calculating money in Flutter', () async {
    final api = RecordingJsonApi()
      ..listResponse = [
        {
          'id': 42,
          'code': 'MC-42',
          'status': 'ACCEPTED',
          'customerId': 7,
          'providerId': 3,
          'incidentTypeId': 1,
          'estimatedPrice': '110000.00',
          'extraCost': '0.00',
          'discountAmount': '0.00',
          'finalPrice': null,
          'createdAt': '2026-10-09T08:00:00.000Z',
          'pricing': pricingJson(),
        },
      ];

    final orders = await HttpOrdersRepository(api).listMine();

    expect(api.lastPath, '/orders');
    expect(orders.single.status, OrderStatus.accepted);
    expect(orders.single.pricing.weatherSurcharge.value, '10000.00');
  });

  test('parses order details and converts GeoJSON longitude first', () async {
    final api = RecordingJsonApi()..objectResponse = detailsJson();

    final details = await HttpOrdersRepository(api).getById(42);

    expect(api.lastPath, '/orders/42');
    expect(details.customerLocation.latitude, 10.7769);
    expect(details.customerLocation.longitude, 106.7009);
    expect(details.providerLocation?.latitude, 10.78);
    expect(details.payment?.isDemo, isTrue);
  });

  test('trims cancellation reason and validates it before HTTP', () async {
    final api = RecordingJsonApi()
      ..objectResponse = {
        'orderId': 42,
        'status': 'REFUND_PENDING',
        'refundAmount': '110000.00',
      };
    final repository = HttpOrdersRepository(api);

    final result = await repository.cancel(42, '  Không cần hỗ trợ nữa  ');

    expect(api.lastPath, '/orders/42/cancel');
    expect(api.lastData, {'reason': 'Không cần hỗ trợ nữa'});
    expect(result.refundAmount?.value, '110000.00');
    await expectLater(repository.cancel(42, 'x'), throwsFormatException);
  });

  test('rejects invalid request coordinates before creating an order', () {
    expect(
      () => GeoPoint(latitude: 91, longitude: 106.7),
      throwsFormatException,
    );
  });
}

Map<String, dynamic> creationJson() => {
  'id': 42,
  'code': 'MC-42',
  'status': 'AWAITING_PREPAYMENT',
  'estimatedPrice': '110000.00',
  'pricing': pricingJson(),
  'matched': false,
  'offerExpiresAt': null,
  'message': 'Awaiting prepayment',
};

Map<String, dynamic> detailsJson() => {
  'id': 42,
  'code': 'MC-42',
  'status': 'ACCEPTED',
  'customerId': 7,
  'providerId': 3,
  'incidentType': {'id': 1, 'name': 'Xẹp lốp'},
  'customerLocation': {
    'type': 'Point',
    'coordinates': [106.7009, 10.7769],
  },
  'estimatedPrice': '110000.00',
  'pricing': pricingJson(),
  'extraCost': '0.00',
  'discountAmount': '0.00',
  'finalPrice': null,
  'payment': {'id': 6, 'amount': '110000.00', 'status': 'PAID', 'isDemo': true},
  'providerLocation': {
    'type': 'Point',
    'coordinates': [106.71, 10.78],
  },
  'message': null,
  'priceProposal': null,
  'paymentAdjustment': null,
};

Map<String, dynamic> pricingJson() => {
  'basePrice': '100000.00',
  'weatherSurcharge': '10000.00',
  'weatherMultiplier': '1.1000',
  'weatherCategory': 'MODERATE',
  'weatherSource': 'OPEN_METEO',
  'weatherObservedAt': '2026-10-09T07:55:00.000Z',
  'weatherCode': 61,
  'precipitationMm': '1.20',
  'windSpeedKmh': '12.00',
  'windGustKmh': '20.00',
  'attribution': 'Weather data by Open-Meteo.com',
};
