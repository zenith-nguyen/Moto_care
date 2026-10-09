import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import 'order_reviews_state.dart';

final orderReviewsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<OrderReviewsController, OrderReviewsState, int>(
      OrderReviewsController.new,
    );

class OrderReviewsController extends AsyncNotifier<OrderReviewsState> {
  OrderReviewsController(this.orderId);

  final int orderId;

  @override
  Future<OrderReviewsState> build() async {
    if (orderId <= 0) throw ArgumentError.value(orderId, 'orderId');
    return OrderReviewsState(
      reviews: await ref.read(reviewsRepositoryProvider).list(orderId),
    );
  }

  Future<void> refresh() => _runAction(OrderReviewsAction.refresh, () async {
    final reviews = await ref.read(reviewsRepositoryProvider).list(orderId);
    state = AsyncData(_requireState().copyWith(reviews: reviews));
  });

  Future<void> create({required int rating, String? comment}) {
    return _runAction(OrderReviewsAction.create, () async {
      final created = await ref
          .read(reviewsRepositoryProvider)
          .create(orderId: orderId, rating: rating, comment: comment);
      final current = _requireState();
      state = AsyncData(
        current.copyWith(
          reviews: List.unmodifiable([...current.reviews, created]),
        ),
      );
    });
  }

  Future<void> _runAction(
    OrderReviewsAction action,
    Future<void> Function() operation,
  ) async {
    final current = state.value;
    if (current == null || current.isBusy) return;
    state = AsyncData(current.copyWith(action: action, lastFailure: null));
    try {
      await operation();
      final latest = state.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(action: null, lastFailure: null));
      }
    } catch (error) {
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(action: null, lastFailure: error));
    }
  }

  OrderReviewsState _requireState() {
    final current = state.value;
    if (current == null) throw StateError('Order reviews are not loaded.');
    return current;
  }
}
