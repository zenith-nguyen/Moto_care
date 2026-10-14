import '../../../core/network/json_reader.dart';

class OrderReview {
  const OrderReview({
    required this.id,
    required this.orderId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final int id;
  final int orderId;
  final int reviewerId;
  final int revieweeId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  factory OrderReview.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final rating = reader.positiveInt('rating');
    if (rating > 5) {
      throw const FormatException('Review rating must be 1 to 5.');
    }
    return OrderReview(
      id: reader.positiveInt('id'),
      orderId: reader.positiveInt('orderId'),
      reviewerId: reader.positiveInt('reviewerId'),
      revieweeId: reader.positiveInt('revieweeId'),
      rating: rating,
      comment: reader.nullableString('comment'),
      createdAt: reader.dateTime('createdAt'),
    );
  }
}
