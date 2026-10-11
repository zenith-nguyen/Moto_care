import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moto_care/features/messages/data/chat_image_picker.dart';

void main() {
  test('detects supported image types from bytes instead of extension', () {
    expect(
      detectChatImageContentType(Uint8List.fromList([0xff, 0xd8, 0xff, 0x00])),
      'image/jpeg',
    );
    expect(
      detectChatImageContentType(
        Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      ),
      'image/png',
    );
    expect(
      detectChatImageContentType(
        Uint8List.fromList([
          0x52,
          0x49,
          0x46,
          0x46,
          0,
          0,
          0,
          0,
          0x57,
          0x45,
          0x42,
          0x50,
        ]),
      ),
      'image/webp',
    );
    expect(detectChatImageContentType(Uint8List.fromList([1, 2, 3])), isNull);
  });

  test('picker uses a safe fallback name and detected content type', () async {
    final picker = FakeImagePicker(
      XFile.fromData(
        Uint8List.fromList([0xff, 0xd8, 0xff, 0x00]),
        name: r'folder\anh cua toi.png',
        mimeType: 'image/png',
      ),
    );

    final upload = await SystemChatImagePicker(picker)
        .pick(ChatImageSource.gallery);

    expect(picker.lastSource, ImageSource.gallery);
    expect(upload?.contentType, 'image/jpeg');
    expect(upload?.filename, 'chat-image.jpg');
  });

  test('picker rejects content that only pretends to be an image', () async {
    final picker = FakeImagePicker(
      XFile.fromData(
        Uint8List.fromList([1, 2, 3, 4]),
        name: 'fake.jpg',
        mimeType: 'image/jpeg',
      ),
    );

    expect(
      () => SystemChatImagePicker(picker).pick(ChatImageSource.camera),
      throwsA(isA<ChatImagePickerException>()),
    );
  });
}

class FakeImagePicker extends ImagePicker {
  FakeImagePicker(this.file);

  final XFile? file;
  ImageSource? lastSource;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    lastSource = source;
    return file;
  }
}
