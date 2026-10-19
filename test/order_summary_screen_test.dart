import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:revo/core/router/app_router.dart';
import 'package:revo/core/theme/app_theme.dart';
import 'package:revo/features/activity/models/rescue_order.dart';
import 'package:revo/features/activity/providers/activity_provider.dart';
import 'package:revo/features/activity/widgets/order_summary.dart';
import 'package:revo/features/home/models/rescue_location.dart';
import 'package:revo/features/home/providers/home_provider.dart';
import 'package:revo/features/location/services/device_location_service.dart';
import 'package:revo/features/partner/models/marketplace_catalog.dart';
import 'package:revo/features/partner/providers/partner_provider.dart';
import 'package:revo/features/rescue/models/marketplace_booking.dart';
import 'package:revo/features/rescue/screens/order_summary_screen.dart';
import 'package:revo/features/rescue/screens/order_tracking_screen.dart';
import 'package:revo/features/rescue/services/checkout_service.dart';
import 'package:revo/features/rescue_station/data/mock_rescue_stations.dart';
import 'package:revo/features/rescue_station/models/rescue_station.dart';
import 'package:revo/features/vehicle/models/vehicle.dart';
import 'package:revo/features/vehicle/providers/vehicle_provider.dart';

import 'fixtures/marketplace_router_fixture.dart';

const _vehicle = Vehicle(
  id: 'summary-vehicle',
  name: 'Honda SH',
  brand: 'Honda',
  licensePlate: '59-A1 123.45',
  tireType: TireType.tubeless,
  engineType: EngineType.gas,
  isDefault: true,
);
const _location = RescueLocation(address: '123 Nguyễn Thị Minh Khai, Quận 1');

PartnerShop _shop() => PartnerShop(
  station: RescueStation.fromJson({
    ...mockRescueStations.first.toJson(),
    'distanceKm': 1.2,
  }),
  vehicleTypes: PartnerVehicleType.values,
  services: RescueServiceType.values,
);

MarketplaceBooking _booking(PartnerShop shop, {int quantity = 1}) =>
    MarketplaceBooking(
      partnerId: shop.id,
      serviceType: 'Vá xe',
      items: [MarketplaceCatalog.packages.first.item(quantity)],
    );

Future<GoRouter> _open(WidgetTester tester) async {
  final shop = _shop();
  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        partnerShopsProvider.overrideWithValue([shop]),
        initialVehiclesProvider.overrideWithValue([_vehicle]),
        initialRescueLocationProvider.overrideWithValue(_location),
        initialRescueOrdersProvider.overrideWithValue([]),
        deviceLocationProvider.overrideWithValue(
          () async => RescueLocation(
            address: '456 Nguyễn Thị Minh Khai, Quận 1',
            latitude: shop.station.latitude + 1.2 / 111.19492664455873,
            longitude: shop.station.longitude,
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
  router.go('/checkout', extra: _booking(shop));
  await tester.pumpAndSettle();
  return router;
}

ProviderContainer _state(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

void main() {
  test('A 30,000 VND service at 1.2 km quotes 45,000 VND without discount', () {
    final shop = _shop();
    final quote = const CheckoutService().quote(
      booking: _booking(shop),
      shops: [shop],
      location: _location,
      note: '',
      hasVehicle: true,
      hasActiveOrder: false,
      submitting: false,
    );
    expect(quote.distance, 1.2);
    expect(quote.travelFee, 15000);
    expect(quote.total, 45000);
    expect(quote.canOrder, isTrue);
    final multiple = const CheckoutService().quote(
      booking: _booking(shop, quantity: 3),
      shops: [shop],
      location: _location,
      note: '',
      hasVehicle: true,
      hasActiveOrder: false,
      submitting: false,
    );
    expect(multiple.total, 105000);
  });

  test('Travel fee uses the documented nearest kilometer boundaries', () {
    for (final (distance, fee) in [
      (0.0, 10000),
      (1.2, 15000),
      (1.49, 15000),
      (1.5, 20000),
      (2.49, 20000),
      (2.5, 25000),
    ]) {
      expect(MarketplaceBooking.travelFee(distance), fee);
    }
  });

  testWidgets(
    'Checkout renders the new summary and its exact red total/action',
    (tester) async {
      await _open(tester);
      expect(find.byType(OrderSummaryScreen), findsOneWidget);
      expect(find.text('Cách bạn ~1.2 km'), findsOneWidget);
      expect(find.textContaining('Chế độ trải nghiệm:'), findsNothing);
      expect(find.text('Chi tiết chi phí'), findsOneWidget);
      final total = tester.widget<Text>(
        find.byKey(const ValueKey('checkout-total')),
      );
      expect(total.data, formatOrderPrice(45000));
      expect(total.style!.color, const Color(0xFFE53935));
      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('marketplace-place-order')),
      );
      expect(
        button.style!.backgroundColor!.resolve({}),
        const Color(0xFFE53935),
      );
      expect(find.text('XÁC NHẬN ĐẶT ĐƠN CỨU HỘ'), findsOneWidget);
      await tapMarketplace(tester, find.text('Giảm giá (Voucher)'));
      expect(find.text('-0đ'), findsOneWidget);
      expect(find.text('x1'), findsOneWidget);
      expect(_state(tester).read(activityProvider).orders, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'VNPay, GPS and notes survive confirmation into the tracked order',
    (tester) async {
      await _open(tester);
      await tapMarketplace(
        tester,
        find.byKey(const ValueKey('checkout-change-address')),
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('checkout-address')))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tester.enterText(
        find.byKey(const ValueKey('checkout-address')),
        'Địa chỉ vừa thay đổi tại Quận 1',
      );
      tester.testTextInput.hide();
      await tapMarketplace(
        tester,
        find.byKey(const ValueKey('checkout-locate')),
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('checkout-address')))
            .controller!
            .text,
        '456 Nguyễn Thị Minh Khai, Quận 1',
      );
      await tapMarketplace(
        tester,
        find.byKey(const ValueKey('checkout-payment')),
      );
      expect(find.byKey(const ValueKey('payment-cash')), findsOneWidget);
      expect(find.byKey(const ValueKey('payment-momo')), findsOneWidget);
      await tapMarketplace(tester, find.byKey(const ValueKey('payment-vnpay')));
      await tapMarketplace(tester, find.byKey(const ValueKey('checkout-note')));
      await tester.enterText(
        find.byKey(const ValueKey('checkout-note')),
        'Xe SH bị thủng bánh sau',
      );
      tester.testTextInput.hide();
      final place = find.byKey(const ValueKey('marketplace-place-order'));
      await tester.tap(place);
      await tester.tap(place);
      await tester.pumpAndSettle();
      expect(find.byType(OrderTrackingScreen), findsOneWidget);
      final order = _state(tester).read(activityProvider).orders.single;
      expect(order.partnerId, _shop().id);
      expect(order.paymentMethod, RescuePaymentMethod.vnpay);
      expect(order.incidentDescription, 'Xe SH bị thủng bánh sau');
      expect(order.locationLatitude, isNotNull);
      expect(order.travelFee, 15000);
      expect(order.totalPrice, 45000);
      expect(order.discount, 0);
      expect(order.voucherCode, isEmpty);
      expect(
        RescueOrder.fromJson(order.toJson()).paymentMethod,
        RescuePaymentMethod.vnpay,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Dragging a large address scrolls the page to later sections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(tester);
    final scrollable = find
        .descendant(
          of: find.byKey(const ValueKey('checkout-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    final position = tester.state<ScrollableState>(scrollable).position;
    await tester.drag(scrollable, const Offset(0, -120));
    await tester.pumpAndSettle();
    final address = find.byKey(const ValueKey('checkout-address'));
    await tester.ensureVisible(address);
    await tester.pumpAndSettle();
    final before = position.pixels;
    await tester.drag(address, const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(before));
    await tapMarketplace(tester, find.byKey(const ValueKey('checkout-note')));
    expect(find.byKey(const ValueKey('checkout-note')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dismissing payment keeps cash and creates no order', (
    tester,
  ) async {
    await _open(tester);
    await tapMarketplace(
      tester,
      find.byKey(const ValueKey('checkout-payment')),
    );
    Navigator.of(tester.element(find.byKey(const ValueKey('payment-cash'))))
        .pop();
    await tester.pumpAndSettle();
    expect(find.text('Tiền mặt cho thợ'), findsOneWidget);
    expect(_state(tester).read(activityProvider).orders, isEmpty);
  });

  test('Legacy wallet payment values remain readable after rebranding', () {
    expect(RescuePaymentMethod.fromValue('motocare'), RescuePaymentMethod.revo);
    expect(RescuePaymentMethod.fromValue('cash'), RescuePaymentMethod.cash);
  });
}
