import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../partner/providers/partner_provider.dart';
import '../data/home_station_details.dart';
import '../models/home_discovery.dart';
import '../models/home_rescue_quick_action.dart';
import '../services/home_discovery_service.dart';
import 'home_provider.dart';

final homeStationDetailsProvider = Provider<Map<String, HomeStationDetails>>(
  (ref) => homeStationDetails,
);

final homeDiscoveryProvider =
    NotifierProvider.autoDispose<HomeDiscoveryController, HomeDiscoveryState>(
      HomeDiscoveryController.new,
    );

class HomeDiscoveryController extends Notifier<HomeDiscoveryState> {
  @override
  HomeDiscoveryState build() => const HomeDiscoveryState();

  void search(String query) => state = HomeDiscoveryState(
    query: query,
    category: state.category,
    filters: state.filters,
  );

  void selectCategory(HomeStationCategory category) =>
      state = HomeDiscoveryState(
        query: state.query,
        category: category,
        filters: state.filters,
        quickAction: state.quickAction,
      );

  void selectQuickAction(HomeRescueQuickAction action) =>
      state = HomeDiscoveryState(
        query: action.searchQuery,
        quickAction: action,
        filters: state.filters,
      );

  void applyFilters(HomeDiscoveryFilters filters) => state = HomeDiscoveryState(
    query: state.query,
    category: state.category,
    filters: filters,
    quickAction: state.quickAction,
  );

  void reset() => state = const HomeDiscoveryState();
}

final homeDiscoveryStationsProvider =
    Provider.autoDispose<List<HomeStationListing>>((ref) {
      final location = ref.watch(rescueLocationProvider);
      final details = ref.watch(homeStationDetailsProvider);
      final listings = [
        for (final shop in ref.watch(partnerShopsProvider))
          HomeStationListing(
            station: shop.station,
            services: shop.services,
            details: details[shop.id] ?? defaultHomeStationDetails,
            distanceKm: stationDistanceKm(shop.station, location),
          ),
      ];
      return const HomeDiscoveryService().filter(
        listings,
        ref.watch(homeDiscoveryProvider),
      );
    });
