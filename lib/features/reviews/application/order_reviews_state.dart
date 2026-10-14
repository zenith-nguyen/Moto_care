import '../domain/order_review.dart';

enum OrderReviewsAction { refresh, create }

class OrderReviewsState {
  const OrderReviewsState({
    required this.reviews,
    this.action,
    this.lastFailure,
  });

  final List<OrderReview> reviews;
  final OrderReviewsAction? action;
  final Object? lastFailure;

  bool get isBusy => action != null;

  OrderReviewsState copyWith({
    List<OrderReview>? reviews,
    Object? action = _unchanged,
    Object? lastFailure = _unchanged,
  }) {
    return OrderReviewsState(
      reviews: reviews ?? this.reviews,
      action: identical(action, _unchanged)
          ? this.action
          : action as OrderReviewsAction?,
      lastFailure: identical(lastFailure, _unchanged)
          ? this.lastFailure
          : lastFailure,
    );
  }
}

const _unchanged = Object();
