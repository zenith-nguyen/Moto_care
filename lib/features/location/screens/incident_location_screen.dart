import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/main_navigation.dart';
import '../../activity/models/rescue_order.dart';
import '../../home/models/home_destination.dart';
import '../../home/models/rescue_location.dart';
import '../../home/theme/home_theme.dart';
import '../../home/widgets/home_bottom_navigation.dart';
import '../../home/widgets/home_sheets.dart';
import '../../rescue/widgets/create_rescue_request_bottom_sheet.dart';
import '../providers/incident_map_provider.dart';
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
  final _draftKey = Object();
  (Object, RescueLocation?) get _key => (_draftKey, widget.initialLocation);
  IncidentMapController get _controller =>
      ref.read(incidentMapProvider(_key).notifier);
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.initialize());
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation() async {
    if (_confirming || !_controller.beginSearch()) return;
    final selected = await context.push<RescueLocation>(
      '/incident-location?pick=1',
      extra: ref.read(incidentMapProvider(_key)).location,
    );
    if (mounted) _controller.endSearch(selected);
  }

  Future<void> _confirmLocation() async {
    if (_confirming) return;
    final confirmed = _controller.confirm();
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
  Widget build(BuildContext context) {
    final draft = ref.watch(incidentMapProvider(_key));
    return Theme(
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
            double sheetSize() => _sheetController.isAttached
                ? _sheetController.size
                : initialSize;
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
                                target: draft.cameraTarget,
                                onCreated: _controller.onMapCreated,
                                onMoveStarted: _controller.onMoveStarted,
                                onMove: _controller.onCameraMove,
                                onIdle: _controller.onCameraIdle,
                              ),
                            ),
                          ),
                          if (draft.location.hasCoordinates &&
                              draft.cameraReady &&
                              !draft.cameraError)
                            Positioned(
                              left: (constraints.maxWidth - 72) / 2,
                              top: visibleHeight / 2 - 92,
                              child: const IgnorePointer(
                                child: IncidentSosPin(),
                              ),
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
                          : context.go(
                              '/incident-location',
                              extra: draft.location,
                            ),
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
                      onPressed:
                          draft.searchOpen || draft.locating || _confirming
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
                      onPressed: draft.locating || _confirming
                          ? null
                          : _controller.recenter,
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
                        if (draft.resolvingAddress || draft.locating)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: LinearProgressIndicator(),
                          ),
                        if (draft.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              draft.error!,
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
                                      draft.location.address.isEmpty
                                          ? 'Hãy tìm địa điểm hoặc chọn một điểm trên bản đồ.'
                                          : draft.location.address,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        height: 1.5,
                                      ),
                                    ),
                                    if (draft.location.landmark.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        draft.location.landmark,
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
                          onPressed: _confirming || !_controller.canConfirm
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
}
