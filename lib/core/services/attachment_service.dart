import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final attachmentPickerProvider = Provider<Future<Uint8List?> Function()>((ref) {
  return () => pickAttachment(ImageSource.gallery);
});

final cameraAttachmentPickerProvider = Provider<Future<Uint8List?> Function()>(
  (ref) =>
      () => pickAttachment(ImageSource.camera),
);

Future<Uint8List?> pickAttachment(ImageSource source) async {
  final photo = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 85,
    requestFullMetadata: false,
  );
  if (photo == null) return null;
  if (await photo.length() > 5 * 1024 * 1024) {
    throw StateError('Vui lòng chọn ảnh nhỏ hơn 5 MB.');
  }
  return photo.readAsBytes();
}

String attachmentError(Object error, {required bool useCamera}) =>
    error is StateError
    ? error.message.toString()
    : useCamera
    ? 'Không thể mở camera. Vui lòng kiểm tra quyền truy cập.'
    : 'Không thể mở thư viện ảnh. Vui lòng kiểm tra quyền truy cập.';

String? validateRequiredPhoto(Uint8List? value, String label, bool required) =>
    required && value == null ? 'Vui lòng chọn ${label.toLowerCase()}.' : null;
