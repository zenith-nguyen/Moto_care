import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'service_scaffold.dart';

final attachmentPickerProvider = Provider<Future<Uint8List?> Function()>((ref) {
  return () async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
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
  };
});

class PhotoAttachmentField extends ConsumerStatefulWidget {
  const PhotoAttachmentField({
    super.key,
    required this.label,
    required this.onChanged,
    this.requiredPhoto = false,
  });

  final String label;
  final ValueChanged<Uint8List?> onChanged;
  final bool requiredPhoto;

  @override
  ConsumerState<PhotoAttachmentField> createState() =>
      _PhotoAttachmentFieldState();
}

class _PhotoAttachmentFieldState extends ConsumerState<PhotoAttachmentField> {
  bool _picking = false;

  Future<void> _pick(FormFieldState<Uint8List> field) async {
    setState(() => _picking = true);
    try {
      final photo = await ref.read(attachmentPickerProvider)();
      if (!mounted || photo == null) return;
      field.didChange(photo);
      widget.onChanged(photo);
    } catch (error) {
      if (mounted) {
        showServiceMessage(
          context,
          error is StateError
              ? error.message.toString()
              : 'Không thể mở thư viện ảnh. Vui lòng kiểm tra quyền truy cập.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) => FormField<Uint8List>(
    validator: (value) => widget.requiredPhoto && value == null
        ? 'Vui lòng chọn ${widget.label.toLowerCase()}.'
        : null,
    builder: (field) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _picking ? null : () => _pick(field),
          icon: Icon(
            field.value == null
                ? Icons.add_photo_alternate_outlined
                : Icons.check_circle_outline,
          ),
          label: Text(_picking ? 'Đang chọn ảnh…' : widget.label),
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
