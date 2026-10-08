import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/attachment_service.dart';
import '../providers/attachment_provider.dart';
export '../services/attachment_service.dart'
    show attachmentPickerProvider, cameraAttachmentPickerProvider;

import 'service_scaffold.dart';

class PhotoAttachmentField extends ConsumerStatefulWidget {
  const PhotoAttachmentField({
    super.key,
    required this.label,
    required this.onChanged,
    this.requiredPhoto = false,
    this.useCamera = false,
  });

  final String label;
  final ValueChanged<Uint8List?> onChanged;
  final bool requiredPhoto;
  final bool useCamera;

  @override
  ConsumerState<PhotoAttachmentField> createState() =>
      _PhotoAttachmentFieldState();
}

class _PhotoAttachmentFieldState extends ConsumerState<PhotoAttachmentField> {
  final _pickerKey = Object();
  Future<void> _pick(FormFieldState<Uint8List> field) async {
    final photo = await ref
        .read(attachmentProvider(_pickerKey).notifier)
        .pick(useCamera: widget.useCamera);
    if (!mounted || photo == null) return;
    field.didChange(photo);
    widget.onChanged(photo);
  }

  @override
  Widget build(BuildContext context) {
    final picker = ref.watch(attachmentProvider(_pickerKey));
    ref.listen(attachmentProvider(_pickerKey), (_, next) {
      if (next.error != null) showServiceMessage(context, next.error!);
    });
    return FormField<Uint8List>(
      validator: (value) =>
          validateRequiredPhoto(value, widget.label, widget.requiredPhoto),
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.useCamera)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: picker.picking ? null : () => _pick(field),
                child: Column(
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 36,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      picker.picking ? 'Đang mở camera…' : widget.label,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: picker.picking ? null : () => _pick(field),
              icon: Icon(
                field.value == null
                    ? Icons.add_photo_alternate_outlined
                    : Icons.check_circle_outline,
              ),
              label: Text(picker.picking ? 'Đang chọn ảnh…' : widget.label),
            ),
          if (field.value != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                field.value!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                field.didChange(null);
                widget.onChanged(null);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Xóa ảnh'),
            ),
          ],
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                field.errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
