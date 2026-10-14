import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract interface class IncidentCameraController {
  Future<void> animateTo(LatLng target, {double zoom = 17});
}
