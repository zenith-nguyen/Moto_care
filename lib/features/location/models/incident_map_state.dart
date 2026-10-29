import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../home/models/rescue_location.dart';

class IncidentMapState {
  const IncidentMapState({
    required this.location,
    required this.cameraTarget,
    this.cameraReady = false,
    this.resolvingAddress = false,
    this.locating = false,
    this.moving = false,
    this.cameraError = false,
    this.searchOpen = false,
    this.error,
  });
  final RescueLocation location;
  final LatLng cameraTarget;
  final bool cameraReady,
      resolvingAddress,
      locating,
      moving,
      cameraError,
      searchOpen;
  final String? error;
  bool get busy => moving || locating || resolvingAddress || cameraError;
}
