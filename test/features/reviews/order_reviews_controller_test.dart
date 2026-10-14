import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/app_dependencies.dart';
import 'package:moto_care/features/reviews/application/order_reviews_controller.dart';
import 'package:moto_care/features/reviews/data/reviews_repository.dart';
import 'package:moto_care/features/reviews/domain/order_review.dart';

void main() {
  test('loads and appends the customer review once', () async {
    final repository = FakeReviewsRepository();
    final container = ProviderContainer(
      overrides: [reviewsRepositoryProvider.overrideWithValue(repository)],
    );
    final provider = orderReviewsControllerProvider(42);
    final listener = container.listen(provider, (_, _) {});
    addTearDown(() {
      listener.close();
      container.dispose();
    });

    expect((await container.read(provider.future)).reviews, isEmpty);

    await container
        .read(provider.notifier)
        .create(rating: 5, comment: ' Rất nhanh ');

    final state = container.read(provider).value!;
    expect(repository.createCount, 1);
    expect(state.reviews.single.rating, 5);
    expect(state.lastFailure, isNull);
  });
}

class FakeReviewsRepository implements ReviewsRepository {
  int createCount = 0;

  @override
  Future<List<OrderReview>> list(int orderId) async => const [];

  @override
  Future<OrderReview> create({
    required int orderId,
    required int rating,
    String? comment,
  }) async {
    createCount += 1;
    return OrderReview.fromJson({
      'id': 1,
      'orderId': orderId,
      'reviewerId': 7,
      'revieweeId': 3,
      'rating': rating,
      'comment': comment?.trim(),
      'createdAt': '2026-10-10T00:00:00.000Z',
    });
  }
}
