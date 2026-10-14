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
import '../models/place_suggestion.dart';
import '../models/location_search_state.dart';

final locationSearchProvider = NotifierProvider.autoDispose
    .family<
      LocationSearchController,
      LocationSearchState,
      (Object, RescueLocation?)
    >(LocationSearchController.new);

class LocationSearchController extends Notifier<LocationSearchState> {
  LocationSearchController(this.key);
  final (Object, RescueLocation?) key;
  late RescueLocation _initial, _addressSource;
  String _query = '';
  bool _openingMap = false, _searching = false, _resolving = false;
  String? _error;
  List<PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  CancelToken? _searchCancel, _detailCancel;
  int _revision = 0;
  String _sessionToken = newPlacesSessionToken();
  @override
  LocationSearchState build() {
    _initial =
        key.$2 ??
        ref.read(rescueLocationProvider) ??
        ref.read(incidentCurrentLocationProvider);
    _addressSource = _initial;
    ref.onDispose(() {
      _revision++;
      _debounce?.cancel();
      _searchCancel?.cancel();
      _detailCancel?.cancel();
    });
    return _snapshot();
  }

  LocationSearchState _snapshot() => LocationSearchState(
    source: _addressSource,
    query: _query,
    openingMap: _openingMap,
    searching: _searching,
    resolving: _resolving,
    error: _error,
    suggestions: _suggestions,
  );
  void _publish(void Function() update) {
    update();
    state = _snapshot();
  }

  bool _current(int revision) => ref.mounted && revision == _revision;
  void editQuery(String value) {
    _debounce?.cancel();
    _searchCancel?.cancel();
    _detailCancel?.cancel();
    final revision = ++_revision;
    _publish(() {
      _query = value.trim();
      _addressSource = RescueLocation(address: value.trim());
      _suggestions = [];
      _searching = false;
      _resolving = false;
      _openingMap = false;
      _error = null;
    });
    if (_query.isEmpty) {
      _sessionToken = newPlacesSessionToken();
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_search(_query, revision)),
    );
  }

  Future<void> _search(String query, int revision) async {
    if (!_current(revision)) return;
    final cancel = _searchCancel = CancelToken();
    _publish(() => _searching = true);
    try {
      final suggestions = await ref
          .read(placesServiceProvider)
          .autocomplete(
            query,
            sessionToken: _sessionToken,
            bias: _initial.hasCoordinates
                ? LatLng(_initial.latitude!, _initial.longitude!)
                : null,
            cancelToken: cancel,
          );
      if (_current(revision)) _publish(() => _suggestions = suggestions);
    } on Exception catch (error) {
      if (_current(revision) &&
          !(error is DioException && CancelToken.isCancel(error))) {
        _publish(
          () => _error = error is PlacesException
              ? error.message
              : 'Không tìm được địa điểm. Vui lòng thử lại.',
        );
      }
    } finally {
      if (_current(revision)) _publish(() => _searching = false);
    }
  }

  Future<RescueLocation?> selectSuggestion(PlaceSuggestion suggestion) async {
    if (_resolving || _openingMap) return null;
    _debounce?.cancel();
    _searchCancel?.cancel();
    final revision = ++_revision;
    final cancel = _detailCancel = CancelToken();
    _publish(() {
      _resolving = true;
      _searching = false;
      _error = null;
    });
    try {
      final token = _sessionToken;
      _sessionToken = newPlacesSessionToken();
      final location = await ref
          .read(placesServiceProvider)
          .detail(suggestion.id, sessionToken: token, cancelToken: cancel);
      if (!_current(revision)) return null;
      return location;
    } on Exception catch (error) {
      if (_current(revision) &&
          !(error is DioException && CancelToken.isCancel(error))) {
        _publish(
          () => _error = error is PlacesException
              ? error.message
              : 'Chưa lấy được tọa độ. Vui lòng chọn lại địa điểm.',
        );
      }
    } finally {
      if (_current(revision)) _publish(() => _resolving = false);
    }
    return null;
  }

  Future<RescueLocation?> useGps() async {
    if (_resolving || _openingMap) return null;
    _debounce?.cancel();
    _searchCancel?.cancel();
    final revision = ++_revision;
    _publish(() {
      _resolving = true;
      _error = null;
      _searching = false;
    });
    try {
      final location = await ref
          .read(deviceLocationProvider)()
          .timeout(const Duration(seconds: 24));
      if (_current(revision)) return location;
    } on Exception catch (error) {
      if (_current(revision)) {
        _publish(
          () => _error = error is LocationLookupException
              ? error.message
              : 'Chưa lấy được GPS. Bạn có thể nhập địa chỉ.',
        );
      }
    } finally {
      if (_current(revision)) _publish(() => _resolving = false);
    }
    return null;
  }

  void acceptPlace(RescueLocation place) => _publish(() {
    _addressSource = place;
    _query = '';
  });
  void closeMap() => _publish(() => _openingMap = false);
  Future<RescueLocation?> prepareMap({
    required String address,
    required String landmark,
    bool pickOnMap = false,
  }) async {
    if (_openingMap) return null;
    _debounce?.cancel();
    _searchCancel?.cancel();
    _publish(() {
      _openingMap = true;
      _error = null;
    });
    final revision = _revision;
    var resolved = address.trim() == _addressSource.address.trim()
        ? _addressSource
        : RescueLocation(address: address.trim());
    try {
      if (!pickOnMap &&
          !resolved.hasCoordinates &&
          ref.read(locationApiConfigProvider).geocodingConfigured) {
        final cancel = _detailCancel = CancelToken();
        resolved = await ref
            .read(placesServiceProvider)
            .geocode(address.trim(), cancelToken: cancel);
      }
    } on Exception catch (error) {
      if (_current(revision)) {
        _publish(() {
          _openingMap = false;
          _error = error is PlacesException ? error.message : 'Chưa tìm được tọa độ địa chỉ này. Hãy chọn một kết quả tìm kiếm.';
        });
      }
      return null;
    }
    if (!_current(revision)) return null;
    return RescueLocation(
      address: resolved.address,
      landmark: landmark.trim(),
      latitude: resolved.latitude,
      longitude: resolved.longitude,
    );
  }
}
