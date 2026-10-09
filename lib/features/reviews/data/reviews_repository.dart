import '../../../core/network/json_api.dart';
import '../domain/order_review.dart';

abstract interface class ReviewsRepository {
  Future<List<OrderReview>> list(int orderId);

  Future<OrderReview> create({
    required int orderId,
    required int rating,
    String? comment,
  });
}

class HttpReviewsRepository implements ReviewsRepository {
  const HttpReviewsRepository(this._api);

  final JsonApi _api;

  @override
  Future<List<OrderReview>> list(int orderId) async {
    _requireOrderId(orderId);
    final response = await _api.getList('/orders/$orderId/reviews');
    return response.map(OrderReview.fromJson).toList(growable: false);
  }

  @override
  Future<OrderReview> create({
    required int orderId,
    required int rating,
    String? comment,
  }) async {
    _requireOrderId(orderId);
    if (rating < 1 || rating > 5) {
      throw const FormatException('Review rating must be 1 to 5.');
    }
    final normalized = comment?.trim();
    if (normalized != null && normalized.length > 500) {
      throw const FormatException(
        'Review comment cannot exceed 500 characters.',
      );
    }
    final response = await _api.postObject(
      '/orders/$orderId/reviews',
      data: {
        'rating': rating,
        if (normalized != null && normalized.isNotEmpty) 'comment': normalized,
      },
    );
    return OrderReview.fromJson(response);
  }
}

void _requireOrderId(int orderId) {
  if (orderId <= 0) throw ArgumentError.value(orderId, 'orderId');
}
