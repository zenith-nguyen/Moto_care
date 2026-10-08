import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/core/providers/attachment_provider.dart';
import 'package:moto_care/core/services/attachment_service.dart';
import 'package:moto_care/features/activity/providers/activity_provider.dart';
import 'package:moto_care/features/activity/services/rescue_order_service.dart';
import 'package:moto_care/features/home/models/rescue_location.dart';
import 'package:moto_care/features/home/providers/home_provider.dart';
import 'package:moto_care/features/location/providers/location_search_provider.dart';
import 'package:moto_care/features/location/services/device_location_service.dart';
import 'package:moto_care/features/location/services/places_service.dart';
import 'package:moto_care/features/partner/models/marketplace_catalog.dart';
import 'package:moto_care/features/partner/providers/partner_registration_draft_provider.dart';
import 'package:moto_care/features/partner/providers/partner_registration_provider.dart';
import 'package:moto_care/features/rescue/models/marketplace_booking.dart';
import 'package:moto_care/features/rescue/providers/checkout_provider.dart';
import 'package:moto_care/features/rescue/providers/tracking_chat_provider.dart';
import 'package:moto_care/features/vehicle/models/vehicle.dart';
import 'package:moto_care/features/vehicle/providers/vehicle_provider.dart';

import 'fixtures/location_fixture.dart';

const _vehicle = Vehicle(
  id: 'vehicle-1',
  name: 'Vision',
  brand: 'Honda',
  licensePlate: '59-X1 123.45',
  tireType: TireType.tubeless,
  engineType: EngineType.gas,
  isDefault: true,
);
const _location = RescueLocation(address: '273 An Dương Vương, Quận 5');
MarketplaceBooking _booking() => MarketplaceBooking(
  partnerId: 'station-tuan',
  serviceType: 'Vá xe',
  items: [MarketplaceCatalog.packages[1].item(1)],
);

void main() {
  test('Checkout drafts are isolated even for the same booking', () {
    final container = ProviderContainer(
      overrides: [
        initialRescueOrdersProvider.overrideWithValue([]),
        initialRescueLocationProvider.overrideWithValue(_location),
        initialVehiclesProvider.overrideWithValue([_vehicle]),
      ],
    );
    addTearDown(container.dispose);
    final booking = _booking();
    final first = (Object(), booking);
    final second = (Object(), booking);
    container.listen(checkoutProvider(first), (_, next) {});
    container.listen(checkoutProvider(second), (_, next) {});
    container
        .read(checkoutProvider(first).notifier)
        .editAddress('Địa chỉ mới tại Quận 7');
    expect(
      container.read(checkoutProvider(second)).location!.address,
      _location.address,
    );
    expect(container.read(rescueLocationProvider)!.address, _location.address);
    expect(container.read(activityProvider).orders, isEmpty);
  });

  test(
    'Fresh Checkout quote rejects a changed fee and saves the full total',
    () {
      final container = ProviderContainer(
        overrides: [
          initialRescueOrdersProvider.overrideWithValue([]),
          initialRescueLocationProvider.overrideWithValue(_location),
          initialVehiclesProvider.overrideWithValue([_vehicle]),
        ],
      );
      addTearDown(container.dispose);
      final key = (Object(), _booking());
      container.listen(checkoutProvider(key), (_, next) {});
      final controller = container.read(checkoutProvider(key).notifier);
      final quote = container.read(checkoutQuoteProvider(key));
      expect(controller.placeOrder(quote.travelFee + 1), isNull);
      expect(container.read(activityProvider).orders, isEmpty);
      expect(container.read(checkoutProvider(key)).submitting, isFalse);
      expect(controller.placeOrder(quote.travelFee), isNotNull);
      expect(container.read(activityProvider).orders.single.discount, 0);
      expect(
        container.read(activityProvider).orders.single.voucherCode,
        isEmpty,
      );
      expect(
        container.read(activityProvider).orders.single.totalPrice,
        quote.total,
      );
    },
  );

  test(
    'Checkout ignores GPS after manual editing and after disposal',
    () async {
      final gps = Completer<RescueLocation>();
      final container = ProviderContainer(
        overrides: [deviceLocationProvider.overrideWithValue(() => gps.future)],
      );
      final key = (Object(), _booking());
      container.listen(checkoutProvider(key), (_, next) {});
      final controller = container.read(checkoutProvider(key).notifier);
      final pending = controller.locate();
      controller.editAddress('Địa chỉ nhập tay tại Quận 7');
      gps.complete(testPlaceLocation);
      await pending;
      expect(
        container.read(checkoutProvider(key)).location!.address,
        'Địa chỉ nhập tay tại Quận 7',
      );
      expect(container.read(rescueLocationProvider), isNull);
      container.dispose();

      final lateGps = Completer<RescueLocation>();
      final disposed = ProviderContainer(
        overrides: [
          deviceLocationProvider.overrideWithValue(() => lateGps.future),
        ],
      );
      disposed.listen(checkoutProvider(key), (_, next) {});
      final lateResult = disposed.read(checkoutProvider(key).notifier).locate();
      disposed.dispose();
      lateGps.complete(testPlaceLocation);
      await lateResult;
    },
  );

  test('Place details cannot commit a result after a newer query', () async {
    final details = Completer<RescueLocation>();
    final container = ProviderContainer(
      overrides: [
        placesServiceProvider.overrideWithValue(
          TestPlacesService(lookup: (_) => details.future),
        ),
      ],
    );
    addTearDown(container.dispose);
    final key = (Object(), null);
    container.listen(locationSearchProvider(key), (_, next) {});
    final controller = container.read(locationSearchProvider(key).notifier);
    final result = controller.selectSuggestion(testPlace);
    controller.editQuery('Địa chỉ khác');
    details.complete(testPlaceLocation);
    expect(await result, isNull);
    expect(
      container.read(locationSearchProvider(key)).source.hasCoordinates,
      isFalse,
    );
    expect(container.read(rescueLocationProvider), isNull);
  });

  test('Attachment controller prevents duplicate picker requests and ignores disposed results', () async {
    final picked = Completer<Uint8List?>();
    var calls = 0;
    final container = ProviderContainer(
      overrides: [
        attachmentPickerProvider.overrideWithValue(() {
          calls++;
          return picked.future;
        }),
      ],
    );
    final key = Object();
    container.listen(attachmentProvider(key), (_, next) {});
    final controller = container.read(attachmentProvider(key).notifier);
    final first = controller.pick(useCamera: false);
    expect(await controller.pick(useCamera: false), isNull);
    expect(calls, 1);
    container.dispose();
    picked.complete(Uint8List.fromList([1, 2, 3]));
    expect(await first, isNull);
  });

  test('Partner identity drafts copy sensitive bytes and submit only once', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final key = Object();
    container.listen(partnerRegistrationDraftProvider(key), (_, next) {});
    final controller = container.read(
      partnerRegistrationDraftProvider(key).notifier,
    );
    final front = Uint8List.fromList([1, 2]);
    controller.attachFront(front);
    front[0] = 99;
    controller.attachBack(Uint8List.fromList([3, 4]));
    controller.selectExperience('3 - 5 năm');
    controller.selectTool('Bơm điện', true);
    controller.selectDistrict('Quận 3');
    expect(controller.submit('Nguyễn Minh Tuấn', '012345678901'), isTrue);
    expect(controller.submit('Nguyễn Minh Tuấn', '012345678901'), isFalse);
    final saved = container.read(partnerApplicationsProvider).single;
    expect(saved.frontPhoto.first, 1);
    expect(() => saved.frontPhoto[0] = 7, throwsUnsupportedError);
    expect(saved.tools, {'Bơm điện'});
  });

  test(
    'Tracking conversations remain separate and have no fabricated replies',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final first = (Object(), 'order-1');
      final second = (Object(), 'order-2');
      container.listen(trackingChatProvider(first), (_, next) {});
      container.listen(trackingChatProvider(second), (_, next) {});
      final controller = container.read(trackingChatProvider(first).notifier);
      expect(controller.send('   '), isFalse);
      expect(controller.send('  Tôi đang ở cổng trường  '), isTrue);
      expect(
        container.read(trackingChatProvider(first)).single.text,
        'Tôi đang ở cổng trường',
      );
      expect(container.read(trackingChatProvider(second)), isEmpty);
      expect(
        () => container.read(trackingChatProvider(first)).clear(),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'Order creation uses the injected clock and preserves displayed prices',
    () {
      final now = DateTime(2026, 10, 8, 9, 30);
      final container = ProviderContainer(
        overrides: [
          initialRescueOrdersProvider.overrideWithValue([]),
          rescueOrderClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
      final item = MarketplaceCatalog.packages[1].item(2);
      final order = container
          .read(activityProvider.notifier)
          .createOrder(
            serviceType: item.serviceType,
            userVehicle: 'Honda Vision',
            locationAddress: _location.address,
            basePrice: 125000,
            travelFee: 25000,
            discount: 20000,
            items: [item],
          );
      expect(order.createdAt, now);
      expect(order.orderCode, 'MC-20261008-001');
      expect(order.totalPrice, 105000);
      expect(order.items.single.quantity, 2);
    },
  );
}
