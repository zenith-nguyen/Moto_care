sealed class RealtimeEvent {
  const RealtimeEvent({required this.orderId});

  final int orderId;
}

class OfferCreated extends RealtimeEvent {
  const OfferCreated({
    required super.orderId,
    required this.offerId,
    required this.expiresAt,
  });

  final int offerId;
  final DateTime expiresAt;
}

class OfferExpired extends RealtimeEvent {
  const OfferExpired({required super.orderId, required this.offerId});

  final int offerId;
}

class OrderStatusChanged extends RealtimeEvent {
  const OrderStatusChanged({required super.orderId, required this.status});

  final String status;
}

class ProviderLocationUpdated extends RealtimeEvent {
  const ProviderLocationUpdated({
    required super.orderId,
    required this.providerId,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  final int providerId;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;
}

class MessageCreated extends RealtimeEvent {
  const MessageCreated({
    required super.orderId,
    required this.id,
    required this.senderId,
    required this.content,
    required this.image,
    required this.createdAt,
  });

  final int id;
  final int senderId;
  final String? content;
  final RealtimeMessageImage? image;
  final DateTime createdAt;
}

class RealtimeMessageImage {
  const RealtimeMessageImage({
    required this.url,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String url;
  final String mimeType;
  final int sizeBytes;
}
