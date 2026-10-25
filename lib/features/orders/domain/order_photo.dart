import '../../../core/network/json_reader.dart';

/// Metadata for an incident photo attached to an order. The bytes are fetched
/// separately from the protected `GET /orders/:id/photos/:photoId/image`.
class OrderPhoto {
  const OrderPhoto({
    required this.id,
    required this.orderId,
    required this.uploadedById,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
  });

  final int id;
  final int orderId;
  final int uploadedById;
  final String mimeType;
  final int sizeBytes;
  final DateTime createdAt;

  factory OrderPhoto.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return OrderPhoto(
      id: reader.positiveInt('id'),
      orderId: reader.positiveInt('orderId'),
      uploadedById: reader.positiveInt('uploadedById'),
      mimeType: reader.string('mimeType'),
      sizeBytes: reader.number('sizeBytes').toInt(),
      createdAt: reader.dateTime('createdAt'),
    );
  }
}
