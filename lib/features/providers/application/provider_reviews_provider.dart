import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/network/json_reader.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/application/session_state.dart';
import '../../reviews/domain/order_review.dart';

/// Real customer reviews about the signed-in provider, from
/// GET /providers/me/reviews (newest first, with count + average).
final providerReviewsProvider =
    FutureProvider.autoDispose<ProviderReviewsSummary>((ref) async {
      if (ref.watch(sessionControllerProvider) is! SessionSignedIn) {
        throw StateError('Chưa đăng nhập tài khoản Thợ.');
      }
      final response = await ref
          .read(jsonApiProvider)
          .getObject('/providers/me/reviews');
      return ProviderReviewsSummary.fromJson(response);
    });

class ProviderReviewsSummary {
  const ProviderReviewsSummary({
    required this.count,
    required this.averageRating,
    required this.items,
  });

  final int count;
  final double averageRating;
  final List<OrderReview> items;

  factory ProviderReviewsSummary.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return ProviderReviewsSummary(
      count: reader.number('count').toInt(),
      averageRating: reader.number('averageRating'),
      items: reader
          .list('items')
          .map(
            (item) =>
                OrderReview.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
    );
  }
}
