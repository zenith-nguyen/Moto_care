import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/app_dependencies.dart';
import 'package:moto_care/core/device/device_location_source.dart';
import 'package:moto_care/core/realtime/realtime_client.dart';
import 'package:moto_care/core/realtime/realtime_session_coordinator.dart';
import 'package:moto_care/features/orders/domain/geo_point.dart';
import 'package:moto_care/features/providers/application/provider_location_tracking_controller.dart';
import 'package:moto_care/features/providers/application/provider_location_tracking_state.dart';
import 'package:moto_care/features/providers/data/providers_repository.dart';
import 'package:moto_care/features/providers/domain/provider_models.dart';

void main() {
  test('moves from waiting GPS to active-order GPS and offline', () async {
    final location = FakeDeviceLocationSource();
    final providers = FakeTrackingProvidersRepository();
    final coordinator = RealtimeSessionCoordinator(
      NoopRealtimeConnection(),
      Uri.parse('https://demo.example.test'),
    );
    final container = ProviderContainer(
      overrides: [
        deviceLocationSourceProvider.overrideWithValue(location),
        providersRepositoryProvider.overrideWithValue(providers),
        realtimeSessionCoordinatorProvider.overrideWithValue(coordinator),
      ],
    );
    addTearDown(() {
      container.dispose();
      coordinator.dispose();
    });

    await container.read(providerLocationTrackingControllerProvider.future);
    final controller = container.read(
      providerLocationTrackingControllerProvider.notifier,
    );

    await controller.goOnline();
    var current = container
        .read(providerLocationTrackingControllerProvider)
        .value!;
    expect(current.mode, ProviderLocationMode.waiting);
    expect(providers.waitingUpdates, 1);
    expect(providers.onlineValues, [true]);

    await controller.trackOrder(42);
    current = container.read(providerLocationTrackingControllerProvider).value!;
    expect(current.mode, ProviderLocationMode.activeOrder);
    expect(current.orderId, 42);
    expect(providers.orderUpdates, [42]);

    await controller.goOffline();
    current = container.read(providerLocationTrackingControllerProvider).value!;
    expect(current.mode, ProviderLocationMode.offline);
    expect(current.orderId, isNull);
    expect(providers.onlineValues, [true, false]);
  });

  test('keeps permission failure in state without going online', () async {
    final location = FakeDeviceLocationSource(
      failure: const DeviceLocationException(
        DeviceLocationFailureKind.permissionDenied,
        'denied',
      ),
    );
    final providers = FakeTrackingProvidersRepository();
    final coordinator = RealtimeSessionCoordinator(
      NoopRealtimeConnection(),
      Uri.parse('https://demo.example.test'),
    );
    final container = ProviderContainer(
      overrides: [
        deviceLocationSourceProvider.overrideWithValue(location),
        providersRepositoryProvider.overrideWithValue(providers),
        realtimeSessionCoordinatorProvider.overrideWithValue(coordinator),
      ],
    );
    addTearDown(() {
      container.dispose();
      coordinator.dispose();
    });

    await container.read(providerLocationTrackingControllerProvider.future);
    await container
        .read(providerLocationTrackingControllerProvider.notifier)
        .goOnline();

    final current = container
        .read(providerLocationTrackingControllerProvider)
        .value!;
    expect(current.mode, ProviderLocationMode.offline);
    expect(current.lastFailure, isA<DeviceLocationException>());
    expect(providers.onlineValues, isEmpty);
  });
}

class FakeDeviceLocationSource implements DeviceLocationSource {
  FakeDeviceLocationSource({this.failure});

  final Object? failure;
  var calls = 0;

  @override
  Future<GeoPoint> currentLocation() async {
    calls += 1;
    if (failure case final error?) throw error;
    return GeoPoint(latitude: 10.7769, longitude: 106.7009);
  }

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}

class FakeTrackingProvidersRepository implements ProvidersRepository {
  var waitingUpdates = 0;
  final List<int> orderUpdates = [];
  final List<bool> onlineValues = [];

  @override
  Future<ProviderPresence> updateWaitingLocation(GeoPoint location) async {
    waitingUpdates += 1;
    return _presence(onlineValues.isEmpty ? false : onlineValues.last);
  }

  @override
  Future<ProviderPresence> setOnline(bool isOnline) async {
    onlineValues.add(isOnline);
    return _presence(isOnline);
  }

  @override
  Future<ProviderPresence> updateOrderLocation({
    required int orderId,
    required GeoPoint location,
  }) async {
    orderUpdates.add(orderId);
    return _presence(true);
  }

  @override
  Future<List<PendingOffer>> listPendingOffers() async => const [];
}

ProviderPresence _presence(bool online) => ProviderPresence(
  providerId: 3,
  isOnline: online,
  lastSeenAt: DateTime.utc(2026, 10, 11),
);

class NoopRealtimeConnection implements RealtimeConnection {
  @override
  void connect({
    required Uri origin,
    required String accessToken,
    required RealtimeScope scope,
  }) {}

  @override
  void disconnect() {}
}
