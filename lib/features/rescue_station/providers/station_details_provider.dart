import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/providers/activity_provider.dart';
import '../../home/data/home_station_details.dart';
import '../../home/providers/home_discovery_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../partner/providers/partner_provider.dart';
import '../../rescue/providers/service_rating_provider.dart';
import '../data/station_profiles.dart';
import '../models/station_model.dart';
import '../services/station_details_service.dart';

final stationProfilesProvider = Provider<Map<String, StationProfile>>(
  (ref) => stationProfiles,
);

final stationDetailsServiceProvider = Provider<StationDetailsService>(
  (ref) => const StationDetailsService(),
);

final stationModelProvider = Provider.autoDispose.family<StationModel?, String>(
  (ref, id) {
    final shops = ref
        .watch(partnerShopsProvider)
        .where((shop) => shop.id == id);
    if (shops.isEmpty) return null;
    final shop = shops.first;
    return ref
        .watch(stationDetailsServiceProvider)
        .build(
          shop: shop,
          details:
              ref.watch(homeStationDetailsProvider)[id] ??
              defaultHomeStationDetails,
          profile:
              ref.watch(stationProfilesProvider)[id] ?? defaultStationProfile,
          distanceKm: stationDistanceKm(
            shop.station,
            ref.watch(rescueLocationProvider),
          ),
        );
  },
);

final stationFavoritesProvider =
    NotifierProvider<StationFavoritesController, Set<String>>(
      StationFavoritesController.new,
    );

class StationFavoritesController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) {
    final next = {...state};
    if (!next.remove(id)) next.add(id);
    state = Set.unmodifiable(next);
  }
}

/// Confirmed reviews use the order's partner ID, never its display name.
final stationReviewsProvider = Provider.autoDispose
    .family<List<StationReview>, String>((ref, id) {
      final activity = ref.watch(activityProvider);
      final reviews = [
        for (final review in ref.watch(serviceRatingsProvider).values)
          if (activity.orderById(review.orderId)?.partnerId == id)
            StationReview(
              id: review.orderId,
              author: 'Bạn',
              stars: review.stars,
              comment: review.comment,
              createdAt: review.createdAt,
            ),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List.unmodifiable(reviews);
    });
