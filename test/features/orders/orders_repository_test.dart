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

  test(
    'loads the short-lived service start token without exposing a secret',
    () async {
      final api = RecordingJsonApi()
        ..objectResponse = {
          'orderId': 42,
          'token': 'opaque-start-token',
          'expiresAt': '2026-10-10T00:05:00.000Z',
        };

      final token = await HttpOrdersRepository(api).getStartToken(42);

      expect(api.lastPath, '/orders/42/start-token');
      expect(token.token, 'opaque-start-token');
    },
  );

  test('approves a final-price proposal through its exact endpoint', () async {
    final api = RecordingJsonApi()..objectResponse = _priceDecisionJson();

    final result = await HttpOrdersRepository(api)
        .approveFinalPrice(orderId: 42, proposalId: 8);

    expect(api.lastPath, '/orders/42/price-proposals/8/approve');
    expect(api.lastData, isNull);
    expect(result.orderStatus, OrderStatus.awaitingPayment);
    expect(result.paymentAdjustment?.amount.value, '25000.00');
  });

  test('rejects a final-price proposal with a trimmed reason', () async {
    final api = RecordingJsonApi()..objectResponse = _priceDecisionJson();

    await HttpOrdersRepository(api).rejectFinalPrice(
      orderId: 42,
      proposalId: 8,
      reason: '  Chưa thống nhất phụ tùng  ',
    );

    expect(api.lastPath, '/orders/42/price-proposals/8/reject');
    expect(api.lastData, {'reason': 'Chưa thống nhất phụ tùng'});
  });

  test('maps provider offer and service commands to exact endpoints', () async {
    final api = RecordingJsonApi()
      ..objectResponse = {'orderId': 42, 'status': 'ACCEPTED'};
    final repository = HttpOrdersRepository(api);

    await repository.acceptOffer(orderId: 42, offerId: 9);
    expect(api.lastPath, '/orders/42/offers/9/accept');
    await repository.markArrived(42);
    expect(api.lastPath, '/orders/42/arrive');
    await repository.startService(
      orderId: 42,
      token: '1760000000000.${'a' * 64}',
    );
    expect(api.lastPath, '/orders/42/start');
    await repository.completeService(42);
    expect(api.lastPath, '/orders/42/complete');
  });

  test('normalizes provider price proposal and dispute contracts', () async {
    final api = RecordingJsonApi()..objectResponse = _priceDecisionJson();
    final repository = HttpOrdersRepository(api);

    await repository.proposeFinalPrice(
      orderId: 42,
      finalPrice: ' 135000.00 ',
      reason: '  Replace damaged inner tube  ',
    );
    expect(api.lastPath, '/orders/42/price-proposals');
    expect(api.lastData, {
      'final_price': '135000.00',
      'reason': 'Replace damaged inner tube',
    });
    await repository.disputeFinalPrice(
      orderId: 42,
      proposalId: 8,
      reason: '  Photo evidence attached  ',
    );
    expect(api.lastPath, '/orders/42/price-proposals/8/dispute');
    expect(api.lastData, {'reason': 'Photo evidence attached'});
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

Map<String, dynamic> _priceDecisionJson() => {
  'orderId': 42,
  'orderStatus': 'AWAITING_PAYMENT',
  'proposal': {
    'id': 8,
    'proposedFinalPrice': '135000.00',
    'reason': 'Thay ruột xe và van',
    'status': 'APPROVED',
    'customerReason': null,
    'disputeReason': null,
    'resolutionReason': null,
  },
  'paymentAdjustment': {
    'id': 9,
    'type': 'CHARGE',
    'amount': '25000.00',
    'status': 'PENDING',
    'isDemo': true,
    'settledAt': null,
  },
};
