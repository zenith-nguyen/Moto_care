import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/activity/models/rescue_order.dart';
import 'package:moto_care/features/activity/providers/activity_provider.dart';
import 'package:moto_care/features/home/models/home_destination.dart';
import 'package:moto_care/features/home/models/home_user.dart';
import 'package:moto_care/features/home/models/rescue_location.dart';
import 'package:moto_care/features/home/providers/home_provider.dart';
import 'package:moto_care/features/home/screens/home_screen.dart';
import 'package:moto_care/features/home/widgets/home_service_grid.dart';
import 'package:moto_care/features/home/widgets/home_bottom_navigation.dart';
import 'package:moto_care/features/profile/models/user_profile.dart';
import 'package:moto_care/features/profile/providers/profile_provider.dart';
import 'package:moto_care/features/partner/screens/partner_list_screen.dart';
import 'package:moto_care/features/partner/models/marketplace_catalog.dart';
import 'package:moto_care/features/rescue/screens/checkout_screen.dart';
import 'package:moto_care/features/location/services/device_location_service.dart';

import 'fixtures/marketplace_router_fixture.dart';

import 'package:moto_care/features/rescue_station/providers/rescue_station_provider.dart';
import 'package:moto_care/features/vehicle/models/vehicle.dart';
import 'package:moto_care/features/vehicle/providers/vehicle_provider.dart';

const _vehicles = [
  Vehicle(
    id: 'vision',
    name: 'Honda Vision',
    brand: 'Honda',
    licensePlate: '59-A1 123.45',
    tireType: TireType.tubeless,
    engineType: EngineType.gas,
    isDefault: true,
  ),
  Vehicle(
    id: 'feliz',
    name: 'VinFast Feliz',
    brand: 'VinFast',
    licensePlate: '59-B1 678.90',
    tireType: TireType.tubeless,
    engineType: EngineType.electric,
  ),
];
const _location = RescueLocation(
  address: '273 An Dương Vương, Quận 5',
  latitude: 10.757,
  longitude: 106.668,
);

Future<ProviderContainer> _open(
  WidgetTester tester, {
  bool hasVehicle = true,
  bool hasLocation = true,
  bool active = false,
  bool routed = false,
  ValueChanged<HomeDestination>? onSelected,
}) async {
  final router = routed
      ? createAppRouter()
      : marketplaceTestRouter(
          HomeScreen(
            user: const HomeUser(displayName: 'Tên cũ', memberId: 'api-user'),
            onDestinationSelected: onSelected,
          ),
        );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialUserProfileProvider.overrideWithValue(
          const UserProfile(
            id: 'api-user',
            fullName: 'Nguyễn An',
            memberTier: 'Thành viên Vàng',
            rewardPoints: 720,
          ),
        ),
        initialVehiclesProvider.overrideWithValue(hasVehicle ? _vehicles : []),
        initialRescueLocationProvider.overrideWithValue(
          hasLocation ? _location : null,
        ),
        if (!active) initialRescueOrdersProvider.overrideWithValue([]),
        deviceLocationProvider.overrideWithValue(
          () async => throw const LocationLookupException('GPS không khả dụng'),
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
  router.go('/trang-chu');
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .last,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _service(HomeService service) =>
    find.byKey(ValueKey('home-service-${service.name}'));
Finder get _confirm => find.byKey(const ValueKey('marketplace-place-order'));

Future<void> _checkout(WidgetTester tester, HomeService service) async {
  await _tap(tester, _service(service));
  await _tap(tester, find.byKey(const ValueKey('choose-station-dealer')));
  final type = MarketplaceCatalog.typeFor(service.title);
  final package = MarketplaceCatalog.packages.firstWhere(
    (item) => type == null || item.serviceType == type,
  );
  await _tap(
    tester,
    find.descendant(
      of: find.byKey(ValueKey('package-${package.id}')),
      matching: find.byTooltip('Thêm'),
    ),
  );
  await _tap(tester, find.byKey(const ValueKey('marketplace-continue')));
}

void main() {
  testWidgets('Home watches the shared profile and default vehicle', (
    tester,
  ) async {
    final container = await _open(tester);
    expect(find.text('Chào Nguyễn An'), findsOneWidget);
    expect(find.text('Tên cũ'), findsNothing);
    expect(find.text('Honda Vision (59-A1 123.45)'), findsOneWidget);
    expect(find.text('720 xu'), findsNothing);
    expect(find.text('Thành viên Vàng'), findsNothing);
    container
        .read(profileProvider.notifier)
        .initialize(
          const UserProfile(
            id: 'updated-user',
            fullName: 'Lê Bình',
            memberTier: 'Thành viên Bạch Kim',
            rewardPoints: 1200,
          ),
        );
    await tester.pumpAndSettle();
    tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byKey(const ValueKey('home-scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Chào Lê Bình'), findsOneWidget);
    expect(find.text('Thành viên Bạch Kim'), findsNothing);
    expect(find.text('1200 xu'), findsNothing);
  });

  testWidgets(
    'Location validates, cancels without changes and clears stale GPS on save',
    (tester) async {
      final container = await _open(tester, routed: true);
      await _tap(tester, find.text('Sửa vị trí'));
      await tester.enterText(
        find.byKey(const ValueKey('incident-address')),
        'abc',
      );
      await _tap(tester, find.text('Chọn trên bản đồ'));
      expect(
        find.text('Vui lòng nhập địa chỉ ít nhất 5 ký tự.'),
        findsOneWidget,
      );
      await _tap(tester, find.byTooltip('Quay lại'));
      expect(container.read(rescueLocationProvider), same(_location));
      await _tap(tester, find.text('Sửa vị trí'));
      await tester.enterText(
        find.byKey(const ValueKey('incident-address')),
        '  45 Lê Văn Sỹ, TP. Hồ Chí Minh  ',
      );
      await _tap(tester, find.text('Chọn trên bản đồ'));
      expect(container.read(rescueLocationProvider), same(_location));
      await _tap(
        tester,
        find.byKey(const ValueKey('incident-confirm-location')),
      );
      await _tap(tester, find.byTooltip('Đóng'));
      await _tap(tester, find.text('Trang chủ'));
      expect(
        container.read(rescueLocationProvider)!.address,
        '45 Lê Văn Sỹ, TP. Hồ Chí Minh',
      );
      expect(container.read(rescueLocationProvider)!.hasCoordinates, isFalse);
      expect(
        find.text('Vị trí sự cố: 45 Lê Văn Sỹ, TP. Hồ Chí Minh'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Vehicle picker changes shared default and dismissal preserves it',
    (tester) async {
      final container = await _open(tester);
      await _tap(tester, find.text('Honda Vision (59-A1 123.45)'));
      await _tap(tester, find.byTooltip('Đóng'));
      expect(container.read(defaultVehicleProvider)!.id, 'vision');
      await _tap(tester, find.text('Honda Vision (59-A1 123.45)'));
      await _tap(tester, find.text('VinFast Feliz'));
      expect(container.read(defaultVehicleProvider)!.id, 'feliz');
      expect(find.text('VinFast Feliz (59-B1 678.90)'), findsOneWidget);
    },
  );

  testWidgets(
    'Marketplace saves selected vehicle and GPS and blocks another order',
    (tester) async {
      final container = await _open(tester);
      container.read(vehicleProvider.notifier).setDefault('feliz');
      await tester.pumpAndSettle();
      await _checkout(tester, HomeService.battery);
      expect(find.byType(CheckoutScreen), findsOneWidget);
      expect(find.text('GPS: 10.757000, 106.668000'), findsOneWidget);
      await _tap(tester, _confirm);
      final order = container.read(activityProvider).orders.single;
      expect(order.serviceType, RescueServiceType.batteryJump);
      expect(order.userVehicle, 'VinFast Feliz (59-B1 678.90)');
      expect(order.locationAddress, _location.address);
      expect(order.locationLatitude, _location.latitude);
      expect(order.locationLongitude, _location.longitude);
      expect(order.partnerId, isNotNull);
      expect(order.items.single.name, 'Kích bình ắc quy');
      for (var step = 0; step < 3; step++) {
        await _tap(tester, find.byType(BackButton));
      }
      await _checkout(tester, HomeService.fuel);
      expect(tester.widget<FilledButton>(_confirm).onPressed, isNull);
      expect(container.read(activityProvider).orders, hasLength(1));
    },
  );

  testWidgets(
    'All eight home services open the partner list and back creates no order',
    (tester) async {
      final selected = <HomeDestination>[];
      final container = await _open(tester, onSelected: selected.add);
      for (final service in HomeService.homeItems) {
        await _tap(tester, _service(service));
        expect(
          tester
              .widget<PartnerListScreen>(find.byType(PartnerListScreen))
              .serviceType,
          service.title,
        );
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      expect(container.read(activityProvider).orders, isEmpty);
      expect(selected, isEmpty);
    },
  );

  for (final missingVehicle in [true, false]) {
    testWidgets(
      'Missing ${missingVehicle ? 'vehicle' : 'location'} disables marketplace checkout',
      (tester) async {
        final container = await _open(
          tester,
          hasVehicle: !missingVehicle,
          hasLocation: missingVehicle,
        );
        await _checkout(tester, HomeService.tire);
        expect(tester.widget<FilledButton>(_confirm).onPressed, isNull);
        expect(container.read(activityProvider).orders, isEmpty);
      },
    );
  }

  testWidgets('Existing active order disables marketplace booking', (
    tester,
  ) async {
    final container = await _open(tester, active: true);
    final count = container.read(activityProvider).orders.length;
    await _checkout(tester, HomeService.tire);
    expect(tester.widget<FilledButton>(_confirm).onPressed, isNull);
    expect(container.read(activityProvider).orders, hasLength(count));
  });

  testWidgets(
    'Nearby section handles empty stations and station details dispatch route',
    (tester) async {
      final selected = <HomeDestination>[];
      final container = await _open(tester, onSelected: selected.add);
      final station = container.read(homeNearbyStationsProvider).first;
      await _tap(tester, find.text(station.name));
      expect(find.text(station.address), findsOneWidget);
      await _tap(tester, find.text('Xem danh sách trạm cứu hộ'));
      expect(selected, [HomeDestination.rescueStations]);
      expect(find.byTooltip('Đóng'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [rescueStationsProvider.overrideWithValue([])],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.text('Chưa có trạm cứu hộ trong khu vực.'),
      );
      expect(find.text('Chưa có trạm cứu hộ trong khu vực.'), findsOneWidget);
    },
  );

  testWidgets(
    'Small screen with keyboard keeps location and confirmation scrollable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _open(tester, routed: true);
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text('Sửa vị trí'));
      await _tap(tester, find.byKey(const ValueKey('incident-address')));
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('incident-address')),
        '273 An Dương Vương, Quận 5',
      );
      await _tap(tester, find.text('Chọn trên bản đồ'));
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await _tap(
        tester,
        find.byKey(const ValueKey('incident-confirm-location')),
      );
      await _tap(tester, find.byTooltip('Đóng'));
      await _tap(tester, find.text('Trang chủ'));
      await _checkout(tester, HomeService.tire);
      await tester.ensureVisible(_confirm);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Four home tabs route and returning preserves session selection',
    (tester) async {
      final router = createAppRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialVehiclesProvider.overrideWithValue(_vehicles),
            initialRescueLocationProvider.overrideWithValue(_location),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      router.go(
        '/trang-chu',
        extra: const HomeUser(displayName: 'Nguyễn An', memberId: 'test-user'),
      );
      await tester.pumpAndSettle();
      for (final (label, path) in [
        ('Hoạt động', '/hoat-dong'),
        ('Dịch vụ', '/dich-vu'),
        ('Tài khoản', '/tai-khoan'),
      ]) {
        await _tap(tester, find.text(label));
        expect(router.state.uri.path, path);
        router.pop();
        await tester.pumpAndSettle();
        expect(find.text('Chào Nguyễn An'), findsOneWidget);
        expect(find.text('Honda Vision (59-A1 123.45)'), findsOneWidget);
        expect(find.text('Vị trí sự cố: ${_location.address}'), findsOneWidget);
      }
    },
  );
  testWidgets('Bottom tabs leave nested screens and reuse their parent tabs', (
    tester,
  ) async {
    final router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    router.go('/trang-chu', extra: const HomeUser(displayName: 'Nguyễn An'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Tài khoản'));
    router.push('/thong-tin-ca-nhan');
    await tester.pumpAndSettle();
    final nav = find.byType(HomeBottomNavigation);
    await _tap(
      tester,
      find.descendant(of: nav, matching: find.text('Tài khoản')),
    );
    expect(router.state.uri.path, '/tai-khoan');
    router.pop();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/trang-chu');
    expect(find.text('Chào Nguyễn An'), findsOneWidget);
    router.push('/bang-gia');
    await tester.pumpAndSettle();
    await _tap(
      tester,
      find.descendant(of: nav, matching: find.text('Dịch vụ')),
    );
    expect(router.state.uri.path, '/dich-vu');
    router.pop();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/trang-chu');
    expect(find.text('Chào Nguyễn An'), findsOneWidget);
    expect(router.canPop(), isFalse);
  });
}
