import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attachment_state.dart';
import '../services/attachment_service.dart';

export '../models/attachment_state.dart';

final attachmentProvider = NotifierProvider.autoDispose
    .family<AttachmentController, AttachmentState, Object>(
      AttachmentController.new,
    );

class AttachmentController extends Notifier<AttachmentState> {
  AttachmentController(this.key);
  final Object key;
  @override
  AttachmentState build() => const AttachmentState();
  Future<Uint8List?> pick({required bool useCamera}) async {
    if (state.picking) return null;
    state = const AttachmentState(picking: true);
    try {
      final picker = ref.read(
        useCamera ? cameraAttachmentPickerProvider : attachmentPickerProvider,
      );
      final photo = await picker();
      if (!ref.mounted) return null;
      state = const AttachmentState();
      return photo;
    } catch (error) {
      if (ref.mounted) {
        state = AttachmentState(
          error: attachmentError(error, useCamera: useCamera),
        );
      }
      return null;
    }
  }
}
