import 'dart:typed_data';

import '../../../core/network/json_api.dart';
import '../../messages/data/chat_image_picker.dart'
    show detectChatImageContentType;
import '../domain/order_photo.dart';

const _supportedImageTypes = {'image/jpeg', 'image/png', 'image/webp'};
const _maxPhotoBytes = 5 * 1024 * 1024;

abstract interface class OrderPhotosRepository {
  Future<List<OrderPhoto>> list(int orderId);

  Future<OrderPhoto> upload({required int orderId, required Uint8List bytes});

  Future<Uint8List> loadImage({required int orderId, required int photoId});
}

class HttpOrderPhotosRepository implements OrderPhotosRepository {
  const HttpOrderPhotosRepository(this._api);

  final JsonApi _api;

  @override
  Future<List<OrderPhoto>> list(int orderId) async {
    _requireId(orderId, 'orderId');
    final response = await _api.getList('/orders/$orderId/photos');
    return response.map(OrderPhoto.fromJson).toList(growable: false);
  }

  @override
  Future<OrderPhoto> upload({
    required int orderId,
    required Uint8List bytes,
  }) async {
    _requireId(orderId, 'orderId');
    if (bytes.isEmpty) {
      throw const FormatException('Incident photo is empty.');
    }
    if (bytes.length > _maxPhotoBytes) {
      throw const FormatException('Incident photo must be 5 MiB or smaller.');
    }
    final contentType = detectChatImageContentType(bytes);
    if (contentType == null) {
      throw const FormatException(
        'Only JPEG, PNG or WebP incident photos are supported.',
      );
    }
    final response = await _api.postMultipartObject(
      '/orders/$orderId/photos',
      file: BinaryUpload(
        fieldName: 'image',
        bytes: bytes,
        filename: 'incident${_extensionFor(contentType)}',
        contentType: contentType,
      ),
    );
    return OrderPhoto.fromJson(response);
  }

  @override
  Future<Uint8List> loadImage({
    required int orderId,
    required int photoId,
  }) async {
    _requireId(orderId, 'orderId');
    _requireId(photoId, 'photoId');
    final response = await _api.getBinary(
      '/orders/$orderId/photos/$photoId/image',
    );
    final contentType = response.contentType?.split(';').first.trim();
    if (contentType == null ||
        !_supportedImageTypes.contains(contentType) ||
        response.bytes.isEmpty ||
        response.bytes.length > _maxPhotoBytes) {
      throw const FormatException('Invalid protected incident photo response.');
    }
    return response.bytes;
  }
}

String _extensionFor(String contentType) => switch (contentType) {
  'image/jpeg' => '.jpg',
  'image/png' => '.png',
  'image/webp' => '.webp',
  _ => '.img',
};

void _requireId(int value, String name) {
  if (value <= 0) throw ArgumentError.value(value, name);
}
