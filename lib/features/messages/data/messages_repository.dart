import '../../../core/network/json_api.dart';
import '../domain/chat_message.dart';

abstract interface class MessagesRepository {
  Future<List<ChatMessage>> list(int orderId);

  Future<ChatMessage> send({
    required int orderId,
    String? content,
    ChatImageUpload? image,
  });

  Future<ProtectedChatImage> loadImage({
    required int orderId,
    required int messageId,
  });
}

class HttpMessagesRepository implements MessagesRepository {
  const HttpMessagesRepository(this._api);

  final JsonApi _api;

  @override
  Future<List<ChatMessage>> list(int orderId) async {
    _requireId(orderId, 'orderId');
    final response = await _api.getList('/orders/$orderId/messages');
    return response.map(ChatMessage.fromJson).toList(growable: false);
  }

  @override
  Future<ChatMessage> send({
    required int orderId,
    String? content,
    ChatImageUpload? image,
  }) async {
    _requireId(orderId, 'orderId');
    final normalized = content?.trim();
    if (normalized != null && normalized.length > 2000) {
      throw const FormatException(
        'Message text cannot exceed 2000 characters.',
      );
    }
    if ((normalized == null || normalized.isEmpty) && image == null) {
      throw const FormatException(
        'Message must contain text, an image, or both.',
      );
    }

    final Map<String, dynamic> response;
    if (image == null) {
      response = await _api.postObject(
        '/orders/$orderId/messages',
        data: {'content': normalized},
      );
    } else {
      response = await _api.postMultipartObject(
        '/orders/$orderId/messages',
        fields: {
          if (normalized != null && normalized.isNotEmpty)
            'content': normalized,
        },
        file: BinaryUpload(
          fieldName: 'image',
          bytes: image.bytes,
          filename: image.filename,
          contentType: image.contentType,
        ),
      );
    }
    return ChatMessage.fromJson(response);
  }

  @override
  Future<ProtectedChatImage> loadImage({
    required int orderId,
    required int messageId,
  }) async {
    _requireId(orderId, 'orderId');
    _requireId(messageId, 'messageId');
    final response = await _api.getBinary(
      '/orders/$orderId/messages/$messageId/image',
    );
    final contentType = response.contentType?.split(';').first.trim();
    if (contentType == null ||
        !supportedChatImageTypes.contains(contentType) ||
        response.bytes.isEmpty ||
        response.bytes.length > maxChatImageBytes) {
      throw const FormatException('Invalid protected chat image response.');
    }
    return ProtectedChatImage(bytes: response.bytes, contentType: contentType);
  }
}

void _requireId(int value, String name) {
  if (value <= 0) throw ArgumentError.value(value, name);
}
