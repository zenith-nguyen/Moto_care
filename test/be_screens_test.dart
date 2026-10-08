import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/activity/data/mock_rescue_orders.dart';
import 'package:moto_care/features/activity/models/rescue_order.dart';
import 'package:moto_care/features/activity/providers/activity_provider.dart';
import 'package:moto_care/features/activity/widgets/activity_order_card.dart';
import 'package:moto_care/features/activity/widgets/order_summary.dart';
import 'package:moto_care/features/home/models/rescue_location.dart';
import 'package:moto_care/features/home/providers/home_provider.dart';
import 'package:moto_care/features/home/theme/home_theme.dart';
import 'package:moto_care/features/home/widgets/home_bottom_navigation.dart';
import 'package:moto_care/features/home/widgets/home_service_grid.dart';
import 'package:moto_care/features/location/services/device_location_service.dart';
import 'package:moto_care/features/partner/models/marketplace_catalog.dart';
import 'package:moto_care/features/partner/screens/partner_detail_screen.dart';
import 'package:moto_care/features/partner/screens/partner_list_screen.dart';
import 'package:moto_care/features/profile/models/user_profile.dart';
import 'package:moto_care/features/profile/providers/profile_provider.dart';
import 'package:moto_care/features/profile/screens/profile_screen.dart';
import 'package:moto_care/features/rescue/screens/checkout_screen.dart';
import 'package:moto_care/features/vehicle/models/vehicle.dart';
import 'package:moto_care/features/vehicle/providers/vehicle_provider.dart';

import 'fixtures/user_profile_fixture.dart';
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
  WidgetTester tester,
  String path, {
  List<RescueOrder> orders = const [],
  UserProfile profile = profileFixture,
  bool hasVehicle = true,
  bool hasLocation = true,
}) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialUserProfileProvider.overrideWithValue(profile),
        initialVehiclesProvider.overrideWithValue(hasVehicle ? [_vehicle] : []),
        initialRescueLocationProvider.overrideWithValue(
          hasLocation ? _location : null,
        ),
        initialRescueOrdersProvider.overrideWithValue(orders),
        deviceLocationProvider.overrideWithValue(
          () async => throw const LocationLookupException('GPS chưa khả dụng.'),
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

Future<void> _tap(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    final scrollable = find
        .byElementPredicate((element) {
          if (element.widget is! Scrollable) return false;
          final state = (element as StatefulElement).state as ScrollableState;
          return state.widget.axisDirection == AxisDirection.down &&
              state.position.maxScrollExtent > 0;
        })
        .hitTestable()
        .last;
    await tester.scrollUntilVisible(target, 160, scrollable: scrollable);
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _nightCheckout(WidgetTester tester) async {
  await _tap(tester, find.byKey(const ValueKey('service-night')));
  await _tap(tester, find.byKey(const ValueKey('choose-station-dealer')));
  await _tap(
    tester,
    find.descendant(
      of: find.byKey(const ValueKey('package-night')),
      matching: find.byTooltip('Thêm'),
    ),
  );
  await _tap(tester, find.byKey(const ValueKey('marketplace-continue')));
}

void main() {
  testWidgets('Account header and club react to shared profile updates', (
    tester,
  ) async {
    await _open(tester, '/tai-khoan');
    expect(find.text(profileFixture.fullName), findsOneWidget);
    expect(find.text(profileFixture.phoneNumber), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);
    expect(find.text('350 xu'), findsOneWidget);
    expect(find.text('Thành viên Vàng'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(HomeBottomNavigation)))
          .scaffoldBackgroundColor,
      HomeColors.background,
    );
    _state(tester)
        .read(profileProvider.notifier)
        .initialize(
          const UserProfile(
            id: 'other',
            fullName: 'Lê Bình',
            phoneNumber: '0901234567',
            memberTier: 'Thành viên Bạch Kim',
            rewardPoints: 900,
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('Lê Bình'), findsOneWidget);
    expect(find.text('900 xu'), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Account links open requested routes and club opens rewards', (
    tester,
  ) async {
    final router = await _open(tester, '/tai-khoan');
    await _tap(tester, find.text('Đổi quà ›'));
    expect(router.state.uri.path, '/tich-diem');
    router.pop();
    await tester.pumpAndSettle();
    for (final (id, route) in [
      ('vehicles', '/xe-cua-toi'),
      ('mechanic', '/dang-ky-tho'),
      ('vouchers', '/kho-voucher'),
      ('help', '/faq'),
      ('commitment', '/cam-ket-dich-vu'),
    ]) {
      await _tap(tester, find.byKey(ValueKey('account-$id')));
      expect(router.state.uri.path, route);
      router.pop();
      await tester.pumpAndSettle();
    }
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Account sheets use actual contacts and completed spending', (
    tester,
  ) async {
    await _open(tester, '/tai-khoan', orders: mockRescueOrders);
    await _tap(tester, find.byKey(const ValueKey('account-expenses')));
    expect(find.text(formatOrderPrice(290000)), findsOneWidget);
    expect(find.text('2 đơn hoàn thành • 0 lần bảo dưỡng'), findsOneWidget);
    await _tap(tester, find.byTooltip('Đóng'));
    await _tap(tester, find.byKey(const ValueKey('account-emergency')));
    expect(find.text('Người thân\n0900000002'), findsOneWidget);
    await _tap(tester, find.byTooltip('Đóng'));
    for (final id in ['payment', 'shop', 'insurance', 'settings']) {
      await _tap(tester, find.byKey(ValueKey('account-$id')));
      expect(find.byTooltip('Đóng'), findsOneWidget);
      await _tap(tester, find.byTooltip('Đóng'));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Shared services open the same filtered marketplace from home and catalog',
    (tester) async {
      final router = await _open(tester, '/trang-chu');
      for (final service in [
        HomeService.tire,
        HomeService.battery,
        HomeService.fuel,
        HomeService.flood,
        HomeService.towing,
        HomeService.maintenance,
        HomeService.charging,
      ]) {
        router.go('/trang-chu');
        await tester.pumpAndSettle();
        await _tap(
          tester,
          find.byKey(ValueKey('home-service-${service.name}')),
        );
        final homeLocation = router.state.uri;
        expect(homeLocation.path, '/partners');
        expect(homeLocation.queryParameters['service'], service.title);

        router.go('/dich-vu');
        await tester.pumpAndSettle();
        await _tap(tester, find.byKey(ValueKey('service-${service.name}')));
        expect(router.state.uri, homeLocation);
        expect(
          tester
              .widget<PartnerListScreen>(find.byType(PartnerListScreen))
              .serviceType,
          service.title,
        );
        expect(_state(tester).read(activityProvider).orders, isEmpty);
        await _tap(tester, find.byKey(const ValueKey('choose-station-dealer')));
        expect(
          tester
              .widget<PartnerDetailScreen>(find.byType(PartnerDetailScreen))
              .serviceType,
          service.title,
        );
        final type = MarketplaceCatalog.typeFor(service.title);
        expect(type, isNotNull);
        final firstPackage = MarketplaceCatalog.packages.firstWhere(
          (package) => package.serviceType == type,
        );
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('package-${firstPackage.id}')),
          100,
          scrollable: find.byType(Scrollable).last,
        );
        for (final package in MarketplaceCatalog.packages) {
          expect(
            find.byKey(ValueKey('package-${package.id}')),
            package.serviceType == type ? findsOneWidget : findsNothing,
          );
        }
        router.pop();
        router.pop();
        await tester.pumpAndSettle();
        expect(router.state.uri.path, '/dich-vu');
        expect(_state(tester).read(activityProvider).orders, isEmpty);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Night rescue booking from the catalog retains selected GPS and vehicle',
    (tester) async {
      final router = await _open(tester, '/dich-vu');
      await _nightCheckout(tester);
      expect(find.byType(CheckoutScreen), findsOneWidget);
      expect(find.text('GPS: 10.757000, 106.668000'), findsOneWidget);
      expect(_state(tester).read(activityProvider).orders, isEmpty);
      await _tap(tester, find.byKey(const ValueKey('marketplace-place-order')));
      expect(router.state.uri.path, '/order-tracking');
      final order = _state(tester).read(activityProvider).activeOrders.single;
      expect(order.serviceType, RescueServiceType.nightRescue);
      expect(order.locationLatitude, _location.latitude);
      expect(order.locationLongitude, _location.longitude);
      expect(order.userVehicle, 'Honda Vision (59-A1 123.45)');
      expect(order.items.single.packageId, 'night');
      expect(order.partnerId, 'station-dealer');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Care utility links open prices, tips and the rescue station list',
    (tester) async {
      final router = await _open(tester, '/dich-vu');
      for (final (id, route) in [
        ('prices', '/bang-gia'),
        ('tips', '/meo-xu-ly'),
      ]) {
        await _tap(tester, find.byKey(ValueKey('service-$id')));
        expect(router.state.uri.path, route);
        router.pop();
        await tester.pumpAndSettle();
      }
      await _tap(tester, find.text('Tìm trạm cứu hộ'));
      expect(router.state.uri.path, '/tram-cuu-ho');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Missing emergency context allows browsing but blocks checkout', (
    tester,
  ) async {
    await _open(tester, '/dich-vu', hasVehicle: false, hasLocation: false);
    await _nightCheckout(tester);
    expect(find.byType(CheckoutScreen), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('marketplace-place-order')),
          )
          .onPressed,
      isNull,
    );
    expect(_state(tester).read(activityProvider).orders, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Activity filters categories and groups sorted orders by month', (
    tester,
  ) async {
    final orders = [
      mockRescueOrders[1],
      RescueOrder.fromJson({
        ...mockRescueOrders[1].toJson(),
        'id': 'maintenance',
        'serviceType': 'Đặt lịch bảo dưỡng',
        'createdAt': '2026-10-01T08:00:00',
      }),
      RescueOrder.fromJson({
        ...mockRescueOrders[1].toJson(),
        'id': 'charging',
        'serviceType': 'Trạm sạc',
        'createdAt': '2026-10-02T08:00:00',
      }),
    ];
    await _open(tester, '/hoat-dong', orders: orders);
    expect(
      tester
          .widgetList<ActivityOrderCard>(find.byType(ActivityOrderCard))
          .first
          .order
          .id,
      'charging',
    );
    expect(find.text('Tháng 10/2026'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('activity-filter-sos')));
    expect(find.byKey(const ValueKey('completed-001')), findsOneWidget);
    expect(find.byKey(const ValueKey('maintenance')), findsNothing);
    expect(find.text('Tháng 9/2026'), findsOneWidget);
    await _tap(
      tester,
      find.byKey(const ValueKey('activity-filter-maintenance')),
    );
    expect(
      tester.widget<ActivityOrderCard>(find.byType(ActivityOrderCard)).order.id,
      'maintenance',
    );
    await _tap(tester, find.byKey(const ValueKey('activity-filter-charging')));
    expect(
      tester.widget<ActivityOrderCard>(find.byType(ActivityOrderCard)).order.id,
      'charging',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Cancelled orders show no payment and active orders cannot be rebooked',
    (tester) async {
      await _open(
        tester,
        '/hoat-dong',
        orders: [mockRescueOrders.first, mockRescueOrders.last],
      );
      final active = find.byKey(const ValueKey('active-001'));
      expect(
        tester
            .widget<FilledButton>(
              find.descendant(of: active, matching: find.byType(FilledButton)),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('cancelled-001')));
      expect(find.text('Chưa thanh toán'), findsOneWidget);
      await _tap(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('cancelled-001')),
          matching: find.text('Chi tiết đơn'),
        ),
      );
      expect(find.text('MC-260925-003'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final path in ['/tai-khoan', '/dich-vu', '/hoat-dong']) {
    testWidgets('Light screen $path stays usable at 320px with 1.5x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _open(tester, path, orders: mockRescueOrders);
      expect(tester.takeException(), isNull);
      if (path == '/dich-vu') {
        await _tap(tester, find.byKey(const ValueKey('service-maintenance')));
        expect(find.byType(PartnerListScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      } else if (path == '/tai-khoan') {
        await _tap(tester, find.byKey(const ValueKey('account-settings')));
        expect(tester.takeException(), isNull);
      } else {
        await _tap(
          tester,
          find.byKey(const ValueKey('activity-filter-charging')),
        );
        expect(find.text('Chưa có hoạt động trạm sạc'), findsOneWidget);
      }
    });
  }
}
