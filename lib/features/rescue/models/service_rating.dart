import 'dart:typed_data';

class QuickRatingTag {
  const QuickRatingTag(this.id, this.label);
  final String id, label;
}

class ServiceRating {
  ServiceRating({
    required this.orderId,
    required this.stars,
    required Set<String> tagIds,
    required this.comment,
    required this.createdAt,
    Uint8List? photo,
  }) : tagIds = Set.unmodifiable(tagIds),
       photo = photo == null
           ? null
           : Uint8List.fromList(photo).asUnmodifiableView();
  final String orderId, comment;
  final int stars;
  final Set<String> tagIds;
  final DateTime createdAt;
  final Uint8List? photo;
}

class ServiceRatingSummary {
  const ServiceRatingSummary({
    required this.mechanicName,
    required this.shopName,
    required this.initials,
    required this.serviceAndPrice,
  });
  final String mechanicName, shopName, initials, serviceAndPrice;
}
