import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rescue/models/marketplace_booking.dart';
import 'partner_provider.dart';

typedef PartnerCartKey = (Object, String, String);
final partnerCartProvider = NotifierProvider.autoDispose
    .family<PartnerCartController, Map<String, int>, PartnerCartKey>(
      PartnerCartController.new,
    );

class PartnerCartController extends Notifier<Map<String, int>> {
  PartnerCartController(this.key);
  final PartnerCartKey key;
  @override
  Map<String, int> build() => const {};
  void setQuantity(String packageId, int value) {
    if (value >= 0 && value <= 9) {
      state = Map.unmodifiable({...state, packageId: value});
    }
  }
}

final partnerBookingProvider = Provider.autoDispose
    .family<MarketplaceBooking, PartnerCartKey>((ref, key) {
      final quantities = ref.watch(partnerCartProvider(key));
      final shops = ref
          .watch(partnerShopsProvider)
          .where((shop) => shop.id == key.$2);
      final menu = shops.isEmpty ? const [] : shops.first.menu(key.$3);
      return MarketplaceBooking(
        partnerId: key.$2,
        serviceType: key.$3,
        items: [
          for (final package in menu)
            if ((quantities[package.id] ?? 0) > 0)
              package.item(quantities[package.id]!),
        ],
      );
    });
final partnerShopProvider = Provider.family<PartnerShop?, String>((ref, id) {
  final shops = ref.watch(partnerShopsProvider).where((shop) => shop.id == id);
  return shops.isEmpty ? null : shops.first;
});
