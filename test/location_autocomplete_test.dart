import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/home/models/rescue_location.dart';
import 'package:moto_care/features/home/providers/home_provider.dart';
import 'package:moto_care/features/location/models/place_suggestion.dart';
import 'package:moto_care/features/location/providers/incident_location_provider.dart';
import 'package:moto_care/features/location/services/device_location_service.dart';
import 'package:moto_care/features/location/services/location_api_config.dart';
import 'package:moto_care/features/location/services/places_service.dart';
import 'package:moto_care/features/location/widgets/incident_google_map.dart';

import 'fixtures/location_fixture.dart';

const _saved = RescueLocation(
  address: '273 An Dương Vương, Quận 5',
  landmark: 'Cổng chính',
  latitude: 10.757,
  longitude: 106.668,
);
Finder get _address => find.byKey(const ValueKey('incident-address'));
Finder get _place => find.byKey(const ValueKey('place-vincom'));
ProviderContainer _state(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
Future<GoRouter> _open(
  WidgetTester tester, {
  required TestIncidentMap map,
  PlacesService? service,
  bool configured = true,
  RescueLocation? saved = _saved,
  bool onMap = false,
  Future<RescueLocation> Function()? gps,
}) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialRescueLocationProvider.overrideWithValue(saved),
        incidentMapBuilderProvider.overrideWithValue(map.build),
        locationApiConfigProvider.overrideWithValue(
          configured
              ? const LocationApiConfig(
                  placesKey: 'test',
                  geocodingKey: 'test',
                  androidMapsKey: 'test',
                )
              : const LocationApiConfig(),
        ),
        if (service != null) placesServiceProvider.overrideWithValue(service),
        deviceLocationProvider.overrideWithValue(gps ?? () async => _saved),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    ),
  );
  router.go(onMap ? '/incident-map-picker' : '/incident-location');
  await tester.pumpAndSettle();
  return router;
}

Future<void> _ensureVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      80,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('incident-search-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _ensureVisible(tester, finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _query(WidgetTester tester, String query) async {
  await tester.enterText(_address, query);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

void main() {
  testWidgets(
    '300ms debounce sends only the newest keyword and clearing cancels work',
    (tester) async {
      final service = TestPlacesService();
      await _open(tester, map: TestIncidentMap(), service: service);
      for (final text in ['v', 'vi', 'vincom']) {
        await tester.enterText(_address, text);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 199));
      expect(service.searches, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(service.searches, ['vincom']);
      expect(find.text(testPlace.title), findsOneWidget);
      expect(find.text(testPlace.address), findsOneWidget);
      await tester.enterText(_address, 'bệnh viện');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byTooltip('Xóa địa chỉ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(service.searches, ['vincom']);
      expect(_place, findsNothing);
    },
  );
  testWidgets(
    'Late autocomplete and place-detail results cannot overwrite edited text',
    (tester) async {
      final old = Completer<List<PlaceSuggestion>>(),
          detail = Completer<RescueLocation>();
      final service = TestPlacesService(
        search: (input) =>
            input == 'vin' ? old.future : Future.value([testPlace]),
        lookup: (_) => detail.future,
      );
      final router = await _open(
        tester,
        map: TestIncidentMap(),
        service: service,
      );
      await _query(tester, 'vin');
      await _query(tester, 'ktx');
      old.complete([
        const PlaceSuggestion(
          id: 'old',
          title: 'Old result',
          address: 'Old address',
        ),
      ]);
      await tester.pump();
      expect(find.text('Old result'), findsNothing);
      expect(service.cancellations.first!.isCancelled, isTrue);
      await tester.tap(_place);
      await tester.pump();
      await tester.enterText(_address, 'bệnh viện');
      detail.complete(testPlaceLocation);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/incident-location');
      expect(
        tester.widget<TextFormField>(_address).controller!.text,
        'bệnh viện',
      );
      expect(_state(tester).read(rescueLocationProvider), same(_saved));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Selecting from map search pops back, animates zoom 17 and updates only the draft',
    (tester) async {
      final map = TestIncidentMap(), service = TestPlacesService();
      final router = await _open(
        tester,
        map: map,
        service: service,
        onMap: true,
      );
      final pin = find.byKey(const ValueKey('incident-sos-pin'));
      final pinPosition = tester.getCenter(pin);
      await _tap(tester, find.byKey(const ValueKey('incident-map-search')));
      await _query(tester, 'vincom');
      await tester.enterText(
        find.byKey(const ValueKey('incident-landmark')),
        'Cổng phía Tây',
      );
      await _tap(tester, _place);
      expect(router.state.uri.path, '/incident-map-picker');
      expect(map.movements.last, (const LatLng(10.778, 106.701), 17.0));
      expect(find.text(testPlaceLocation.address), findsOneWidget);
      expect(find.text('Cổng phía Tây'), findsOneWidget);
      expect(tester.getCenter(pin), pinPosition);
      expect(service.tokens.toSet(), hasLength(1));
      expect(_state(tester).read(rescueLocationProvider), same(_saved));
      await _tap(
        tester,
        find.byKey(const ValueKey('incident-confirm-location')),
      );
      final saved = _state(tester).read(rescueLocationProvider)!;
      expect(saved.latitude, 10.778);
      expect(saved.longitude, 106.701);
      expect(saved.landmark, 'Cổng phía Tây');
      expect(
        _state(tester)
            .read(recentIncidentPlacesProvider)
            .first
            .location
            .address,
        testPlaceLocation.address,
      );
    },
  );
  testWidgets('A selected coordinate waits for a late native map controller', (
    tester,
  ) async {
    final map = TestIncidentMap()..autoCreate = false;
    final router = await _open(
      tester,
      map: map,
      service: TestPlacesService(),
      onMap: true,
    );
    await _tap(tester, find.byKey(const ValueKey('incident-map-search')));
    await _query(tester, 'vincom');
    await _tap(tester, _place);
    expect(router.state.uri.path, '/incident-map-picker');
    expect(map.movements, isEmpty);
    map.create();
    await tester.pumpAndSettle();
    expect(map.movements.single, (const LatLng(10.778, 106.701), 17.0));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Reverse geocoding races preserve camera coordinates, even if an address snaps elsewhere',
    (tester) async {
      final old = Completer<RescueLocation>();
      final map = TestIncidentMap();
      final service = TestPlacesService(
        reverse: (point) => point.latitude == 10.76
            ? old.future
            : Future.value(
                const RescueLocation(
                  address: 'Địa chỉ mới nhất, Quận 1',
                  latitude: 10.78,
                  longitude: 106.72,
                ),
              ),
      );
      await _open(tester, map: map, service: service, onMap: true);
      map.pan(const LatLng(10.76, 106.7));
      await tester.pump();
      map.pan(const LatLng(10.77, 106.71));
      await tester.pump();
      old.complete(
        const RescueLocation(
          address: 'Địa chỉ cũ, Quận 5',
          latitude: 10.76,
          longitude: 106.7,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Địa chỉ cũ, Quận 5'), findsNothing);
      expect(find.text('Địa chỉ mới nhất, Quận 1'), findsOneWidget);
      await _tap(
        tester,
        find.byKey(const ValueKey('incident-confirm-location')),
      );
      expect(_state(tester).read(rescueLocationProvider)!.latitude, 10.77);
      expect(_state(tester).read(rescueLocationProvider)!.longitude, 106.71);
    },
  );
  testWidgets(
    'Dragging during GPS acquisition discards late GPS and leaves the map usable',
    (tester) async {
      final gps = Completer<RescueLocation>(), map = TestIncidentMap();
      await _open(
        tester,
        map: map,
        service: TestPlacesService(),
        onMap: true,
        gps: () => gps.future,
      );
      await tester.tap(find.byKey(const ValueKey('incident-map-gps')));
      await tester.pump();
      map.pan(testPannedPoint);
      await tester.pump();
      gps.complete(testPlaceLocation);
      await tester.pumpAndSettle();
      expect(find.text(testPannedAddress), findsOneWidget);
      expect(find.text(testPlaceLocation.address), findsNothing);
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('incident-map-gps')))
            .onPressed,
        isNotNull,
      );
    },
  );
  testWidgets(
    'Missing API configuration and detail failures never commit a bogus location',
    (tester) async {
      await _open(tester, map: TestIncidentMap(), configured: false);
      await _query(tester, 'ktx');
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Tìm kiếm địa điểm chưa sẵn sàng'),
        findsOneWidget,
      );
      expect(_state(tester).read(rescueLocationProvider), same(_saved));
      await tester.pumpWidget(const SizedBox());
      final service = TestPlacesService(
        lookup: (_) async =>
            throw const PlacesException('Chưa lấy được tọa độ.'),
      );
      final router = await _open(
        tester,
        map: TestIncidentMap(),
        service: service,
      );
      await _query(tester, 'vincom');
      await _tap(tester, _place);
      expect(router.state.uri.path, '/incident-location');
      expect(find.text('Chưa lấy được tọa độ.'), findsOneWidget);
      await _tap(tester, _place);
      expect(service.details, hasLength(2));
      expect(_state(tester).read(rescueLocationProvider), same(_saved));
    },
  );
  testWidgets(
    'An empty draft opens a map without turning its default viewport into an incident',
    (tester) async {
      final map = TestIncidentMap();
      final router = await _open(
        tester,
        map: map,
        service: TestPlacesService(),
        saved: null,
      );
      expect(tester.widget<TextFormField>(_address).controller!.text, isEmpty);
      await _tap(tester, find.text('Chọn trên bản đồ'));
      expect(router.state.uri.path, '/incident-map-picker');
      map.request!.onMove(map.request!.target);
      map.request!.onIdle();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('incident-sos-pin')), findsNothing);
      expect(_state(tester).read(rescueLocationProvider), isNull);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('incident-confirm-location')),
            )
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets(
    'A failed camera animation cannot confirm a mismatched pin and GPS can retry',
    (tester) async {
      final map = TestIncidentMap()..failAnimation = true;
      await _open(tester, map: map, service: TestPlacesService(), onMap: true);
      expect(find.textContaining('Chưa di chuyển được bản đồ'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('incident-confirm-location')),
            )
            .onPressed,
        isNull,
      );
      map.failAnimation = false;
      await _tap(tester, find.byKey(const ValueKey('incident-map-gps')));
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('incident-confirm-location')),
            )
            .onPressed,
        isNotNull,
      );
      expect(_state(tester).read(rescueLocationProvider), same(_saved));
    },
  );
  testWidgets(
    'Disposing during a search cancels transport and ignores completion',
    (tester) async {
      final pending = Completer<List<PlaceSuggestion>>();
      final service = TestPlacesService(search: (_) => pending.future);
      await _open(tester, map: TestIncidentMap(), service: service);
      await _query(tester, 'bệnh viện');
      await tester.pumpWidget(const SizedBox());
      pending.complete([testPlace]);
      await tester.pump();
      expect(service.cancellations.single!.isCancelled, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Dynamic results and return-to-map fit 320px with large text and keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _open(
        tester,
        map: TestIncidentMap(),
        service: TestPlacesService(),
        onMap: true,
      );
      await _tap(tester, find.byKey(const ValueKey('incident-map-search')));
      await tester.tap(_address);
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      await _query(tester, 'vincom');
      await _ensureVisible(tester, _place);
      await tester.pump();
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pump();
      await _tap(tester, _place);
      expect(tester.takeException(), isNull);
    },
  );
}
