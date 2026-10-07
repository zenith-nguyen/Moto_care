import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/models/rescue_location.dart';
import '../data/mock_incident_places.dart';

/// Replace with a device location result when GPS and geocoding are connected.
/// Demo addresses deliberately have no fabricated GPS coordinates.
final incidentCurrentLocationProvider = Provider<RescueLocation>(
  (ref) => mockCurrentIncidentLocation,
);

final recentIncidentPlacesProvider = Provider<List<IncidentPlace>>(
  (ref) => mockRecentIncidentPlaces,
);
