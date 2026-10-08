import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/activity/models/rescue_order.dart';
import 'package:moto_care/features/activity/providers/activity_provider.dart';
import 'package:moto_care/features/activity/widgets/order_summary.dart';
import 'package:moto_care/features/home/models/rescue_location.dart';
import 'package:moto_care/features/home/providers/home_provider.dart';
import 'package:moto_care/features/home/theme/home_theme.dart';
import 'package:moto_care/features/location/services/device_location_service.dart';
import 'package:moto_care/features/partner/models/marketplace_catalog.dart';
import 'package:moto_care/features/partner/providers/partner_provider.dart';
import 'package:moto_care/features/rescue/models/marketplace_booking.dart';
import 'package:moto_care/features/rescue/screens/checkout_screen.dart';
import 'package:moto_care/features/rescue/screens/order_tracking_screen.dart';
import 'package:moto_care/features/rescue_station/providers/rescue_station_provider.dart';
import 'package:moto_care/features/vehicle/models/vehicle.dart';
import 'package:moto_care/features/vehicle/providers/vehicle_provider.dart';

import 'fixtures/marketplace_router_fixture.dart';

const _vehicle = Vehicle(
  id: 'vision',
  name: 'Honda Vision',
  brand: 'Honda',
  licensePlate: '59-A1 123.45',
  tireType: TireType.tubeless,
  engineType: EngineType.gas,
  isDefault: true,
);
const _location = RescueLocation(
  address: '273 An Dương Vương, Quận 5',
  latitude: 10.757,
  longitude: 106.668,
);

Future<GoRouter> _open(
  WidgetTester tester, {
  String path = '/partners?service=Vá%20xe',
  RescueLocation? location = _location,
  Future<RescueLocation> Function()? gps,
  bool emptyPartners = false,
}) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialVehiclesProvider.overrideWithValue([_vehicle]),
        initialRescueLocationProvider.overrideWithValue(location),
        initialRescueOrdersProvider.overrideWithValue([]),
        if (emptyPartners) rescueStationsProvider.overrideWithValue([]),
        deviceLocationProvider.overrideWithValue(
          gps ??
              () async => throw const LocationLookupException(
                'Quyền GPS bị từ chối. Nhập địa chỉ sự cố.',
              ),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
        builder: freezeMarketplaceMotion,
      ),
    ),
  );
  router.go(path);
  await tester.pumpAndSettle();
  return router;
}

ProviderContainer _state(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
Finder _package(String id) => find.byKey(ValueKey('package-$id'));
Future<void> _add(WidgetTester tester, String id) => tapMarketplace(
  tester,
  find.descendant(of: _package(id), matching: find.byTooltip('Thêm')),
);
Future<void> _chooseShop(WidgetTester tester) =>
    tapMarketplace(tester, find.byKey(const ValueKey('choose-station-dealer')));
Future<void> _checkout(WidgetTester tester) async {
  await _chooseShop(tester);
  await _add(tester, 'tire-tubed');
  await _add(tester, 'tire-tubeless');
  await tapMarketplace(
    tester,
    find.byKey(const ValueKey('marketplace-continue')),
  );
}

Finder get _place => find.byKey(const ValueKey('marketplace-place-order'));

void main() {
  testWidgets(
    'Search and vehicle filter narrow shops and show a useful empty state',
    (tester) async {
      await _open(tester);
      await tester.enterText(
        find.byKey(const ValueKey('partner-search')),
        'An Phát',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('partner-station-dealer')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('partner-station-mobile')),
        findsNothing,
      );
      await tester.enterText(
        find.byKey(const ValueKey('partner-search')),
        'Không tồn tại',
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Không tìm thấy tiệm phù hợp'),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(const ValueKey('partner-search')), '');
      await tapMarketplace(tester, find.widgetWithText(FilterChip, 'PKL'));
      expect(
        find.byKey(const ValueKey('partner-station-dealer')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('partner-station-mobile')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Booking preserves packages and payment without voucher discounts',
    (tester) async {
      final router = await _open(tester);
      await _chooseShop(tester);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('marketplace-continue')),
            )
            .onPressed,
        isNull,
      );
      await _add(tester, 'tire-tubed');
      await _add(tester, 'tire-tubed');
      await _add(tester, 'tire-tubeless');
      await tapMarketplace(
        tester,
        find.byKey(const ValueKey('marketplace-continue')),
      );
      final booking = tester
          .widget<CheckoutScreen>(find.byType(CheckoutScreen))
          .booking!;
      expect(booking.quantity, 3);
      expect(booking.subtotal, 110000);
      await tapMarketplace(tester, find.byKey(const ValueKey('checkout-note')));
      await tester.enterText(
        find.byKey(const ValueKey('checkout-note')),
        'Đứng trước cổng trường',
      );
      await tapMarketplace(
        tester,
        find.byKey(const ValueKey('checkout-payment')),
      );
      await tapMarketplace(tester, find.byKey(const ValueKey('payment-momo')));
      expect(find.byKey(const ValueKey('checkout-voucher')), findsNothing);
      expect(find.text('Thêm mã giảm giá / Voucher'), findsNothing);
      expect(find.text('Giảm giá voucher'), findsNothing);
      final priceText = tester
          .widget<Text>(find.byKey(const ValueKey('checkout-total')))
          .data;
      await tapMarketplace(tester, _place);
      expect(router.state.uri.path, '/order-tracking');
      expect(find.byType(OrderTrackingScreen), findsOneWidget);
      final order = _state(tester).read(activityProvider).orders.single;
      expect(order.items.map((item) => item.quantity), [2, 1]);
      expect(order.partnerName, 'Đại lý chính hãng An Phát');
      expect(order.paymentMethod, RescuePaymentMethod.momo);
      expect(order.voucherCode, isEmpty);
      expect(order.discount, 0);
      expect(order.totalPrice, booking.subtotal + order.travelFee);
      expect(order.laborFee, 110000);
      expect(priceText, formatOrderPrice(order.totalPrice));
      expect(order.locationLatitude, _location.latitude);
      expect(order.incidentDescription, 'Đứng trước cổng trường');
      expect(order.hasProvider, isFalse);
      final restored = RescueOrder.fromJson(order.toJson());
      expect(restored.toJson(), order.toJson());
      expect(
        restored
            .copyWith(status: RescueOrderStatus.enRoute)
            .items
            .map((item) => item.toJson()),
        order.items.map((item) => item.toJson()),
      );
      await tapMarketplace(tester, find.text('Hủy đơn hàng'));
      await tapMarketplace(tester, find.text('Xác nhận hủy'));
      expect(
        _state(tester).read(activityProvider).orders.single.status,
        RescueOrderStatus.cancelled,
      );
      expect(find.text('Đơn cứu hộ đã hủy'), findsOneWidget);
    },
  );

  testWidgets(
    'A delayed GPS response cannot overwrite an address typed by the user',
    (tester) async {
      final pending = Completer<RescueLocation>();
      await _open(tester, location: null, gps: () => pending.future);
      await _checkout(tester);
      await tapMarketplace(
        tester,
        find.byKey(const ValueKey('checkout-address')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('checkout-address')),
        '45 Lê Văn Sỹ, TP. Hồ Chí Minh',
      );
      pending.complete(_location);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('checkout-address')))
            .controller!
            .text,
        '45 Lê Văn Sỹ, TP. Hồ Chí Minh',
      );
      await tapMarketplace(tester, _place);
      final order = _state(tester).read(activityProvider).orders.single;
      expect(order.locationAddress, '45 Lê Văn Sỹ, TP. Hồ Chí Minh');
      expect(order.locationLatitude, isNull);
      expect(order.locationLongitude, isNull);
    },
  );

  testWidgets('Automatic GPS fills the address and retains coordinates', (
    tester,
  ) async {
    await _open(tester, location: null, gps: () async => _location);
    await _checkout(tester);
    await tapMarketplace(tester, _place);
    expect(
      _state(tester).read(activityProvider).orders.single.locationLatitude,
      _location.latitude,
    );
    expect(
      _state(tester).read(rescueLocationProvider)!.address,
      _location.address,
    );
  });

  testWidgets(
    'Denied GPS permits manual address entry and clearing it blocks booking',
    (tester) async {
      await _open(tester, location: null);
      await _checkout(tester);
      expect(tester.widget<FilledButton>(_place).onPressed, isNull);
      await tapMarketplace(
        tester,
        find.byKey(const ValueKey('checkout-address')),
      );
      expect(find.textContaining('Quyền GPS bị từ chối'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('checkout-address')),
        '45 Lê Văn Sỹ',
      );
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(_place).onPressed, isNotNull);
      await tester.enterText(
        find.byKey(const ValueKey('checkout-address')),
        '',
      );
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(_place).onPressed, isNull);
    },
  );

  testWidgets(
    'Back from checkout creates no order and keeps the selected detail menu',
    (tester) async {
      await _open(tester);
      await _checkout(tester);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('2 dịch vụ đã chọn'), findsOneWidget);
      expect(_state(tester).read(activityProvider).orders, isEmpty);
    },
  );

  testWidgets('Invalid direct routes and an empty directory stay usable', (
    tester,
  ) async {
    final router = await _open(tester, emptyPartners: true);
    expect(find.textContaining('Không tìm thấy tiệm phù hợp'), findsOneWidget);
    router.go('/checkout');
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa có gói dịch vụ'), findsOneWidget);
    router.go('/partners/missing?service=Vá%20xe');
    await tester.pumpAndSettle();
    expect(find.text('Tiệm không còn trong danh sách.'), findsOneWidget);
    router.go('/rescue-tracking?id=missing');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy đơn cứu hộ.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '320px and large text support filters, checkout and the keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _open(tester);
      expect(tester.takeException(), isNull);
      await _checkout(tester);
      await tapMarketplace(tester, find.byKey(const ValueKey('checkout-note')));
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('checkout-note')),
        'Xe ở bên trái cổng',
      );
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tapMarketplace(tester, _place);
      expect(find.byType(OrderTrackingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('Cart validation rejects changed prices, duplicate packages and unsupported services', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final shop = container.read(partnerShopsProvider).first;
    final package = MarketplaceCatalog.packages.first;
    final valid = MarketplaceBooking(
      partnerId: shop.id,
      serviceType: 'Vá xe',
      items: [package.item(1)],
    );
    expect(valid.isValidFor(shop), isTrue);
    final duplicate = MarketplaceBooking(
      partnerId: shop.id,
      serviceType: 'Vá xe',
      items: [package.item(1), package.item(2)],
    );
    expect(duplicate.isValidFor(shop), isFalse);
    final changed = MarketplaceBooking(
      partnerId: shop.id,
      serviceType: 'Vá xe',
      items: [
        RescueOrderItem(
          packageId: package.id,
          name: package.name,
          unitPrice: 1,
          quantity: 1,
          serviceType: package.serviceType,
        ),
      ],
    );
    expect(changed.isValidFor(shop), isFalse);
    expect(
      MarketplaceBooking(
        partnerId: shop.id,
        serviceType: 'Kích bình điện',
        items: valid.items,
      ).isValidFor(shop),
      isFalse,
    );
  });

  test('Booking items reject zero quantities', () {
    expect(
      () => RescueOrderItem(
        packageId: 'x',
        name: 'x',
        unitPrice: 30000,
        quantity: 0,
        serviceType: RescueServiceType.flatTire,
      ),
      throwsArgumentError,
    );
  });

  test('Global palette and primary actions use the requested exact colors', () {
    expect(HomeColors.primary, const Color(0xFFCC0001));
    expect(HomeColors.text, const Color(0xFF111827));
    expect(HomeColors.secondary, const Color(0xFF4B5563));
    final scheme = AppTheme.light.colorScheme;
    for (final accent in [
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.error,
      scheme.inversePrimary,
    ]) {
      expect(accent, const Color(0xFFCC0001));
    }
    expect(
      AppTheme.light.filledButtonTheme.style!.backgroundColor!.resolve({}),
      const Color(0xFFCC0001),
    );
  });
}
