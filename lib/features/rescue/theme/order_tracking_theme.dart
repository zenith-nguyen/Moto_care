import 'package:flutter/material.dart';

import '../../customer/presentation/theme/customer_order_theme.dart';
export '../../customer/presentation/theme/customer_order_theme.dart';

abstract final class OrderTrackingTheme {
  static final light = CustomerOrderTheme.light;
}

abstract final class OrderTrackingColors {
  static const route = Color(0xFF14B8A6);
  static const routeHalo = Color(0x2614B8A6);
  static const statusBlue = Color(0xFF1E40AF);
  static const avatarTint = Color(0xFFFFEDD5);
  static const border = CustomerOrderTheme.line;
  static const muted = CustomerOrderTheme.muted;
}
