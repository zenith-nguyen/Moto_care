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
import 'package:moto_care/features/orders/data/orders_repository.dart';
import 'package:moto_care/features/orders/domain/geo_point.dart';
import 'package:moto_care/features/orders/domain/order_action_results.dart';
import 'package:moto_care/features/orders/domain/order_models.dart';
import 'package:moto_care/features/orders/domain/price_decision_result.dart';
import 'package:moto_care/features/providers/application/provider_work_controller.dart';
import 'package:moto_care/features/providers/data/providers_repository.dart';
import 'package:moto_care/features/providers/domain/provider_models.dart';

void main() {
  test('accepts a pending offer and follows the assigned order', () async {
    final providers = FakeProvidersRepository();
    final orders = FakeProviderOrdersRepository();
    final transport = FakeRealtimeTransport();
    final realtime = RealtimeClient(transport);
    final connection = RecordingRealtimeConnection();
    final coordinator = RealtimeSessionCoordinator(
      connection,
      Uri.parse('https://demo.example.test'),
    )..synchronize(const SessionSignedIn(_providerSession));
    final container = ProviderContainer(
      overrides: [
        providersRepositoryProvider.overrideWithValue(providers),
        ordersRepositoryProvider.overrideWithValue(orders),
        realtimeClientProvider.overrideWithValue(realtime),
        realtimeSessionCoordinatorProvider.overrideWithValue(coordinator),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await realtime.dispose();
    });

    final initial = await container.read(providerWorkControllerProvider.future);
    expect(initial.pendingOffers.single.id, 9);

    await container
        .read(providerWorkControllerProvider.notifier)
        .acceptOffer(initial.pendingOffers.single);

    final accepted = container.read(providerWorkControllerProvider).value!;
    expect(orders.acceptCount, 1);
    expect(accepted.pendingOffers, isEmpty);
    expect(accepted.selectedOrder?.id, 42);
    expect(connection.lastScope?.orderId, 42);

    realtime.connect(
      origin: Uri.parse('https://demo.example.test'),
      accessToken: 'test-jwt',
      scope: const RealtimeScope(role: AppRole.provider, orderId: 42),
    );
    transport.payload('offer.created', {
      'orderId': 50,
      'offerId': 10,
      'expiresAt': '2099-10-10T08:00:15.000Z',
    });
    await Future<void>.delayed(Duration.zero);
    expect(providers.offerLoads, greaterThanOrEqualTo(3));
  });
}

const _providerSession = AuthSession(
  accessToken: 'test-jwt',
  user: AppUser(
    id: 8,
    name: 'Provider',
    email: 'provider@example.test',
    phone: null,
    role: AppRole.provider,
    status: AppUserStatus.active,
  ),
);

class FakeProvidersRepository implements ProvidersRepository {
  int offerLoads = 0;

  @override
  Future<List<PendingOffer>> listPendingOffers() async {
    offerLoads += 1;
    return offerLoads == 1 ? [PendingOffer.fromJson(_offerJson())] : [];
  }

  @override
  Future<ProviderPresence> setOnline(bool isOnline) =>
      throw UnimplementedError();

  @override
  Future<ProviderPresence> updateOrderLocation({
    required int orderId,
    required GeoPoint location,
  }) => throw UnimplementedError();

  @override
  Future<ProviderPresence> updateWaitingLocation(GeoPoint location) =>
      throw UnimplementedError();
}

class FakeProviderOrdersRepository implements OrdersRepository {
  int acceptCount = 0;

  @override
  Future<void> acceptOffer({required int orderId, required int offerId}) async {
    acceptCount += 1;
  }

  @override
  Future<OrderDetails> getById(int orderId) async =>
      OrderDetails.fromJson(_detailsJson());

  @override
  Future<List<OrderSummary>> listMine() async =>
      acceptCount == 0 ? [] : [OrderSummary.fromJson(_summaryJson())];

  @override
  Future<void> completeService(int orderId) => throw UnimplementedError();

  @override
  Future<OrderCancellationResult> cancel(int orderId, String reason) =>
      throw UnimplementedError();

  @override
  Future<OrderCreationResult> create({
    required int incidentTypeId,
    required GeoPoint customerLocation,
  }) => throw UnimplementedError();

  @override
  Future<PriceDecisionResult> disputeFinalPrice({
    required int orderId,
    required int proposalId,
    required String reason,
  }) => throw UnimplementedError();

  @override
  Future<ServiceStartToken> getStartToken(int orderId) =>
      throw UnimplementedError();

  @override
  Future<void> markArrived(int orderId) => throw UnimplementedError();

  @override
  Future<PriceDecisionResult> proposeFinalPrice({
    required int orderId,
    required String finalPrice,
    required String reason,
  }) => throw UnimplementedError();

  @override
  Future<void> rejectOffer({required int orderId, required int offerId}) =>
      throw UnimplementedError();

  @override
  Future<OrderCreationResult> retryMatching(int orderId) =>
      throw UnimplementedError();

  @override
  Future<void> startService({required int orderId, required String token}) =>
      throw UnimplementedError();

  @override
  Future<PriceDecisionResult> approveFinalPrice({
    required int orderId,
    required int proposalId,
  }) => throw UnimplementedError();

  @override
  Future<PriceDecisionResult> rejectFinalPrice({
    required int orderId,
    required int proposalId,
    required String reason,
  }) => throw UnimplementedError();
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

Map<String, dynamic> _offerJson() => {
  'id': 9,
  'orderId': 42,
  'expiresAt': '2099-10-10T08:00:15.000Z',
  'order': {
    'code': 'MC-42',
    'incidentType': {'id': 1, 'name': 'Flat tire'},
    'estimatedPrice': '100000.00',
    'pricing': _pricingJson(),
    'customerLocation': {
      'type': 'Point',
      'coordinates': [106.7009, 10.7769],
    },
  },
};

Map<String, dynamic> _summaryJson() => {
  'id': 42,
  'code': 'MC-42',
  'status': 'ACCEPTED',
  'customerId': 7,
  'providerId': 3,
  'incidentTypeId': 1,
  'estimatedPrice': '100000.00',
  'extraCost': '0.00',
  'discountAmount': '0.00',
  'finalPrice': null,
  'createdAt': '2026-10-10T08:00:00.000Z',
  'pricing': _pricingJson(),
};

Map<String, dynamic> _detailsJson() => {
  'id': 42,
  'code': 'MC-42',
  'status': 'ACCEPTED',
  'customerId': 7,
  'providerId': 3,
  'incidentType': {'id': 1, 'name': 'Flat tire'},
  'customerLocation': {
    'type': 'Point',
    'coordinates': [106.7009, 10.7769],
  },
  'estimatedPrice': '100000.00',
  'pricing': _pricingJson(),
  'extraCost': '0.00',
  'discountAmount': '0.00',
  'finalPrice': null,
  'payment': null,
  'providerLocation': null,
  'message': null,
  'priceProposal': null,
  'paymentAdjustment': null,
};

Map<String, dynamic> _pricingJson() => {
  'basePrice': '100000.00',
  'weatherSurcharge': '0.00',
  'weatherMultiplier': '1.0000',
  'weatherCategory': 'DISABLED',
  'weatherSource': 'FALLBACK',
  'weatherObservedAt': null,
  'weatherCode': null,
  'precipitationMm': null,
  'windSpeedKmh': null,
  'windGustKmh': null,
  'attribution': null,
};
