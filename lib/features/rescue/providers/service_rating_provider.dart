import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/providers/activity_provider.dart';
import '../models/service_rating.dart';
import '../services/service_rating_service.dart';

final serviceRatingSummaryProvider = Provider.autoDispose
    .family<ServiceRatingSummary?, String?>((ref, id) {
      final order = ref.watch(
        activityProvider.select((state) => state.orderById(id)),
      );
      return order == null
          ? null
          : ref.read(serviceRatingServiceProvider).summary(order);
    });

final serviceRatingsProvider =
    NotifierProvider<ServiceRatingsController, Map<String, ServiceRating>>(
      ServiceRatingsController.new,
    );

class ServiceRatingsController extends Notifier<Map<String, ServiceRating>> {
  final _pending = <String>{};
  @override
  Map<String, ServiceRating> build() => const {};

  Future<void> submit(
    String orderId, {
    required int stars,
    required Set<String> tagIds,
    required String comment,
    Uint8List? photo,
  }) async {
    if (!_pending.add(orderId)) throw StateError('Đánh giá đang được gửi.');
    try {
      final review = ref
          .read(serviceRatingServiceProvider)
          .create(
            ref.read(activityProvider).orderById(orderId),
            stars: stars,
            tagIds: tagIds,
            comment: comment,
            photo: photo,
          );
      await ref.read(serviceRatingSubmitterProvider)(review);
      if (!ref.mounted) return;
      if (!ref
          .read(activityProvider.notifier)
          .rateOrder(orderId, review.stars)) {
        throw StateError('Đơn hàng không còn khả dụng để đánh giá.');
      }
      state = Map.unmodifiable({...state, orderId: review});
    } finally {
      _pending.remove(orderId);
    }
  }
}
