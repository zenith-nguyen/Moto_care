import '../../activity/models/rescue_order.dart';
import '../../partner/models/partner_shop.dart';

class MarketplaceBooking {
  MarketplaceBooking({
    required this.partnerId,
    required this.serviceType,
    required List<RescueOrderItem> items,
  }) : items = List.unmodifiable(items);
  final String partnerId;
  final String serviceType;
  final List<RescueOrderItem> items;
  int get quantity => items.fold(0, (sum, item) => sum + item.quantity);
  int get subtotal => items.fold(0, (sum, item) => sum + item.total);

  bool isValidFor(PartnerShop partner) {
    if (!partner.station.isOpen || items.isEmpty || partner.id != partnerId) {
      return false;
    }
    final menu = partner.menu(serviceType);
    final ids = <String>{};
    for (final item in items) {
      if (!ids.add(item.packageId)) return false;
      final matches = menu.where((package) => package.id == item.packageId);
      if (matches.length != 1) return false;
      final package = matches.single;
      if (package.price != item.unitPrice ||
          package.name != item.name ||
          package.serviceType != item.serviceType) {
        return false;
      }
    }
    return true;
  }

  static int travelFee(double distanceKm) => 10000 + distanceKm.ceil() * 5000;
}
