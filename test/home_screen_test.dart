import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/core/theme/revo_brand.dart';
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
import 'fixtures/home_scroll_helpers.dart';

import 'package:moto_care/features/rescue_station/providers/rescue_station_provider.dart';
import 'package:moto_care/features/rescue_station/screens/station_detail_screen.dart';
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

void _expectSelectedNavigation(
  WidgetTester tester,
  HomeDestination selectedDestination, {
  Color activeColor = RevoBrandColors.primary,
}) {
  final nav = find.byType(HomeBottomNavigation);
  expect(
    tester.widget<HomeBottomNavigation>(nav).selectedDestination,
    selectedDestination,
  );
  expect(
    tester
        .widgetList<Text>(find.descendant(of: nav, matching: find.byType(Text)))
        .map((label) => label.data),
    ['Trang chủ', 'Bản đồ trạm', 'Hoạt động', 'Tài khoản'],
  );
  for (final destination in HomeDestination.homeNavigationItems) {
    final selected = destination == selectedDestination;
    final color = selected ? activeColor : RevoBrandColors.textSubtle;
    final icon = find.descendant(
      of: nav,
      matching: find.byIcon(destination.navigationIcon),
    );
    final label = find.descendant(
      of: nav,
      matching: find.text(destination.navigationLabel),
    );
    expect(tester.widget<Icon>(icon).color, color);
    expect(tester.widget<Text>(label).style!.color, color);
    expect(
      tester
          .widget<Semantics>(
            find
                .ancestor(
                  of: icon,
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Semantics &&
                        widget.properties.selected != null,
                  ),
                )
                .first,
          )
          .properties
          .selected,
      selected,
    );
  }
}

Future<ProviderContainer> _open(
  WidgetTester tester, {
  bool hasVehicle = true,
  bool hasLocation = true,
  bool active = false,
  bool routed = false,
  ValueChanged<HomeDestination>? onSelected,
  RescueLocation? initialLocation,
  Future<RescueLocation> Function()? deviceLocation,
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
          initialLocation ?? (hasLocation ? _location : null),
        ),
        if (!active) initialRescueOrdersProvider.overrideWithValue([]),
        deviceLocationProvider.overrideWithValue(
          deviceLocation ??
              () async =>
                  throw const LocationLookupException('GPS không khả dụng'),
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
  if (finder.evaluate().isEmpty &&
      find.byType(HomeScreen).evaluate().isNotEmpty) {
    final services = find.byKey(const ValueKey('home-services'));
    await tester.ensureVisible(services);
    await tester.pumpAndSettle();
    await tester.tap(services);
    await tester.pumpAndSettle();
  }
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
  finder = finder.last;
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
  testWidgets('Returning to the app refreshes only device-selected GPS', (
    tester,
  ) async {
    const oldGps = RescueLocation(
      address: '191 Nguyễn Tiểu La, TP. Hồ Chí Minh',
      latitude: 10.7638,
      longitude: 106.6663,
      source: RescueLocationSource.device,
    );
    const freshGps = RescueLocation(
      address: '232/6 Võ Thị Sáu, TP. Hồ Chí Minh',
      latitude: 10.7820,
      longitude: 106.6858,
      source: RescueLocationSource.device,
    );
    var gpsCalls = 0;
    final container = await _open(
      tester,
      initialLocation: oldGps,
      deviceLocation: () async {
        gpsCalls++;
        return freshGps;
      },
    );
    expect(gpsCalls, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(gpsCalls, 1);
    expect(container.read(rescueLocationProvider)!.address, freshGps.address);

    container
        .read(rescueLocationProvider.notifier)
        .confirmLocation(
          const RescueLocation(
            address: '45 Lê Văn Sỹ, TP. Hồ Chí Minh',
            latitude: 10.7830,
            longitude: 106.6780,
          ),
        );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(gpsCalls, 1);
    expect(
      container.read(rescueLocationProvider)!.address,
      '45 Lê Văn Sỹ, TP. Hồ Chí Minh',
    );
  });

  testWidgets('Home watches the shared profile and default vehicle', (
    tester,
  ) async {
    final container = await _open(tester);
    expect(find.byTooltip('Tài khoản Nguyễn An'), findsOneWidget);
    expect(find.text('Tên cũ'), findsNothing);
    expect(container.read(defaultVehicleProvider)!.id, 'vision');
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
    expect(find.byTooltip('Tài khoản Lê Bình'), findsOneWidget);
    expect(find.text('Thành viên Bạch Kim'), findsNothing);
    expect(find.text('1200 xu'), findsNothing);
  });

  testWidgets(
    'Location validates, cancels without changes and clears stale GPS on save',
    (tester) async {
      final container = await _open(tester, routed: true);
      final homeState = tester.state(find.byType(HomeScreen));
      await _tap(tester, find.byKey(const ValueKey('home-location')));
      expect(find.text('Xác nhận vị trí gặp sự cố'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('incident-map-search')));
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
      await _tap(tester, find.byTooltip('Quay lại'));
      expect(container.read(rescueLocationProvider), same(_location));
      await _tap(tester, find.byKey(const ValueKey('home-location')));
      await _tap(tester, find.byKey(const ValueKey('incident-map-search')));
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
      expect(tester.state(find.byType(HomeScreen)), same(homeState));
      expect(container.read(activityProvider).orders, isEmpty);
      expect(
        find.byKey(const ValueKey('incident-request-submit')),
        findsNothing,
      );
      expect(
        container.read(rescueLocationProvider)!.address,
        '45 Lê Văn Sỹ, TP. Hồ Chí Minh',
      );
      expect(container.read(rescueLocationProvider)!.hasCoordinates, isFalse);
      expect(find.text('45 Lê Văn Sỹ, TP. Hồ Chí Minh'), findsOneWidget);
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
      await _tap(tester, find.byTooltip('Quay lại'));
      for (var step = 0; step < 2; step++) {
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
      await scrollHomeToStations(tester);
      await _tap(tester, find.text(station.name));
      expect(find.text(station.address), findsOneWidget);
      expect(
        tester
            .widget<StationDetailScreen>(find.byType(StationDetailScreen))
            .station
            .id,
        station.id,
      );
      await _tap(tester, find.byKey(const ValueKey('station-back')));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(selected, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [rescueStationsProvider.overrideWithValue([])],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await scrollHomeToStations(tester);
      await tester.ensureVisible(find.text('Không tìm thấy trạm phù hợp'));
      expect(find.text('Không tìm thấy trạm phù hợp'), findsOneWidget);
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
      await _tap(tester, find.byKey(const ValueKey('home-location')));
      await _tap(tester, find.byKey(const ValueKey('incident-map-search')));
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
      expect(find.byType(HomeScreen), findsOneWidget);
      await _checkout(tester, HomeService.tire);
      await tester.ensureVisible(_confirm);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Four tabs keep their scoped active colors and preserve session selection',
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
      _expectSelectedNavigation(tester, HomeDestination.home);
      for (final (destination, path) in [
        (HomeDestination.activity, '/hoat-dong'),
        (HomeDestination.rescueStations, '/tram-cuu-ho'),
        (HomeDestination.account, '/tai-khoan'),
      ]) {
        await _tap(tester, find.text(destination.navigationLabel));
        expect(router.state.uri.path, path);
        _expectSelectedNavigation(tester, destination);
        router.pop();
        await tester.pumpAndSettle();
        _expectSelectedNavigation(tester, HomeDestination.home);
        expect(find.byTooltip('Tài khoản Nguyễn An'), findsOneWidget);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomeScreen)),
        );
        expect(container.read(defaultVehicleProvider)!.id, 'vision');
        expect(find.text(_location.address), findsOneWidget);
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
    expect(find.byTooltip('Tài khoản Nguyễn An'), findsOneWidget);
    router.push('/bang-gia');
    await tester.pumpAndSettle();
    await _tap(
      tester,
      find.descendant(of: nav, matching: find.text('Bản đồ trạm')),
    );
    expect(router.state.uri.path, '/tram-cuu-ho');
    router.pop();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/trang-chu');
    expect(find.byTooltip('Tài khoản Nguyễn An'), findsOneWidget);
    expect(router.canPop(), isFalse);
  });
}
