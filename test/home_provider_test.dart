import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moto_care/features/activity/models/rescue_order.dart';
import 'package:moto_care/features/activity/providers/activity_provider.dart';
import 'package:moto_care/features/home/models/rescue_location.dart';
import 'package:moto_care/features/home/providers/home_provider.dart';
import 'package:moto_care/features/rescue_station/models/rescue_station.dart';
import 'package:moto_care/features/rescue_station/providers/rescue_station_provider.dart';

RescueStation _station(String id, double latitude, double distance) =>
    RescueStation(
      id: id,
      name: id,
      address: 'Địa chỉ trạm',
      rating: 4.8,
      completedRescues: 10,
      distanceKm: distance,
      isOpen24h: true,
      isVerified: true,
      phoneNumber: '',
      latitude: latitude,
      longitude: 106,
      stationType: StationType.partner,
    );

void main() {
  test('Location confirmation trims notes and rejects invalid drafts without saving', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(rescueLocationProvider.notifier);
    expect(
      controller.confirmLocation(
        const RescueLocation(
          address: ' 180/9a Bùi Văn Ba ',
          landmark: ' Đối diện cây xăng ',
          latitude: 10.75,
          longitude: 106.66,
        ),
      ),
      isTrue,
    );
    final confirmed = container.read(rescueLocationProvider)!;
    expect(confirmed.address, '180/9a Bùi Văn Ba');
    expect(confirmed.landmark, 'Đối diện cây xăng');
    expect(confirmed.latitude, 10.75);
    expect(confirmed.longitude, 106.66);
    for (final draft in [
      const RescueLocation(address: ' '),
      const RescueLocation(address: 'abc'),
      RescueLocation(address: 'x' * 241),
      RescueLocation(address: 'Địa chỉ mới', landmark: 'x' * 241),
    ]) {
      expect(controller.confirmLocation(draft), isFalse);
      expect(container.read(rescueLocationProvider), same(confirmed));
    }
  });

  test(
    'Typed address validates and discards coordinates only when changed',
    () {
      const initial = RescueLocation(
        address: '273 An Dương Vương',
        latitude: 10.75,
        longitude: 106.66,
      );
      final container = ProviderContainer(
        overrides: [initialRescueLocationProvider.overrideWithValue(initial)],
      );
      addTearDown(container.dispose);
      final controller = container.read(rescueLocationProvider.notifier);
      expect(controller.updateAddress(''), isFalse);
      expect(controller.updateAddress('x' * 241), isFalse);
      expect(container.read(rescueLocationProvider), same(initial));
      expect(controller.updateAddress(' 273 An Dương Vương '), isTrue);
      expect(container.read(rescueLocationProvider), same(initial));
      expect(controller.updateAddress(' 45 Lê Văn Sỹ '), isTrue);
      final changed = container.read(rescueLocationProvider)!;
      expect(changed.address, '45 Lê Văn Sỹ');
      expect(changed.latitude, isNull);
      expect(changed.longitude, isNull);
    },
  );

  test(
    'Nearby stations follow injected GPS, then reference distances without GPS',
    () {
      final stations = [_station('far', 10.1, 0.5), _station('near', 10.01, 5)];
      final container = ProviderContainer(
        overrides: [
          initialRescueLocationProvider.overrideWithValue(
            const RescueLocation(
              address: 'Vị trí GPS',
              latitude: 10,
              longitude: 106,
            ),
          ),
          rescueStationsProvider.overrideWithValue(stations),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(homeNearbyStationsProvider).map((item) => item.id),
        ['near', 'far'],
      );
      expect(
        stationDistanceKm(
          stations.last,
          container.read(rescueLocationProvider),
        ),
        closeTo(1.112, 0.01),
      );
      container
          .read(rescueLocationProvider.notifier)
          .updateAddress('Địa chỉ nhập tay');
      expect(
        container.read(homeNearbyStationsProvider).map((item) => item.id),
        ['far', 'near'],
      );
      expect(stations.first.id, 'far');
      expect(
        () => container.read(homeNearbyStationsProvider).clear(),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'Each new order preserves service, trimmed vehicle/address and coordinates',
    () {
      final container = ProviderContainer(
        overrides: [initialRescueOrdersProvider.overrideWithValue([])],
      );
      addTearDown(container.dispose);
      final controller = container.read(activityProvider.notifier);
      for (final service in RescueServiceType.values) {
        final order = controller.createOrder(
          serviceType: service,
          userVehicle: ' Honda Vision (59-A1 123.45) ',
          locationAddress: ' 273 An Dương Vương ',
          locationLatitude: 10.75,
          locationLongitude: 106.66,
          locationLandmark: ' Cổng trường ',
          incidentDescription: ' Xe không đề được ',
        );
        expect(order.serviceType, service);
        expect(order.userVehicle, 'Honda Vision (59-A1 123.45)');
        expect(order.locationAddress, '273 An Dương Vương');
        expect(order.locationLandmark, 'Cổng trường');
        expect(order.incidentDescription, 'Xe không đề được');
        expect(order.status, RescueOrderStatus.pending);
        expect(RescueOrder.fromJson(order.toJson()).toJson(), order.toJson());
        expect(
          order.copyWith(status: RescueOrderStatus.cancelled).locationLatitude,
          10.75,
        );
        expect(
          () => controller.createOrder(
            serviceType: service,
            userVehicle: 'Xe khác',
            locationAddress: 'Địa chỉ khác',
          ),
          throwsStateError,
        );
        expect(controller.cancelOrder(order.id), isTrue);
      }
      expect(
        container.read(activityProvider).orders,
        hasLength(RescueServiceType.values.length),
      );
    },
  );

  test('Invalid input and partial GPS coordinates never create orders', () {
    final container = ProviderContainer(
      overrides: [initialRescueOrdersProvider.overrideWithValue([])],
    );
    addTearDown(container.dispose);
    final controller = container.read(activityProvider.notifier);
    expect(
      () => controller.createOrder(
        serviceType: RescueServiceType.flatTire,
        userVehicle: ' ',
        locationAddress: 'Địa chỉ',
      ),
      throwsArgumentError,
    );
    for (final coords in [
      (10.0, null),
      (91.0, 106.0),
      (10.0, 181.0),
      (double.nan, 106.0),
    ]) {
      expect(
        () => controller.createOrder(
          serviceType: RescueServiceType.flatTire,
          userVehicle: 'Honda Vision',
          locationAddress: 'Địa chỉ',
          locationLatitude: coords.$1,
          locationLongitude: coords.$2,
        ),
        throwsArgumentError,
      );
    }
    expect(container.read(activityProvider).orders, isEmpty);
  });
}
