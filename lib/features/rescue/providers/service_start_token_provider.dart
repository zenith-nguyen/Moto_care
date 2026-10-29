import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/realtime/realtime_event.dart';
import '../../orders/domain/order_action_results.dart';

/// Service start code the customer shows the mechanic once they arrive.
///
/// Returns the live token from `GET /orders/:id/start-token`. While the
/// provider has not arrived yet the backend answers 409 (conflict); we surface
/// that as `null` (nothing to show) rather than an error. The provider refreshes
/// itself when the order's realtime status changes (e.g. accepted -> arrived
/// makes the code available) and shortly after the 5-minute token expires, so
/// the code on screen is always valid.
final serviceStartTokenProvider = FutureProvider.autoDispose
    .family<ServiceStartToken?, int>((ref, orderId) async {
      if (!ref.watch(runtimeApiIntegrationProvider)) return null;

      final subscription = ref
          .read(realtimeClientProvider)
          .events
          .where(
            (event) => event.orderId == orderId && event is OrderStatusChanged,
          )
          .listen((_) => ref.invalidateSelf());
      ref.onDispose(subscription.cancel);

      try {
        final token = await ref
            .read(ordersRepositoryProvider)
            .getStartToken(orderId);
        final remaining = token.expiresAt.difference(DateTime.now());
        if (remaining > Duration.zero) {
          final timer = Timer(
            remaining + const Duration(seconds: 1),
            ref.invalidateSelf,
          );
          ref.onDispose(timer.cancel);
        }
        return token;
      } on ApiFailure catch (failure) {
        // Provider has not arrived yet (409) or the order is no longer
        // addressable (404): there is simply no code to display.
        if (failure.kind == ApiFailureKind.conflict ||
            failure.kind == ApiFailureKind.notFound) {
          return null;
        }
        rethrow;
      }
    });
