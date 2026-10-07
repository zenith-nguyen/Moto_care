import 'package:flutter/material.dart';
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
import '../data/mock_incident_places.dart';
import '../providers/incident_location_provider.dart';
import '../widgets/incident_mock_map.dart';

class IncidentMapPickerScreen extends ConsumerStatefulWidget {
  const IncidentMapPickerScreen({super.key, this.initialLocation});
  final RescueLocation? initialLocation;

  @override
  ConsumerState<IncidentMapPickerScreen> createState() =>
      _IncidentMapPickerScreenState();
}

class _IncidentMapPickerScreenState
    extends ConsumerState<IncidentMapPickerScreen> {
  final _sheetController = DraggableScrollableController();
  late final RescueLocation _initialLocation =
      widget.initialLocation ??
      ref.read(rescueLocationProvider) ??
      ref.read(incidentCurrentLocationProvider);
  late RescueLocation _location = _initialLocation;
  late RescueLocation _mapOriginLocation = _initialLocation;
  Offset _mapOffset = Offset.zero;
  bool _confirming = false;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _pan(Offset delta) => setState(() {
    _mapOffset = Offset(
      (_mapOffset.dx + delta.dx).clamp(-360, 360),
      (_mapOffset.dy + delta.dy).clamp(-360, 360),
    );
  });

  void _selectPinLocation() {
    // Select the closest sample landmark under the fixed pin, without geocoding.
    const anchors = [Offset.zero, Offset(-130, -100), Offset(130, 100)];
    var selected = 0;
    for (var i = 1; i < anchors.length; i++) {
      if ((anchors[i] + _mapOffset).distanceSquared <
          (anchors[selected] + _mapOffset).distanceSquared) {
        selected = i;
      }
    }
    final point = selected == 0
        ? _mapOriginLocation
        : mockNearbyIncidentLocations[selected];
    setState(
      () => _location = RescueLocation(
        address: point.address,
        landmark: _initialLocation.landmark,
        latitude: point.latitude,
        longitude: point.longitude,
      ),
    );
  }

  void _recenter() {
    final current = ref.read(incidentCurrentLocationProvider);
    setState(() {
      _mapOffset = Offset.zero;
      _mapOriginLocation = current;
      _location = RescueLocation(
        address: current.address,
        landmark: _initialLocation.landmark,
        latitude: current.latitude,
        longitude: current.longitude,
      );
    });
  }

  Future<void> _confirmLocation() async {
    if (_confirming) return;
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
    setState(() => _confirming = true);
    final order = await showHomeSheet<RescueOrder>(
      context,
      const CreateRescueRequestBottomSheet(),
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
      backgroundColor: const Color(0xFFE9ECEF),
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
              Positioned.fill(
                child: IncidentMockMap(
                  offset: _mapOffset,
                  onPanUpdate: _pan,
                  onPanEnd: _selectPinLocation,
                ),
              ),
              AnimatedBuilder(
                animation: _sheetController,
                builder: (context, child) => Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: constraints.maxHeight * sheetSize(),
                  child: IgnorePointer(
                    child: Center(
                      child: FittedBox(fit: BoxFit.scaleDown, child: child),
                    ),
                  ),
                ),
                child: const IncidentSosPin(),
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
                top: MediaQuery.paddingOf(context).top + 20,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: HomeColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Bản đồ minh họa',
                    style: TextStyle(fontSize: 12, color: HomeColors.secondary),
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
                    onPressed: _recenter,
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
                      const Divider(height: 28),
                      Container(
                        key: const ValueKey('incident-selected-address'),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: HomeColors.selected,
                          border: Border.all(color: const Color(0xFFFFDCCF)),
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
                                    _location.address,
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
                        onPressed: _confirming ? null : _confirmLocation,
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
