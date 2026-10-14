import 'dart:typed_data';

import '../../../core/network/json_reader.dart';

const maxChatImageBytes = 5 * 1024 * 1024;
const supportedChatImageTypes = {'image/jpeg', 'image/png', 'image/webp'};

class ChatImageUpload {
  ChatImageUpload({
    required this.bytes,
    required this.filename,
    required this.contentType,
  }) {
    if (bytes.isEmpty || bytes.length > maxChatImageBytes) {
      throw const FormatException(
        'Chat image must be between 1 byte and 5 MiB.',
      );
    }
    if (filename.trim().isEmpty ||
        filename.contains('/') ||
        filename.contains('\\')) {
      throw const FormatException('Invalid chat image filename.');
    }
    if (!supportedChatImageTypes.contains(contentType)) {
      throw const FormatException('Unsupported chat image type.');
    }
  }

  final Uint8List bytes;
  final String filename;
  final String contentType;
}

class ChatMessageImage {
  const ChatMessageImage({
    required this.url,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String url;
  final String mimeType;
  final int sizeBytes;

  factory ChatMessageImage.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final url = reader.string('url');
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasQuery ||
        uri.hasFragment ||
        !url.startsWith('/orders/') ||
        !url.endsWith('/image')) {
      throw const FormatException('Invalid protected chat image URL.');
    }
    final mimeType = reader.string('mimeType');
    if (!supportedChatImageTypes.contains(mimeType)) {
      throw const FormatException('Unsupported chat image type.');
    }
    final sizeBytes = reader.positiveInt('sizeBytes');
    if (sizeBytes > maxChatImageBytes) {
      throw const FormatException('Chat image exceeds 5 MiB.');
    }
    return ChatMessageImage(url: url, mimeType: mimeType, sizeBytes: sizeBytes);
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.image,
    required this.createdAt,
  });

  final int id;
  final int senderId;
  final String? content;
  final ChatMessageImage? image;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final image = reader.nullableObject('image');
    final content = reader.nullableString('content');
    if ((content == null || content.isEmpty) && image == null) {
      throw const FormatException('Chat message has no content.');
    }
    return ChatMessage(
      id: reader.positiveInt('id'),
      senderId: reader.positiveInt('senderId'),
      content: content,
      image: image == null ? null : ChatMessageImage.fromJson(image),
      createdAt: reader.dateTime('createdAt'),
    );
  }
}

class ProtectedChatImage {
  const ProtectedChatImage({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;
}
