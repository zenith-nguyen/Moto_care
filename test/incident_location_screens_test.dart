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
import 'package:moto_care/features/home/models/rescue_location.dart';
import 'package:moto_care/features/home/providers/home_provider.dart';
import 'package:moto_care/features/home/theme/home_theme.dart';
import 'package:moto_care/features/home/widgets/home_bottom_navigation.dart';
import 'package:moto_care/features/location/data/mock_incident_places.dart';
import 'package:moto_care/features/location/providers/incident_location_provider.dart';
import 'package:moto_care/features/location/models/place_suggestion.dart';
import 'package:moto_care/features/location/services/device_location_service.dart';
import 'package:moto_care/features/location/services/places_service.dart';
import 'package:moto_care/features/location/widgets/incident_google_map.dart';

import 'fixtures/location_fixture.dart';

import 'package:moto_care/features/location/screens/incident_location_search_screen.dart';
import 'package:moto_care/features/location/screens/incident_map_picker_screen.dart';
import 'package:moto_care/features/profile/models/user_profile.dart';
import 'package:moto_care/features/profile/providers/profile_provider.dart';
import 'package:moto_care/features/rescue/widgets/create_rescue_request_bottom_sheet.dart';
import 'package:moto_care/features/vehicle/models/vehicle.dart';
import 'package:moto_care/features/vehicle/providers/vehicle_provider.dart';

const _vehicle = Vehicle(
  id: 'vision',
  name: 'Honda Vision',
  brand: 'Honda',
  licensePlate: '59-A1 123.45',
  tireType: TireType.tubeless,
  engineType: EngineType.gas,
  isDefault: true,
);
const _saved = RescueLocation(
  address: '273 An Dương Vương, Quận 5',
  landmark: 'Cổng chính',
  latitude: 10.757,
  longitude: 106.668,
);

Future<GoRouter> _open(
  WidgetTester tester, {
  String path = '/incident-location',
  RescueLocation? saved,
  RescueLocation current = mockCurrentIncidentLocation,
  bool hasVehicle = true,
  bool active = false,
}) async {
  final router = createAppRouter();
  final map = TestIncidentMap();
  final places = TestPlacesService(
    search: (query) async => query == 'dao duy tu'
        ? [
            PlaceSuggestion(
              id: 'ueh',
              title: mockRecentIncidentPlaces[1].name,
              address: mockRecentIncidentPlaces[1].location.address,
            ),
          ]
        : [],
    lookup: (id) async => RescueLocation(
      address: mockRecentIncidentPlaces[1].location.address,
      latitude: 10.762,
      longitude: 106.666,
    ),
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        initialRescueLocationProvider.overrideWithValue(saved),
        recentIncidentPlacesProvider.overrideWithValue(
          mockRecentIncidentPlaces,
        ),
        deviceLocationProvider.overrideWithValue(() async => current),
        placesServiceProvider.overrideWithValue(places),
        incidentMapBuilderProvider.overrideWithValue(map.build),
        incidentCurrentLocationProvider.overrideWithValue(current),
        initialVehiclesProvider.overrideWithValue(hasVehicle ? [_vehicle] : []),
        initialRescueOrdersProvider.overrideWithValue(
          active ? mockRescueOrders : [],
        ),
        initialUserProfileProvider.overrideWithValue(
          const UserProfile(
            id: 'test-user',
            fullName: 'Nguyễn An',
            defaultAddress: '45 Lê Văn Sỹ, TP. Hồ Chí Minh',
            workAddress: '273 An Dương Vương, TP. Hồ Chí Minh',
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
      ),
    ),
  );
  router.go(path);
  await tester.pumpAndSettle();
  return router;
}

ProviderContainer _state(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

Finder get _address => find.byKey(const ValueKey('incident-address'));
Finder get _landmark => find.byKey(const ValueKey('incident-landmark'));
Finder get _confirm => find.byKey(const ValueKey('incident-confirm-location'));
Finder get _submit => find.byKey(const ValueKey('incident-request-submit'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final searchScroll = find.descendant(
      of: find.byKey(const ValueKey('incident-search-scroll')),
      matching: find.byType(Scrollable),
    );
    if (searchScroll.evaluate().isNotEmpty) {
      tester.state<ScrollableState>(searchScroll.first).position.jumpTo(0);
      await tester.pump();
    }
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable:
          find
              .byKey(const ValueKey('incident-search-scroll'))
              .evaluate()
              .isNotEmpty
          ? find
                .descendant(
                  of: find.byKey(const ValueKey('incident-search-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first
          : find
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
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder.hitTestable());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Search shows fields, shortcuts, injected history and light tabs',
    (tester) async {
      await _open(tester);
      expect(find.byType(IncidentLocationSearchScreen), findsOneWidget);
      expect(
        tester.widget<TextFormField>(_address).controller!.text,
        mockCurrentIncidentLocation.address,
      );
      for (final label in [
        'Vị trí gặp sự cố?',
        'Chọn trên bản đồ',
        'Sử dụng vị trí hiện tại của tôi',
        'Địa điểm quen thuộc',
        'Gần Nhà',
        'Gần Công ty',
        'Địa điểm gần đây',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(HomeBottomNavigation), findsOneWidget);
      expect(Theme.of(tester.element(_address)).brightness, Brightness.light);
      expect(
        Theme.of(tester.element(_address)).scaffoldBackgroundColor,
        HomeColors.background,
      );
      expect(_state(tester).read(rescueLocationProvider), isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Search sends an accentless query to Places and opens the resolved result',
    (tester) async {
      final router = await _open(tester);
      await tester.enterText(_address, 'dao duy tu');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Đại học Kinh tế UEH – Cổng Đào Duy Từ'),
        100,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('incident-search-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        find.text('Đại học Kinh tế UEH – Cổng Đào Duy Từ'),
        findsOneWidget,
      );
      expect(find.text('180/9a Bùi Văn Ba'), findsNothing);
      await _tap(tester, find.text('Đại học Kinh tế UEH – Cổng Đào Duy Từ'));
      expect(router.state.uri.path, '/incident-map-picker');
      expect(
        find.text(mockRecentIncidentPlaces[1].location.address),
        findsOneWidget,
      );
      expect(_state(tester).read(rescueLocationProvider), isNull);
    },
  );

  testWidgets('Home and work shortcuts use the saved profile addresses', (
    tester,
  ) async {
    final router = await _open(tester);
    for (final (chip, address) in [
      ('Gần Nhà', '45 Lê Văn Sỹ, TP. Hồ Chí Minh'),
      ('Gần Công ty', '273 An Dương Vương, TP. Hồ Chí Minh'),
    ]) {
      await _tap(tester, find.text(chip));
      expect(router.state.uri.path, '/incident-map-picker');
      expect(find.text(address), findsOneWidget);
      await _tap(tester, find.byTooltip('Quay lại'));
      expect(router.state.uri.path, '/incident-location');
    }
    expect(_state(tester).read(rescueLocationProvider), isNull);
  });

  testWidgets(
    'Current-location shortcut confirms the injected position and notes',
    (tester) async {
      final current = const RescueLocation(
        address: '120 Huỳnh Tấn Phát, Tân Thuận, Q.7',
        latitude: 10.74,
        longitude: 106.73,
      );
      await _open(tester, saved: _saved, current: current);
      await tester.enterText(_landmark, 'Cổng màu xanh');
      await _tap(tester, find.text('Sử dụng vị trí hiện tại của tôi'));
      expect(find.text(current.address), findsOneWidget);
      expect(_state(tester).read(rescueLocationProvider), same(_saved));
      await _tap(tester, _confirm);
      final confirmed = _state(tester).read(rescueLocationProvider)!;
      expect(confirmed.address, current.address);
      expect(confirmed.landmark, 'Cổng màu xanh');
      expect(confirmed.latitude, current.latitude);
      expect(confirmed.longitude, current.longitude);
    },
  );

  testWidgets(
    'Draft notes survive back navigation; cancelling leaves the saved location unchanged',
    (tester) async {
      final router = await _open(tester, path: '/trang-chu', saved: _saved);
      await _tap(tester, find.text('Sửa vị trí'));
      await tester.enterText(_address, 'abc');
      await _tap(tester, find.text('Chọn trên bản đồ'));
      expect(
        find.text('Vui lòng nhập địa chỉ ít nhất 5 ký tự.'),
        findsOneWidget,
      );
      await tester.enterText(_address, ' 120 Huỳnh Tấn Phát, Q.7 ');
      await tester.enterText(_landmark, 'Đối diện cây xăng');
      await _tap(tester, find.text('Chọn trên bản đồ'));
      expect(find.text('Đối diện cây xăng'), findsOneWidget);
      expect(_state(tester).read(rescueLocationProvider), same(_saved));
      await _tap(tester, find.byTooltip('Quay lại'));
      expect(
        tester.widget<TextFormField>(_landmark).controller!.text,
        'Đối diện cây xăng',
      );
      await _tap(tester, find.byTooltip('Quay lại'));
      expect(router.state.uri.path, '/trang-chu');
      expect(_state(tester).read(rescueLocationProvider), same(_saved));
    },
  );

  testWidgets(
    'Camera panning geocodes the address while the SOS pin stays fixed; GPS restores real coordinates',
    (tester) async {
      await _open(tester, path: '/incident-map-picker', current: _saved);
      final pin = find.byKey(const ValueKey('incident-sos-pin'));
      final before = tester.getCenter(pin);
      await tester.dragFrom(const Offset(400, 140), const Offset(150, 120));
      await tester.pumpAndSettle();
      expect(tester.getCenter(pin), before);
      expect(find.text(testPannedAddress), findsOneWidget);
      expect(_state(tester).read(rescueLocationProvider), isNull);
      await _tap(tester, find.byKey(const ValueKey('incident-map-gps')));
      expect(find.text(_saved.address), findsOneWidget);
      await _tap(tester, _confirm);
      final location = _state(tester).read(rescueLocationProvider)!;
      expect(location.latitude, _saved.latitude);
      expect(location.longitude, _saved.longitude);
    },
  );

  testWidgets(
    'Dragging the confirmation sheet expands it and moves the GPS button',
    (tester) async {
      await _open(tester, path: '/incident-map-picker');
      final sheet = tester.widget<DraggableScrollableSheet>(
        find.byType(DraggableScrollableSheet),
      );
      final initialSize = sheet.controller!.size;
      final gps = find.byKey(const ValueKey('incident-map-gps'));
      final before = tester.getCenter(gps);
      final list = find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byType(ListView),
      );
      final start = tester.getTopLeft(list) + const Offset(100, 24);
      await tester.dragFrom(start, const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(sheet.controller!.size, greaterThan(initialSize));
      expect(tester.getCenter(gps).dy, lessThan(before.dy));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Confirming opens request details and retains the location even when the modal is cancelled',
    (tester) async {
      await _open(tester);
      await tester.enterText(_landmark, 'Cổng trường bên phải');
      await _tap(tester, find.text('Chọn trên bản đồ'));
      await _tap(tester, _confirm);
      expect(find.byType(CreateRescueRequestBottomSheet), findsOneWidget);
      expect(
        _state(tester).read(rescueLocationProvider)!.landmark,
        'Cổng trường bên phải',
      );
      expect(
        _state(tester).read(rescueLocationProvider)!.hasCoordinates,
        isFalse,
      );
      await _tap(tester, find.byTooltip('Đóng'));
      expect(find.byType(CreateRescueRequestBottomSheet), findsNothing);
      expect(find.byType(IncidentMapPickerScreen), findsOneWidget);
      expect(_state(tester).read(activityProvider).orders, isEmpty);
    },
  );

  testWidgets(
    'Complete flow creates one order with selected service, vehicle, address and both notes',
    (tester) async {
      final router = await _open(tester, path: '/trang-chu');
      await _tap(tester, find.text('Sửa vị trí'));
      await tester.enterText(_address, ' 118 Bùi Văn Ba, Tân Thuận, Q.7 ');
      await tester.enterText(_landmark, ' Cạnh cổng trường ');
      await _tap(tester, find.text('Chọn trên bản đồ'));
      await _tap(tester, _confirm);
      await _tap(
        tester,
        find.byKey(const ValueKey('incident-request-service')),
      );
      await _tap(tester, find.text('Hết xăng').last);
      expect(find.text('Giao 2 Lít A95 (45k)'), findsOneWidget);
      await _tap(tester, find.text('Giao 4 Lít A95 (85k)'));
      final description = find.byKey(
        const ValueKey('incident-request-description'),
      );
      await tester.ensureVisible(description);
      await tester.enterText(description, ' Xe hết xăng giữa đường ');
      await _tap(tester, _submit);
      expect(router.state.uri.path, '/trang-chu');
      final orders = _state(tester).read(activityProvider).orders;
      expect(orders, hasLength(1));
      final order = orders.single;
      expect(order.serviceType, RescueServiceType.outOfFuel);
      expect(order.serviceOption, 'Giao 4 Lít A95 (85k)');
      expect(order.totalPrice, 85000);
      expect(order.userVehicle, 'Honda Vision (59-A1 123.45)');
      expect(order.locationAddress, '118 Bùi Văn Ba, Tân Thuận, Q.7');
      expect(order.locationLandmark, 'Cạnh cổng trường');
      expect(order.incidentDescription, 'Xe hết xăng giữa đường');
      expect(order.locationLatitude, isNull);
      expect(RescueOrder.fromJson(order.toJson()).toJson(), order.toJson());
      expect(find.byType(CreateRescueRequestBottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final (hasVehicle, active) in [(false, false), (true, true)]) {
    testWidgets(
      'Request blocks submission with ${active ? 'an active order' : 'no vehicle'}',
      (tester) async {
        await _open(
          tester,
          path: '/incident-map-picker',
          hasVehicle: hasVehicle,
          active: active,
        );
        final count = _state(tester).read(activityProvider).orders.length;
        await _tap(tester, _confirm);
        expect(tester.widget<FilledButton>(_submit).onPressed, isNull);
        expect(_state(tester).read(activityProvider).orders, hasLength(count));
        if (!hasVehicle) {
          expect(find.text('Thêm xe cần cứu hộ'), findsOneWidget);
        }
      },
    );
  }

  testWidgets(
    'Both screens and the request modal support 320px, large text and the keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _open(tester);
      await _tap(tester, _address);
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      await tester.pumpAndSettle();
      await tester.enterText(_address, mockCurrentIncidentLocation.address);
      await _tap(tester, _landmark);
      await tester.enterText(_landmark, 'Đối diện cây xăng');
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text('Chọn trên bản đồ'));
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _tap(tester, _confirm);
      final description = find.byKey(
        const ValueKey('incident-request-description'),
      );
      await _tap(tester, description);
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      await tester.pumpAndSettle();
      await tester.enterText(description, 'Xe không đề được');
      await tester.ensureVisible(_submit);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
