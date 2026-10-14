import 'package:flutter/material.dart';

import '../models/marketplace_booking.dart';
import 'order_summary_screen.dart';

// Retain the existing route and constructor for marketplace callers.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key, this.booking});
  final MarketplaceBooking? booking;

  @override
  Widget build(BuildContext context) => OrderSummaryScreen(booking: booking);
}
