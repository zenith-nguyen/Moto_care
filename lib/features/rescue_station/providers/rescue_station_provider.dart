import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/search_service.dart';
import '../data/mock_rescue_stations.dart';
import '../models/rescue_station.dart';

final rescueStationsProvider = Provider<List<RescueStation>>(
  (ref) => mockRescueStations,
);

enum StationFilter {
  open24h('Mở 24/7'),
  verified('Đã xác thực'),
  official('Chính hãng'),
  nearest('Gần nhất');

  const StationFilter(this.label);
  final String label;
}

List<RescueStation> filterRescueStations(
  List<RescueStation> stations, {
  String query = '',
  Set<StationFilter> filters = const {},
}) {
  final normalized = normalizeServiceSearch(query);
  final result = stations
      .where(
        (station) =>
            normalizeServiceSearch('${station.name} ${station.address}')
                .contains(normalized) &&
            (!filters.contains(StationFilter.open24h) || station.isOpen24h) &&
            (!filters.contains(StationFilter.verified) || station.isVerified) &&
            (!filters.contains(StationFilter.official) ||
                station.stationType == StationType.officialDealer),
      )
      .toList();
  result.sort((a, b) {
    final comparison = filters.contains(StationFilter.nearest)
        ? a.distanceKm.compareTo(b.distanceKm)
        : b.rating.compareTo(a.rating);
    return comparison != 0 ? comparison : a.id.compareTo(b.id);
  });
  return List.unmodifiable(result);
}
