import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/app_dependencies.dart';
import 'package:moto_care/core/realtime/realtime_client.dart';
import 'package:moto_care/core/realtime/realtime_session_coordinator.dart';
import 'package:moto_care/core/realtime/realtime_transport.dart';
import 'package:moto_care/features/auth/application/session_state.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';
import 'package:moto_care/features/auth/domain/auth_session.dart';
import 'package:moto_care/features/incidents/data/incident_types_repository.dart';
import 'package:moto_care/features/incidents/domain/incident_type.dart';
import 'package:moto_care/features/orders/application/customer_orders_controller.dart';
import 'package:moto_care/features/orders/data/orders_repository.dart';
import 'package:moto_care/features/orders/domain/geo_point.dart';
import 'package:moto_care/features/orders/domain/order_action_results.dart';
import 'package:moto_care/features/orders/domain/order_models.dart';
import 'package:moto_care/features/orders/domain/order_status.dart';
import 'package:moto_care/features/orders/domain/price_decision_result.dart';
import 'package:moto_care/features/payments/data/payments_repository.dart';
import 'package:moto_care/features/payments/domain/bank_transfer_instructions.dart';
import 'package:moto_care/features/payments/domain/demo_payment_result.dart';

void main() {
  test('loads customer data, creates an order, follows its room, and reloads after payment', () async {
    final orders = FakeOrdersRepository();
    final payments = FakePaymentsRepository();
    final transport = FakeRealtimeTransport();
    final realtime = RealtimeClient(transport);
    final connection = RecordingRealtimeConnection();
    final coordinator = RealtimeSessionCoordinator(
      connection,
      Uri.parse('https://demo.example.test'),
    )..synchronize(const SessionSignedIn(_customerSession));
    final container = ProviderContainer(
      overrides: [
        incidentTypesRepositoryProvider.overrideWithValue(
          FakeIncidentTypesRepository(),
        ),
        ordersRepositoryProvider.overrideWithValue(orders),
        paymentsRepositoryProvider.overrideWithValue(payments),
        realtimeClientProvider.overrideWithValue(realtime),
        realtimeSessionCoordinatorProvider.overrideWithValue(coordinator),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await realtime.dispose();
    });

    final initial = await container.read(
      customerOrdersControllerProvider.future,
    );

    expect(initial.incidentTypes.single.name, 'Xẹp lốp');
    expect(initial.orders, isEmpty);

    await container
        .read(customerOrdersControllerProvider.notifier)
        .createOrder(
          incidentTypeId: 1,
          customerLocation: GeoPoint(latitude: 10.7769, longitude: 106.7009),
        );

    final created = container.read(customerOrdersControllerProvider).value!;
    expect(orders.createCount, 1);
    expect(created.selectedOrder?.id, 42);
    expect(created.orders.single.id, 42);
    expect(connection.lastScope?.orderId, 42);

    realtime.connect(
      origin: Uri.parse('https://demo.example.test'),
      accessToken: 'test-jwt',
      scope: const RealtimeScope(role: AppRole.customer, orderId: 42),
    );
    transport.payload('provider.location_updated', {
      'orderId': 42,
      'providerId': 3,
      'latitude': 10.78,
      'longitude': 106.71,
      'updatedAt': '2026-10-09T08:00:10.000Z',
    });
    expect(
      container
          .read(customerOrdersControllerProvider)
          .value
          ?.selectedOrder
          ?.providerLocation
          ?.latitude,
      10.78,
    );

    transport.payload('order.status_changed', {
      'orderId': 42,
      'status': 'OFFERED',
    });
    expect(
      container
          .read(customerOrdersControllerProvider)
          .value
          ?.selectedOrder
          ?.status,
      OrderStatus.offered,
    );
    await Future<void>.delayed(Duration.zero);

    await container
        .read(customerOrdersControllerProvider.notifier)
        .confirmDemoPrepayment();

    final paid = container.read(customerOrdersControllerProvider).value!;
    expect(payments.prepaymentConfirmCount, 1);
    expect(orders.detailsLoadCount, 3);
    expect(paid.lastFailure, isNull);
    expect(paid.action, isNull);

    await container
        .read(customerOrdersControllerProvider.notifier)
        .loadServiceStartToken();
    expect(
      container
          .read(customerOrdersControllerProvider)
          .value
          ?.serviceStartToken
          ?.token,
      'opaque-start-token',
    );

    await container
        .read(customerOrdersControllerProvider.notifier)
        .approveFinalPrice();
    expect(orders.approveCount, 1);

    await container
        .read(customerOrdersControllerProvider.notifier)
        .rejectFinalPrice(' Chưa đồng ý phụ tùng ');
    expect(orders.rejectCount, 1);
    expect(orders.lastRejectReason, ' Chưa đồng ý phụ tùng ');
  });
}

const _customerSession = AuthSession(
  accessToken: 'test-jwt',
  user: AppUser(
    id: 7,
    name: 'Customer',
    email: 'customer@example.test',
    phone: null,
    role: AppRole.customer,
    status: AppUserStatus.active,
  ),
);

class FakeIncidentTypesRepository implements IncidentTypesRepository {
  @override
  Future<List<IncidentType>> listActive() async => [
    IncidentType.fromJson({
      'id': 1,
      'code': 'FLAT_TIRE',
      'name': 'Xẹp lốp',
      'basePrice': '100000.00',
    }),
  ];
}

class FakeOrdersRepository implements OrdersRepository {
  int createCount = 0;
  int detailsLoadCount = 0;
  int approveCount = 0;
  int rejectCount = 0;
  String? lastRejectReason;
  bool _created = false;

  @override
  Future<void> acceptOffer({required int orderId, required int offerId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> completeService(int orderId) {
    throw UnimplementedError();
  }

  @override
  Future<PriceDecisionResult> disputeFinalPrice({
    required int orderId,
    required int proposalId,
    required String reason,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> markArrived(int orderId) {
    throw UnimplementedError();
  }

  @override
  Future<PriceDecisionResult> proposeFinalPrice({
    required int orderId,
    required String finalPrice,
    required String reason,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> rejectOffer({required int orderId, required int offerId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> startService({required int orderId, required String token}) {
    throw UnimplementedError();
  }

  @override
  Future<List<OrderSummary>> listMine() async => _created
      ? [OrderSummary.fromJson(_summaryJson())]
      : const <OrderSummary>[];

  @override
  Future<OrderCreationResult> create({
    required int incidentTypeId,
    required GeoPoint customerLocation,
  }) async {
    createCount += 1;
    _created = true;
    return OrderCreationResult.fromJson(_creationJson());
  }

  @override
  Future<OrderDetails> getById(int orderId) async {
    detailsLoadCount += 1;
    return OrderDetails.fromJson(_detailsJson());
  }

  @override
  Future<OrderCancellationResult> cancel(int orderId, String reason) {
    throw UnimplementedError();
  }

  @override
  Future<PriceDecisionResult> approveFinalPrice({
    required int orderId,
    required int proposalId,
  }) async {
    approveCount += 1;
    return PriceDecisionResult.fromJson(_priceDecisionJson());
  }

  @override
  Future<ServiceStartToken> getStartToken(int orderId) async {
    return ServiceStartToken.fromJson({
      'orderId': orderId,
      'token': 'opaque-start-token',
      'expiresAt': '2026-10-10T00:05:00.000Z',
    });
  }

  @override
  Future<OrderCreationResult> retryMatching(int orderId) {
    throw UnimplementedError();
  }

  @override
  Future<PriceDecisionResult> rejectFinalPrice({
    required int orderId,
    required int proposalId,
    required String reason,
  }) async {
    rejectCount += 1;
    lastRejectReason = reason;
    return PriceDecisionResult.fromJson(_priceDecisionJson());
  }
}

class FakePaymentsRepository implements PaymentsRepository {
  int prepaymentConfirmCount = 0;

  @override
  Future<DemoPrepaymentResult> confirmDemoPrepayment(int orderId) async {
    prepaymentConfirmCount += 1;
    return const DemoPrepaymentResult(
      orderId: 42,
      orderStatus: OrderStatus.pendingMatch,
      paymentStatus: PaymentStatus.paid,
      matched: true,
    );
  }

  @override
  Future<DemoAdjustmentResult> confirmDemoAdjustment(int orderId) {
    throw UnimplementedError();
  }

  @override
  Future<BankTransferInstructions> getTestModeInstructions(int orderId) {
    throw UnimplementedError();
  }
}

class RecordingRealtimeConnection implements RealtimeConnection {
  RealtimeScope? lastScope;

  @override
  void connect({
    required Uri origin,
    required String accessToken,
    required RealtimeScope scope,
  }) {
    lastScope = scope;
  }

  @override
  void disconnect() {}
}

class FakeRealtimeTransport implements RealtimeTransport {
  final StreamController<RealtimeTransportEvent> _events =
      StreamController<RealtimeTransportEvent>.broadcast(sync: true);

  @override
  Stream<RealtimeTransportEvent> get events => _events.stream;

  @override
  void connect({required Uri origin, required Map<String, Object> auth}) {}

  @override
  void disconnect() {}

  void payload(String name, Object? data) {
    _events.add(RealtimeTransportPayload(name, data));
  }

  @override
  Future<void> dispose() => _events.close();
}

Map<String, dynamic> _creationJson() => {
  'id': 42,
  'code': 'MC-42',
  'status': 'AWAITING_PREPAYMENT',
  'estimatedPrice': '110000.00',
  'pricing': _pricingJson(),
  'matched': false,
  'offerExpiresAt': null,
  'message': 'Awaiting prepayment',
};

Map<String, dynamic> _summaryJson() => {
  'id': 42,
  'code': 'MC-42',
  'status': 'AWAITING_PREPAYMENT',
  'customerId': 7,
  'providerId': null,
  'incidentTypeId': 1,
  'estimatedPrice': '110000.00',
  'extraCost': '0.00',
  'discountAmount': '0.00',
  'finalPrice': null,
  'createdAt': '2026-10-09T08:00:00.000Z',
  'pricing': _pricingJson(),
};

Map<String, dynamic> _detailsJson() => {
  'id': 42,
  'code': 'MC-42',
  'status': 'AWAITING_PREPAYMENT',
  'customerId': 7,
  'providerId': null,
  'incidentType': {'id': 1, 'name': 'Xẹp lốp'},
  'customerLocation': {
    'type': 'Point',
    'coordinates': [106.7009, 10.7769],
  },
  'estimatedPrice': '110000.00',
  'pricing': _pricingJson(),
  'extraCost': '0.00',
  'discountAmount': '0.00',
  'finalPrice': null,
  'payment': null,
  'providerLocation': null,
  'message': null,
  'priceProposal': {
    'id': 8,
    'proposedFinalPrice': '135000.00',
    'reason': 'Thay ruột xe và van',
    'status': 'PENDING',
    'customerReason': null,
    'disputeReason': null,
    'resolutionReason': null,
  },
  'paymentAdjustment': null,
};

Map<String, dynamic> _pricingJson() => {
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
