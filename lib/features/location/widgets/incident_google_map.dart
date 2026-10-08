import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_api_config.dart';
import '../services/incident_camera_controller.dart';
export '../services/incident_camera_controller.dart';

class GoogleIncidentCameraController implements IncidentCameraController {
  GoogleIncidentCameraController(this.mapController);
  final GoogleMapController mapController;
  @override
  Future<void> animateTo(LatLng target, {double zoom = 17}) =>
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom),
        ),
      );
}

class IncidentMapRequest {
  const IncidentMapRequest({
    required this.target,
    required this.onCreated,
    required this.onMoveStarted,
    required this.onMove,
    required this.onIdle,
  });
  final LatLng target;
  final ValueChanged<IncidentCameraController> onCreated;
  final VoidCallback onMoveStarted, onIdle;
  final ValueChanged<LatLng> onMove;
}

typedef IncidentMapBuilder = Widget Function(
  BuildContext context,
  IncidentMapRequest request,
);

/// A replaceable boundary for native maps; tests supply a controllable camera.
final incidentMapBuilderProvider = Provider<IncidentMapBuilder>((ref) {
  final configured = ref.watch(locationApiConfigProvider).mapConfigured;
  return (context, request) => configured
      ? GoogleMap(
          key: const ValueKey('incident-map-canvas'),
          initialCameraPosition: CameraPosition(
            target: request.target,
            zoom: 17,
          ),
          onMapCreated: (controller) =>
              request.onCreated(GoogleIncidentCameraController(controller)),
          onCameraMoveStarted: request.onMoveStarted,
          onCameraMove: (position) => request.onMove(position.target),
          onCameraIdle: request.onIdle,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
        )
      : const ColoredBox(
          color: Color(0xFFF8F9FA),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'Bản đồ chưa sẵn sàng. Bạn có thể tìm kiếm địa điểm hoặc dùng GPS.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
});
