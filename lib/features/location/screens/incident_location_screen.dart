import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/main_navigation.dart';
import '../../activity/models/rescue_order.dart';
import '../../home/models/home_destination.dart';
import '../../home/models/rescue_location.dart';
import '../../home/providers/home_provider.dart';
import '../../home/theme/home_theme.dart';
import '../../home/widgets/home_bottom_navigation.dart';
import '../../home/widgets/home_sheets.dart';
import '../../rescue/widgets/create_rescue_request_bottom_sheet.dart';
import '../services/device_location_service.dart';
import '../services/location_api_config.dart';
import '../services/places_service.dart';
import '../providers/incident_location_provider.dart';
import '../widgets/incident_google_map.dart';
import '../widgets/incident_sos_pin.dart';

class IncidentLocationScreen extends ConsumerStatefulWidget {
  const IncidentLocationScreen({super.key, this.initialLocation});
  final RescueLocation? initialLocation;

  @override
  ConsumerState<IncidentLocationScreen> createState() =>
      _IncidentLocationScreenState();
}

class _IncidentLocationScreenState
    extends ConsumerState<IncidentLocationScreen> {
  final _sheetController = DraggableScrollableController();
  late final RescueLocation _initialLocation =
      widget.initialLocation ??
      ref.read(rescueLocationProvider) ??
      ref.read(incidentCurrentLocationProvider);
  late RescueLocation _location = _initialLocation;
  IncidentCameraController? _mapController;
  late LatLng _cameraTarget = _initialLocation.hasCoordinates
      ? LatLng(_initialLocation.latitude!, _initialLocation.longitude!)
      : const LatLng(10.762622, 106.660172);
  LatLng? _programmaticTarget;
  bool _programmaticMoving = false;
  CancelToken? _geocodeCancel;
  int _revision = 0;
  bool _confirming = false;
  bool _resolvingAddress = false;
  bool _locating = false;
  bool _moving = false;
  bool _cameraError = false;
  bool _searchOpen = false;
  String? _error;

  bool _current(int revision) => mounted && revision == _revision;
  bool _samePoint(LatLng a, LatLng b) =>
      (a.latitude - b.latitude).abs() < .000001 &&
      (a.longitude - b.longitude).abs() < .000001;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          !_location.hasCoordinates &&
          _location.address.isNotEmpty &&
          ref.read(locationApiConfigProvider).geocodingConfigured) {
        unawaited(_resolveInitial());
      }
    });
  }

  @override
  void dispose() {
    _revision++;
    _geocodeCancel?.cancel();
    // GoogleMap owns and disposes its native controller.
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _resolveInitial() async {
    final revision = ++_revision;
    final cancel = _geocodeCancel = CancelToken();
    setState(() => _resolvingAddress = true);
    try {
      final location = await ref
          .read(placesServiceProvider)
          .geocode(_location.address, cancelToken: cancel);
      if (_current(revision)) _applyLocation(location);
    } on Exception catch (error) {
      if (_current(revision)) {
        setState(
          () => _error = error is PlacesException
              ? error.message
              : 'Chưa tìm được tọa độ. Hãy tìm địa điểm hoặc dùng GPS.',
        );
      }
    } finally {
      if (_current(revision)) setState(() => _resolvingAddress = false);
    }
  }

  void _onMapCreated(IncidentCameraController controller) {
    if (!mounted) return;
    setState(() => _mapController = controller);
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
      if (mounted && _programmaticTarget == target) {
        setState(() {
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
    setState(() {
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

  void _onMoveStarted() {
    if (!mounted || _searchOpen) return;
    _revision++;
    _geocodeCancel?.cancel();
    setState(() {
      _moving = true;
      _cameraError = false;
      _locating = false;
      _resolvingAddress = false;
      if (_programmaticTarget != null) _programmaticMoving = true;
    });
  }

  void _onCameraMove(LatLng point) {
    if (!mounted || _searchOpen) return;
    _cameraTarget = point;
    if (_programmaticTarget != null || !_moving) return;
    setState(() => _location = _coordinateLocation(point));
  }

  RescueLocation _coordinateLocation(LatLng point) => RescueLocation(
    address:
        'GPS: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
    landmark: _location.landmark,
    latitude: point.latitude,
    longitude: point.longitude,
  );

  void _onCameraIdle() {
    if (!mounted || _searchOpen) return;
    final expected = _programmaticTarget;
    if (expected != null) {
      if (_samePoint(expected, _cameraTarget)) {
        setState(() {
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
    setState(() {
      _moving = false;
      _location = _coordinateLocation(point);
    });
    unawaited(_resolvePinAddress(point));
  }

  Future<void> _resolvePinAddress(LatLng point) async {
    final revision = ++_revision;
    _geocodeCancel?.cancel();
    final cancel = _geocodeCancel = CancelToken();
    setState(() {
      _resolvingAddress = true;
      _error = null;
    });
    try {
      final resolved = await ref
          .read(placesServiceProvider)
          .reverseGeocode(point, cancelToken: cancel);
      if (_current(revision)) {
        setState(
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
        setState(
          () => _error = 'Chưa tra được tên đường. Vị trí GPS của ghim vẫn được giữ chính xác.',
        );
      }
    } finally {
      if (_current(revision)) setState(() => _resolvingAddress = false);
    }
  }

  Future<void> _recenter() async {
    if (_locating) return;
    _geocodeCancel?.cancel();
    final revision = ++_revision;
    setState(() {
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
        setState(
          () => _error = error is LocationLookupException
              ? error.message
              : 'Chưa lấy được GPS. Hãy thử lại hoặc tìm địa điểm.',
        );
      }
    } finally {
      if (_current(revision)) setState(() => _locating = false);
    }
  }

  Future<void> _searchLocation() async {
    if (_searchOpen || _locating || _confirming) return;
    _revision++;
    _geocodeCancel?.cancel();
    setState(() {
      _searchOpen = true;
      _resolvingAddress = false;
    });
    final selected = await context.push<RescueLocation>(
      '/incident-location?pick=1',
      extra: _location,
    );
    if (!mounted) return;
    setState(() => _searchOpen = false);
    if (selected != null) {
      if (selected.hasCoordinates) {
        _applyLocation(selected);
        setState(
          () => _location = RescueLocation(
            address: _location.address,
            landmark: selected.landmark,
            latitude: _location.latitude,
            longitude: _location.longitude,
          ),
        );
      } else {
        setState(
          () => _error = 'Địa chỉ chưa có tọa độ. Hãy chọn kết quả tìm kiếm hoặc dùng GPS.',
        );
      }
    }
  }

  Future<void> _confirmLocation() async {
    if (_confirming ||
        _moving ||
        _locating ||
        _resolvingAddress ||
        _cameraError) {
      return;
    }
    final confirmed = ref
        .read(rescueLocationProvider.notifier)
        .confirmLocation(_location);
    if (!confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vị trí chưa hợp lệ. Hãy quay lại kiểm tra địa chỉ.'),
        ),
      );
      return;
    }
    ref.read(incidentHistoryProvider.notifier).remember(_location);
    setState(() => _confirming = true);
    final order = await showHomeSheet<RescueOrder>(
      context,
      const CreateRescueRequestBottomSheet(
        serviceType: 'Kiểm tra & Cứu hộ tận nơi',
        allowServiceSelection: true,
      ),
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (order != null) {
      if (context.canPop()) {
        context.pop(order);
      } else {
        context.go('/hoat-dong');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: HomeTheme.light,
    child: Scaffold(
      backgroundColor: HomeColors.background,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final initialSize =
              ((348 + (scale - 1) * 180) / constraints.maxHeight).clamp(
                .42,
                .68,
              );
          double sheetSize() =>
              _sheetController.isAttached ? _sheetController.size : initialSize;
          return Stack(
            children: [
              AnimatedBuilder(
                animation: _sheetController,
                builder: (context, child) {
                  final visibleHeight =
                      constraints.maxHeight * (1 - sheetSize());
                  return Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: visibleHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ref.watch(incidentMapBuilderProvider)(
                            context,
                            IncidentMapRequest(
                              target: _cameraTarget,
                              onCreated: _onMapCreated,
                              onMoveStarted: _onMoveStarted,
                              onMove: _onCameraMove,
                              onIdle: _onCameraIdle,
                            ),
                          ),
                        ),
                        if (_location.hasCoordinates &&
                            _mapController != null &&
                            !_cameraError)
                          Positioned(
                            left: (constraints.maxWidth - 72) / 2,
                            top: visibleHeight / 2 - 92,
                            child: const IgnorePointer(child: IncidentSosPin()),
                          ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 12,
                left: 16,
                child: Material(
                  color: HomeColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  elevation: 2,
                  shadowColor: const Color(0x15000000),
                  child: IconButton(
                    tooltip: 'Quay lại',
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/incident-location', extra: _location),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 12,
                right: 16,
                child: Material(
                  color: HomeColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: IconButton(
                    key: const ValueKey('incident-map-search'),
                    tooltip: 'Tìm địa điểm',
                    onPressed: _searchOpen || _locating || _confirming
                        ? null
                        : _searchLocation,
                    icon: const Icon(Icons.search, color: HomeColors.text),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _sheetController,
                builder: (context, child) => Positioned(
                  right: 16,
                  bottom: (constraints.maxHeight * sheetSize() + 16).clamp(
                    16,
                    constraints.maxHeight - 64,
                  ),
                  child: child!,
                ),
                child: Material(
                  color: HomeColors.surface,
                  shape: const CircleBorder(),
                  elevation: 3,
                  shadowColor: const Color(0x20000000),
                  child: IconButton(
                    key: const ValueKey('incident-map-gps'),
                    tooltip: 'Sử dụng vị trí hiện tại của tôi',
                    onPressed: _locating || _confirming ? null : _recenter,
                    icon: const Icon(
                      Icons.my_location_rounded,
                      color: HomeColors.text,
                    ),
                  ),
                ),
              ),
              DraggableScrollableSheet(
                key: const ValueKey('incident-map-sheet'),
                controller: _sheetController,
                initialChildSize: initialSize,
                minChildSize: .30,
                maxChildSize: .94,
                builder: (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: HomeColors.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 18,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDEE2E6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Xác nhận vị trí gặp sự cố',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Di chuyển bản đồ để ghim đúng vị trí xe đang hỏng',
                        style: TextStyle(
                          fontSize: 14,
                          color: HomeColors.secondary,
                          height: 1.5,
                        ),
                      ),
                      if (_resolvingAddress || _locating)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: HomeColors.red),
                          ),
                        ),
                      const Divider(height: 28),
                      Container(
                        key: const ValueKey('incident-selected-address'),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: HomeColors.selected,
                          border: Border.all(color: HomeColors.accentBorder),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: HomeColors.red,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _location.address.isEmpty
                                        ? 'Hãy tìm địa điểm hoặc chọn một điểm trên bản đồ.'
                                        : _location.address,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      height: 1.5,
                                    ),
                                  ),
                                  if (_location.landmark.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      _location.landmark,
                                      style: const TextStyle(
                                        color: HomeColors.secondary,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        key: const ValueKey('incident-confirm-location'),
                        onPressed:
                            _confirming ||
                                _cameraError ||
                                _moving ||
                                _locating ||
                                _resolvingAddress ||
                                _location.address.trim().length < 5 ||
                                (ref
                                        .watch(locationApiConfigProvider)
                                        .mapConfigured &&
                                    !_location.hasCoordinates)
                            ? null
                            : _confirmLocation,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                        ),
                        child: const Text(
                          'XÁC NHẬN VỊ TRÍ SỰ CỐ',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: HomeBottomNavigation(
        selectedDestination: HomeDestination.home,
        onSelected: (destination) => navigateMainTab(context, destination),
      ),
    ),
  );
}
