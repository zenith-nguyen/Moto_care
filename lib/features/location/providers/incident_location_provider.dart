import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/models/rescue_location.dart';
import '../../home/providers/home_provider.dart';
import '../models/incident_place.dart';
export '../models/incident_place.dart';

/// Seed an address draft without inventing device coordinates.
final incidentCurrentLocationProvider = Provider<RescueLocation>(
  (ref) =>
      ref.watch(rescueLocationProvider) ?? const RescueLocation(address: ''),
);
final initialIncidentHistoryProvider = Provider<List<IncidentPlace>>(
  (ref) => [],
);
final incidentHistoryProvider =
    NotifierProvider<IncidentHistoryController, List<IncidentPlace>>(
      IncidentHistoryController.new,
    );
final recentIncidentPlacesProvider = Provider<List<IncidentPlace>>(
  (ref) => ref.watch(incidentHistoryProvider),
);

class IncidentHistoryController extends Notifier<List<IncidentPlace>> {
  @override
  List<IncidentPlace> build() =>
      List.unmodifiable(ref.read(initialIncidentHistoryProvider));
  void remember(RescueLocation location) {
    state = List.unmodifiable(
      [
        (name: location.address, location: location),
        ...state.where((place) => place.location.address != location.address),
      ].take(6),
    );
  }
}
