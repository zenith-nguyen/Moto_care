import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/models/rescue_location.dart';
import '../../location/services/location_service.dart';
import '../../partner/models/partner_shop.dart';
import '../models/checkout_quote.dart';
import '../models/marketplace_booking.dart';

export '../models/checkout_quote.dart';

final checkoutServiceProvider = Provider<CheckoutService>(
  (ref) => const CheckoutService(),
);

class CheckoutService {
  const CheckoutService({this.locationService = const LocationService()});
  final LocationService locationService;
  CheckoutQuote quote({
    required MarketplaceBooking? booking,
    required List<PartnerShop> shops,
    required RescueLocation? location,
    required String note,
    required bool hasVehicle,
    required bool hasActiveOrder,
    required bool submitting,
  }) {
    final matches = shops.where((shop) => shop.id == booking?.partnerId);
    final shop = matches.isEmpty ? null : matches.first;
    if (shop == null || booking == null) return const CheckoutQuote();
    final distance = locationService.stationDistanceKm(shop.station, location);
    final travelFee = MarketplaceBooking.travelFee(distance);
    final address = location?.address.trim() ?? '';
    final validBooking = booking.isValidFor(shop);
    return CheckoutQuote(
      shop: shop,
      distance: distance,
      travelFee: travelFee,
      total: booking.subtotal + travelFee,
      validBooking: validBooking,
      canOrder:
          !submitting &&
          validBooking &&
          hasVehicle &&
          address.length >= 5 &&
          address.length <= 240 &&
          note.length <= 500 &&
          !hasActiveOrder,
    );
  }
}
