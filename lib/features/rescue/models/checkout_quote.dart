import '../../partner/models/partner_shop.dart';

class CheckoutQuote {
  const CheckoutQuote({
    this.shop,
    this.distance = 0,
    this.travelFee = 0,
    this.total = 0,
    this.validBooking = false,
    this.canOrder = false,
  });
  final PartnerShop? shop;
  final double distance;
  final int travelFee, total;
  final bool validBooking, canOrder;
}
