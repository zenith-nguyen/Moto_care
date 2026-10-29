import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/providers/home_provider.dart';
import 'partner_provider.dart';

typedef PartnerListing = ({
  PartnerShop shop,
  double distance,
  int price,
  int minutes,
});
final partnerSearchProvider = Provider.autoDispose
    .family<List<PartnerListing>, (String, String, PartnerVehicleType?)>((
      ref,
      query,
    ) {
      final location = ref.watch(rescueLocationProvider);
      final shops = ref
          .watch(partnerShopsProvider)
          .where(
            (shop) =>
                shop.station.isOpen &&
                shop.menu(query.$1).isNotEmpty &&
                (query.$3 == null || shop.vehicleTypes.contains(query.$3)) &&
                '${shop.station.name} ${shop.station.address}'
                    .toLowerCase()
                    .contains(query.$2.trim().toLowerCase()),
          );
      final listings = [
        for (final shop in shops)
          (
            shop: shop,
            distance: stationDistanceKm(shop.station, location),
            price: shop
                .menu(query.$1)
                .map((item) => item.price)
                .reduce((a, b) => a < b ? a : b),
            minutes: (stationDistanceKm(shop.station, location) * 5).ceil() + 5,
          ),
      ]..sort((a, b) => a.distance.compareTo(b.distance));
      return List.unmodifiable(listings);
    });
