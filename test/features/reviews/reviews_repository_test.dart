import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/reviews/data/reviews_repository.dart';

import '../../support/recording_json_api.dart';

void main() {
  late RecordingJsonApi api;
  late HttpReviewsRepository repository;

  setUp(() {
    api = RecordingJsonApi();
    repository = HttpReviewsRepository(api);
  });

  test('loads participant reviews for a completed order', () async {
    api.listResponse = [_reviewJson()];

    final reviews = await repository.list(42);

    expect(api.lastPath, '/orders/42/reviews');
    expect(reviews.single.rating, 5);
  });

  test('creates a trimmed review with the exact backend contract', () async {
    api.objectResponse = _reviewJson(comment: 'Hỗ trợ nhanh');

    final review = await repository.create(
      orderId: 42,
      rating: 5,
      comment: '  Hỗ trợ nhanh  ',
    );

    expect(api.lastPath, '/orders/42/reviews');
    expect(api.lastData, {'rating': 5, 'comment': 'Hỗ trợ nhanh'});
    expect(review.comment, 'Hỗ trợ nhanh');
  });

  test('rejects invalid ratings and oversized comments before HTTP', () async {
    await expectLater(
      repository.create(orderId: 42, rating: 0),
      throwsFormatException,
    );
    await expectLater(
      repository.create(
        orderId: 42,
        rating: 5,
        comment: List.filled(501, 'x').join(),
      ),
      throwsFormatException,
    );
    expect(api.lastPath, isNull);
  });
}

Map<String, dynamic> _reviewJson({String? comment = 'Hỗ trợ nhanh'}) => {
  'id': 4,
  'orderId': 42,
  'reviewerId': 7,
  'revieweeId': 3,
  'rating': 5,
  'comment': comment,
  'createdAt': '2026-10-10T00:10:00.000Z',
};
