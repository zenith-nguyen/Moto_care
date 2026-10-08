import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../home/models/rescue_location.dart';
import '../../home/providers/home_provider.dart';
import '../services/device_location_service.dart';
import '../services/location_api_config.dart';
import '../services/places_service.dart';
import 'incident_location_provider.dart';
import '../models/incident_map_state.dart';
import '../services/incident_camera_controller.dart';

final incidentMapProvider = NotifierProvider.autoDispose
    .family<IncidentMapController, IncidentMapState, (Object, RescueLocation?)>(
      IncidentMapController.new,
    );

class IncidentMapController extends Notifier<IncidentMapState> {
  IncidentMapController(this.key);
  final (Object, RescueLocation?) key;
  late RescueLocation _location;
  IncidentCameraController? _mapController;
  late LatLng _cameraTarget;
  LatLng? _programmaticTarget;
  bool _programmaticMoving = false;
  CancelToken? _geocodeCancel;
  int _revision = 0;
  bool _resolvingAddress = false,
      _locating = false,
      _moving = false,
      _cameraError = false,
      _searchOpen = false;
  String? _error;
  @override
  IncidentMapState build() {
    _location =
        key.$2 ??
        ref.read(rescueLocationProvider) ??
        ref.read(incidentCurrentLocationProvider);
    _cameraTarget = _location.hasCoordinates
        ? LatLng(_location.latitude!, _location.longitude!)
        : const LatLng(10.762622, 106.660172);
    ref.onDispose(() {
      _revision++;
      _geocodeCancel?.cancel();
    });
    return _snapshot();
  }

  IncidentMapState _snapshot() => IncidentMapState(
    location: _location,
    cameraTarget: _cameraTarget,
    cameraReady: _mapController != null,
    resolvingAddress: _resolvingAddress,
    locating: _locating,
    moving: _moving,
    cameraError: _cameraError,
    searchOpen: _searchOpen,
    error: _error,
  );
  void _publish(void Function() update) {
    update();
    state = _snapshot();
  }

  bool _current(int revision) => ref.mounted && revision == _revision;
  bool _samePoint(LatLng a, LatLng b) =>
      (a.latitude - b.latitude).abs() < .000001 &&
      (a.longitude - b.longitude).abs() < .000001;
  Future<void> initialize() async {
    if (!_location.hasCoordinates &&
        _location.address.isNotEmpty &&
        ref.read(locationApiConfigProvider).geocodingConfigured) {
      await resolveInitial();
    }
  }

  Future<void> resolveInitial() async {
    final revision = ++_revision;
    final cancel = _geocodeCancel = CancelToken();
    _publish(() => _resolvingAddress = true);
    try {
      final location = await ref
          .read(placesServiceProvider)
          .geocode(_location.address, cancelToken: cancel);
      if (_current(revision)) _applyLocation(location);
    } on Exception catch (error) {
      if (_current(revision)) {
        _publish(
          () => _error = error is PlacesException
              ? error.message
              : 'Chưa tìm được tọa độ. Hãy tìm địa điểm hoặc dùng GPS.',
        );
      }
    } finally {
      if (_current(revision)) _publish(() => _resolvingAddress = false);
    }
  }

  void onMapCreated(IncidentCameraController controller) {
    if (!ref.mounted) return;
    _publish(() => _mapController = controller);
    _programmaticTarget = _cameraTarget;
    _programmaticMoving = false;
    if (_location.hasCoordinates) {
      _programmaticTarget = LatLng(_location.latitude!, _location.longitude!);
      unawaited(_animate(_programmaticTarget!));
    }
  }

  Future<void> _animate(LatLng target) async {
    try {
      await _mapController?.animateTo(target, zoom: 17);
    } on Exception {
      if (ref.mounted && _programmaticTarget == target) {
        _publish(() {
          _programmaticTarget = null;
          _cameraError = true;
          _moving = false;
          _error = 'Chưa di chuyển được bản đồ. Hãy thử lại.';
        });
      }
    }
  }

  void _applyLocation(RescueLocation result) {
    _revision++;
    _geocodeCancel?.cancel();
    final target = LatLng(result.latitude!, result.longitude!);
    _publish(() {
      _location = RescueLocation(
        address: result.address,
        landmark: _location.landmark,
        latitude: target.latitude,
        longitude: target.longitude,
      );
      _cameraTarget = target;
      _programmaticTarget = target;
      _programmaticMoving = false;
      _locating = false;
      _resolvingAddress = false;
      _moving = false;
      _cameraError = false;
      _error = null;
    });
    if (_mapController != null) unawaited(_animate(target));
  }

  void onMoveStarted() {
    if (!ref.mounted || _searchOpen) return;
    _revision++;
    _geocodeCancel?.cancel();
    _publish(() {
      _moving = true;
      _cameraError = false;
      _locating = false;
      _resolvingAddress = false;
      if (_programmaticTarget != null) _programmaticMoving = true;
    });
  }

  void onCameraMove(LatLng point) {
    if (!ref.mounted || _searchOpen) return;
    _cameraTarget = point;
    if (_programmaticTarget != null || !_moving) return;
    _publish(() => _location = _coordinateLocation(point));
  }

  RescueLocation _coordinateLocation(LatLng point) => RescueLocation(
    address:
        'GPS: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
    landmark: _location.landmark,
    latitude: point.latitude,
    longitude: point.longitude,
  );

  void onCameraIdle() {
    if (!ref.mounted || _searchOpen) return;
    final expected = _programmaticTarget;
    if (expected != null) {
      if (_samePoint(expected, _cameraTarget)) {
        _publish(() {
          _programmaticTarget = null;
          _programmaticMoving = false;
          _moving = false;
        });
        return;
      }
      if (!_programmaticMoving) return;
      _programmaticTarget = null;
      _programmaticMoving = false;
    }
    if (!_moving) return;
    final point = _cameraTarget;
    _publish(() {
      _moving = false;
      _location = _coordinateLocation(point);
    });
    unawaited(_resolvePinAddress(point));
  }

  Future<void> _resolvePinAddress(LatLng point) async {
    final revision = ++_revision;
    _geocodeCancel?.cancel();
    final cancel = _geocodeCancel = CancelToken();
    _publish(() {
      _resolvingAddress = true;
      _error = null;
    });
    try {
      final resolved = await ref
          .read(placesServiceProvider)
          .reverseGeocode(point, cancelToken: cancel);
      if (_current(revision)) {
        _publish(
          () => _location = RescueLocation(
            address: resolved.address,
            landmark: _location.landmark,
            latitude: point.latitude,
            longitude: point.longitude,
          ),
        );
      }
    } on Exception catch (error) {
      if (_current(revision) &&
          !(error is DioException && CancelToken.isCancel(error))) {
        _publish(
          () => _error = 'Chưa tra được tên đường. Vị trí GPS của ghim vẫn được giữ chính xác.',
        );
      }
    } finally {
      if (_current(revision)) _publish(() => _resolvingAddress = false);
    }
  }

  Future<void> recenter() async {
    if (_locating) return;
    _geocodeCancel?.cancel();
    final revision = ++_revision;
    _publish(() {
      _locating = true;
      _resolvingAddress = false;
      _error = null;
    });
    try {
      final current = await ref
          .read(deviceLocationProvider)()
          .timeout(const Duration(seconds: 24));
      if (_current(revision)) _applyLocation(current);
    } on Exception catch (error) {
      if (_current(revision)) {
        _publish(
          () => _error = error is LocationLookupException
              ? error.message
              : 'Chưa lấy được GPS. Hãy thử lại hoặc tìm địa điểm.',
        );
      }
    } finally {
      if (_current(revision)) _publish(() => _locating = false);
    }
  }

  bool beginSearch() {
    if (_searchOpen || _locating) return false;
    _revision++;
    _geocodeCancel?.cancel();
    _publish(() {
      _searchOpen = true;
      _resolvingAddress = false;
    });
    return true;
  }

  void endSearch(RescueLocation? selected) {
    _publish(() => _searchOpen = false);
    if (selected == null) return;
    if (!selected.hasCoordinates) {
      _publish(
        () => _error =
            'Địa chỉ chưa có tọa độ. Hãy chọn kết quả tìm kiếm hoặc dùng GPS.',
      );
      return;
    }
    _applyLocation(selected);
    _publish(
      () => _location = RescueLocation(
        address: _location.address,
        landmark: selected.landmark,
        latitude: _location.latitude,
        longitude: _location.longitude,
      ),
    );
  }

  bool get canConfirm =>
      !state.busy &&
      _location.address.trim().length >= 5 &&
      (!ref.read(locationApiConfigProvider).mapConfigured ||
          _location.hasCoordinates);
  bool confirm() {
    if (!canConfirm ||
        !ref.read(rescueLocationProvider.notifier).confirmLocation(_location)) {
      return false;
    }
    ref.read(incidentHistoryProvider.notifier).remember(_location);
    return true;
  }
}
