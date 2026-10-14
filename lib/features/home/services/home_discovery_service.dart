import '../../../core/services/search_service.dart';
import '../../activity/models/rescue_order.dart';
import '../models/home_discovery.dart';

class HomeDiscoveryService {
  const HomeDiscoveryService();

  List<HomeStationListing> filter(
    List<HomeStationListing> listings,
    HomeDiscoveryState state,
  ) {
    final query = normalizeServiceSearch(state.query);
    final filters = state.filters;
    final result = listings.where((listing) {
      final station = listing.station;
      final quickService = state.quickAction.serviceType;
      if (quickService != null && !listing.services.contains(quickService)) {
        return false;
      }
      final searchable = normalizeServiceSearch(
        '${station.name} ${station.address} ${listing.details.area ?? ''} '
        '${listing.services.map(_serviceSearchLabel).join(' ')}',
      );
      if (!searchable.contains(query) ||
          (filters.open24h && !station.isOpen24h) ||
          (filters.verified && !station.isVerified) ||
          (filters.maxDistanceKm != null &&
              listing.distanceKm > filters.maxDistanceKm!)) {
        return false;
      }
      return switch (state.category) {
        HomeStationCategory.towing => listing.services.contains(
          RescueServiceType.towing,
        ),
        HomeStationCategory.tire24h =>
          station.isOpen24h &&
              listing.services.contains(RescueServiceType.flatTire),
        _ => true,
      };
    }).toList();
    result.sort((a, b) {
      // Unavailable stations never appear ahead of available assistance.
      final availability = (a.station.isOpen ? 0 : 1).compareTo(
        b.station.isOpen ? 0 : 1,
      );
      if (availability != 0) return availability;
      final comparison = switch (state.category) {
        HomeStationCategory.topRated => b.station.rating.compareTo(
          a.station.rating,
        ),
        HomeStationCategory.fastest =>
          (a.details.responseMinutes ?? 999).compareTo(
            b.details.responseMinutes ?? 999,
          ),
        _ => a.distanceKm.compareTo(b.distanceKm),
      };
      if (comparison != 0) return comparison;
      final distance = a.distanceKm.compareTo(b.distanceKm);
      return distance != 0 ? distance : a.station.id.compareTo(b.station.id);
    });
    return List.unmodifiable(result);
  }

  String _serviceSearchLabel(RescueServiceType service) => switch (service) {
    RescueServiceType.flatTire => 'Vá xe Vá lốp Thủng lốp ${service.label}',
    RescueServiceType.batteryJump => 'Hết bình ${service.label}',
    RescueServiceType.towing => 'Xe kéo ${service.label}',
    _ => service.label,
  };
}
