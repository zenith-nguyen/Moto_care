import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moto_care/features/location/services/device_location_service.dart';

class _GpsPlatform extends GeolocatorPlatform {
  bool enabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission requested = LocationPermission.whileInUse;
  int requests = 0;
  int positionCalls = 0;
  LocationSettings? settings;
  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return requested;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    positionCalls++;
    settings = locationSettings;
    return Position(
      longitude: 106.668,
      latitude: 10.757,
      timestamp: DateTime(2026, 10, 6),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  late GeolocatorPlatform original;
  late _GpsPlatform gps;
  setUp(() {
    original = GeolocatorPlatform.instance;
    gps = _GpsPlatform();
    GeolocatorPlatform.instance = gps;
  });
  tearDown(() => GeolocatorPlatform.instance = original);

  test(
    'GPS disabled returns an actionable error without acquiring a position',
    () async {
      gps.enabled = false;
      await expectLater(
        locateDevice(),
        throwsA(isA<LocationLookupException>()),
      );
      expect(gps.positionCalls, 0);
    },
  );
  test(
    'Permanent denial does not request permissions or fabricate a location',
    () async {
      gps.permission = LocationPermission.deniedForever;
      await expectLater(
        locateDevice(),
        throwsA(isA<LocationLookupException>()),
      );
      expect(gps.requests, 0);
      expect(gps.positionCalls, 0);
    },
  );
  test('A rejected permission request blocks GPS acquisition', () async {
    gps.permission = LocationPermission.denied;
    gps.requested = LocationPermission.denied;
    await expectLater(locateDevice(), throwsA(isA<LocationLookupException>()));
    expect(gps.requests, 1);
    expect(gps.positionCalls, 0);
  });
  test('Granted foreground permission preserves actual coordinates with a bounded lookup', () async {
    gps.permission = LocationPermission.denied;
    final location = await locateDevice();
    expect(gps.requests, 1);
    expect(location.latitude, 10.757);
    expect(location.longitude, 106.668);
    expect(location.address, contains('GPS:'));
    expect(gps.settings!.accuracy, LocationAccuracy.high);
    expect(gps.settings!.timeLimit, const Duration(seconds: 12));
  });
}
