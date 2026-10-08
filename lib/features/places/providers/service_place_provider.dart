import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/search_service.dart';
import '../models/service_place.dart';
import '../data/demo_service_places.dart';

final servicePlacesProvider = Provider<List<ServicePlace>>(
  (ref) => demoServicePlaces,
);
final filteredServicePlacesProvider = Provider.autoDispose
    .family<List<ServicePlace>, (String, Set<String>)>((ref, selection) {
      final places =
          ref
              .watch(servicePlacesProvider)
              .where(
                (place) =>
                    normalizeServiceSearch('${place.name} ${place.address}')
                        .contains(normalizeServiceSearch(selection.$1)) &&
                    (!selection.$2.contains('Trạm sạc') || place.isCharging) &&
                    (!selection.$2.contains('Mở 24/7') || place.is24Hours) &&
                    (!selection.$2.contains('Sửa xe xăng') ||
                        place.repairsPetrol),
              )
              .toList()
            ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return List.unmodifiable(places);
    });
