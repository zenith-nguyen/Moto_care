import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moto_care/features/home/models/rescue_location.dart';
import 'package:moto_care/features/location/models/place_suggestion.dart';
import 'package:moto_care/features/location/services/places_service.dart';
import 'package:moto_care/features/location/widgets/incident_google_map.dart';

const testPlace = PlaceSuggestion(
  id: 'vincom',
  title: 'Vincom Đồng Khởi',
  address: '72 Lê Thánh Tôn, Quận 1, TP. Hồ Chí Minh',
);
const testPlaceLocation = RescueLocation(
  address: '72 Lê Thánh Tôn, Quận 1, TP. Hồ Chí Minh',
  latitude: 10.778,
  longitude: 106.701,
);
const testPannedPoint = LatLng(10.758, 106.667);
const testPannedAddress = '118 Bùi Văn Ba, Tân Thuận, Q.7';

class TestPlacesService implements PlacesService {
  TestPlacesService({this.search, this.lookup, this.reverse, this.forward});
  final Future<List<PlaceSuggestion>> Function(String)? search;
  final Future<RescueLocation> Function(String)? lookup;
  final Future<RescueLocation> Function(LatLng)? reverse;
  final Future<RescueLocation> Function(String)? forward;
  final searches = <String>[];
  final details = <String>[];
  final tokens = <String>[];
  final cancellations = <CancelToken?>[];
  @override
  Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    required String sessionToken,
    LatLng? bias,
    CancelToken? cancelToken,
  }) async {
    searches.add(input);
    tokens.add(sessionToken);
    cancellations.add(cancelToken);
    return search == null ? [testPlace] : await search!(input);
  }

  @override
  Future<RescueLocation> detail(
    String placeId, {
    required String sessionToken,
    CancelToken? cancelToken,
  }) async {
    details.add(placeId);
    tokens.add(sessionToken);
    cancellations.add(cancelToken);
    return lookup == null ? testPlaceLocation : await lookup!(placeId);
  }

  @override
  Future<RescueLocation> geocode(
    String address, {
    CancelToken? cancelToken,
  }) async => forward == null
      ? RescueLocation(address: address, latitude: 10.75, longitude: 106.7)
      : await forward!(address);
  @override
  Future<RescueLocation> reverseGeocode(
    LatLng point, {
    CancelToken? cancelToken,
  }) async => reverse == null
      ? RescueLocation(
          address: testPannedAddress,
          latitude: point.latitude,
          longitude: point.longitude,
        )
      : await reverse!(point);
}

class TestIncidentMap implements IncidentCameraController {
  IncidentMapRequest? request;
  bool autoCreate = true;
  bool failAnimation = false;
  final movements = <(LatLng, double)>[];
  Widget build(BuildContext context, IncidentMapRequest request) {
    this.request = request;
    return _TestMap(controller: this);
  }

  void create() => request!.onCreated(this);
  void pan(LatLng target) {
    request!.onMoveStarted();
    request!.onMove(target);
    request!.onIdle();
  }

  @override
  Future<void> animateTo(LatLng target, {double zoom = 17}) async {
    if (failAnimation) throw Exception('camera unavailable');
    movements.add((target, zoom));
    request!.onMoveStarted();
    request!.onMove(target);
    request!.onIdle();
  }
}

class _TestMap extends StatefulWidget {
  const _TestMap({required this.controller});
  final TestIncidentMap controller;
  @override
  State<_TestMap> createState() => _TestMapState();
}

class _TestMapState extends State<_TestMap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.controller.autoCreate) widget.controller.create();
    });
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey('incident-map-canvas'),
    behavior: HitTestBehavior.opaque,
    onPanStart: (_) => widget.controller.request!.onMoveStarted(),
    onPanUpdate: (_) => widget.controller.request!.onMove(testPannedPoint),
    onPanEnd: (_) => widget.controller.request!.onIdle(),
    child: const ColoredBox(color: Color(0xFFF8F9FA), child: SizedBox.expand()),
  );
}
