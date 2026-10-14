import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/chat_message.dart';

enum ChatImageSource { camera, gallery }

class ChatImagePickerException implements Exception {
  const ChatImagePickerException(this.message);

  final String message;

  @override
  String toString() => 'ChatImagePickerException($message)';
}

abstract interface class ChatImagePicker {
  Future<ChatImageUpload?> pick(ChatImageSource source);

  Future<ChatImageUpload?> recoverLostImage();
}

class SystemChatImagePicker implements ChatImagePicker {
  SystemChatImagePicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<ChatImageUpload?> pick(ChatImageSource source) async {
    final file = await _picker.pickImage(
      source: source == ChatImageSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      requestFullMetadata: false,
    );
    return file == null ? null : _toUpload(file);
  }

  @override
  Future<ChatImageUpload?> recoverLostImage() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final response = await _picker.retrieveLostData();
    if (response.isEmpty) return null;
    if (response.exception != null) {
      throw const ChatImagePickerException(
        'Android could not recover the selected image.',
      );
    }
    final file = response.file;
    return file == null ? null : _toUpload(file);
  }

  Future<ChatImageUpload> _toUpload(XFile file) async {
    final length = await file.length();
    if (length <= 0 || length > maxChatImageBytes) {
      throw const ChatImagePickerException(
        'The selected image must be 5 MiB or smaller.',
      );
    }
    final bytes = await file.readAsBytes();
    final contentType = detectChatImageContentType(bytes);
    if (contentType == null) {
      throw const ChatImagePickerException(
        'Only JPEG, PNG, and WebP images are supported.',
      );
    }
    return ChatImageUpload(
      bytes: bytes,
      filename: _safeFilename(file.name, contentType),
      contentType: contentType,
    );
  }
}

@visibleForTesting
String? detectChatImageContentType(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  return null;
}

String _safeFilename(String rawName, String contentType) {
  final baseName = rawName.split(RegExp(r'[/\\]')).last.trim();
  final extension = switch (contentType) {
    'image/jpeg' => '.jpg',
    'image/png' => '.png',
    'image/webp' => '.webp',
    _ => throw const FormatException('Unsupported chat image type.'),
  };
  final stem = baseName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (stem.isEmpty) return 'chat-image$extension';
  final lower = stem.toLowerCase();
  if (lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp')) {
    return stem.substring(0, stem.lastIndexOf('.')) + extension;
  }
  return '$stem$extension';
}
