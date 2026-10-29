import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/providers/profile_provider.dart';
import '../models/order_details.dart';
import '../services/order_details_service.dart';
import 'activity_provider.dart';

final orderDetailsServiceProvider = Provider<OrderDetailsService>(
  (ref) => const OrderDetailsService(),
);

final orderDetailsProvider = Provider.autoDispose
    .family<OrderDetails?, String?>((ref, id) {
      final order = ref.watch(activityProvider).orderById(id);
      if (order == null) return null;
      return ref
          .watch(orderDetailsServiceProvider)
          .resolve(order, ref.watch(profileProvider).profile);
    });
