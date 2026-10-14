import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/core/network/json_api.dart';
import 'package:moto_care/features/messages/data/messages_repository.dart';
import 'package:moto_care/features/messages/domain/chat_message.dart';

import '../../support/recording_json_api.dart';

void main() {
  late RecordingJsonApi api;
  late HttpMessagesRepository repository;

  setUp(() {
    api = RecordingJsonApi();
    repository = HttpMessagesRepository(api);
  });

  test(
    'loads chronological message history with protected image metadata',
    () async {
      api.listResponse = [_messageJson()];

      final messages = await repository.list(42);

      expect(api.lastPath, '/orders/42/messages');
      expect(messages.single.content, 'Tôi đang tới');
      expect(messages.single.image?.mimeType, 'image/jpeg');
    },
  );

  test('sends trimmed text as JSON', () async {
    api.objectResponse = _messageJson(content: 'Đã thấy bạn', image: null);

    final message = await repository.send(
      orderId: 42,
      content: '  Đã thấy bạn  ',
    );

    expect(api.lastMethod, 'POST');
    expect(api.lastPath, '/orders/42/messages');
    expect(api.lastData, {'content': 'Đã thấy bạn'});
    expect(message.content, 'Đã thấy bạn');
  });

  test('sends an image as bounded multipart data', () async {
    api.objectResponse = _messageJson(content: 'Hiện trường');
    final image = ChatImageUpload(
      bytes: Uint8List.fromList([0xff, 0xd8, 0xff]),
      filename: 'incident.jpg',
      contentType: 'image/jpeg',
    );

    await repository.send(orderId: 42, content: ' Hiện trường ', image: image);

    expect(api.lastMethod, 'POST_MULTIPART');
    expect(api.lastMultipartFields, {'content': 'Hiện trường'});
    expect(api.lastUpload?.fieldName, 'image');
    expect(api.lastUpload?.contentType, 'image/jpeg');
  });

  test(
    'downloads protected image bytes and validates response MIME type',
    () async {
      api.binaryResponse = BinaryResponse(
        bytes: Uint8List.fromList([0x89, 0x50, 0x4e, 0x47]),
        contentType: 'image/png; charset=binary',
      );

      final image = await repository.loadImage(orderId: 42, messageId: 9);

      expect(api.lastPath, '/orders/42/messages/9/image');
      expect(image.contentType, 'image/png');
      expect(image.bytes, isNotEmpty);
    },
  );

  test(
    'rejects empty messages and unsupported image types before HTTP',
    () async {
      await expectLater(
        repository.send(orderId: 42, content: '   '),
        throwsFormatException,
      );
      expect(
        () => ChatImageUpload(
          bytes: Uint8List.fromList([1]),
          filename: 'incident.gif',
          contentType: 'image/gif',
        ),
        throwsFormatException,
      );
      expect(api.lastPath, isNull);
    },
  );
}

Map<String, dynamic> _messageJson({
  String? content = 'Tôi đang tới',
  Object? image = _defaultImage,
}) => {
  'id': 9,
  'senderId': 3,
  'content': content,
  'image': identical(image, _defaultImage)
      ? {
          'url': '/orders/42/messages/9/image',
          'mimeType': 'image/jpeg',
          'sizeBytes': 2048,
        }
      : image,
  'createdAt': '2026-10-10T00:00:00.000Z',
};

const _defaultImage = Object();
