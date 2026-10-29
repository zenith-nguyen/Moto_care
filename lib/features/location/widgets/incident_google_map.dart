import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as osm_map;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:url_launcher/url_launcher.dart';

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

class OsmIncidentCameraController implements IncidentCameraController {
  OsmIncidentCameraController(this.mapController);

  final osm_map.MapController mapController;

  @override
  Future<void> animateTo(LatLng target, {double zoom = 17}) async {
    mapController.move(osm.LatLng(target.latitude, target.longitude), zoom);
  }
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
      : OsmIncidentMap(request: request);
});

class OsmIncidentMap extends StatefulWidget {
  const OsmIncidentMap({super.key, required this.request});

  final IncidentMapRequest request;

  @override
  State<OsmIncidentMap> createState() => _OsmIncidentMapState();
}

class _OsmIncidentMapState extends State<OsmIncidentMap> {
  final _controller = osm_map.MapController();
  bool _gestureMoving = false;

  @override
  Widget build(BuildContext context) => osm_map.FlutterMap(
    key: const ValueKey('incident-map-canvas-osm'),
    mapController: _controller,
    options: osm_map.MapOptions(
      initialCenter: osm.LatLng(
        widget.request.target.latitude,
        widget.request.target.longitude,
      ),
      initialZoom: 17,
      minZoom: 5,
      maxZoom: 19,
      onMapReady: () =>
          widget.request.onCreated(OsmIncidentCameraController(_controller)),
      onPositionChanged: (camera, hasGesture) {
        if (hasGesture && !_gestureMoving) {
          _gestureMoving = true;
          widget.request.onMoveStarted();
        }
        widget.request.onMove(
          LatLng(camera.center.latitude, camera.center.longitude),
        );
      },
      onMapEvent: (event) {
        if (event is osm_map.MapEventMoveEnd) {
          _gestureMoving = false;
          widget.request.onIdle();
        }
      },
    ),
    children: [
      osm_map.TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.motocare.app',
        maxNativeZoom: 19,
      ),
      osm_map.RichAttributionWidget(
        showFlutterMapAttribution: false,
        attributions: [
          osm_map.TextSourceAttribution(
            'OpenStreetMap contributors',
            onTap: () => launchUrl(
              Uri.parse('https://www.openstreetmap.org/copyright'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    ],
  );
}
