import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/service_rating_theme.dart';

class ImagePickerBox extends StatelessWidget {
  const ImagePickerBox({
    super.key,
    required this.photo,
    required this.picking,
    required this.onPick,
    required this.onRemove,
    this.error,
  });
  final Uint8List? photo;
  final bool picking;
  final VoidCallback? onPick, onRemove;
  final String? error;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (photo != null)
            SizedBox(
              width: 108,
              height: 108,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        photo!,
                        key: const ValueKey('service-rating-photo'),
                        semanticLabel: 'Ảnh thực tế đã chọn',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: ServiceRatingColors.surface,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: ServiceRatingColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: IconButton(
                        key: const ValueKey('service-rating-remove-photo'),
                        tooltip: 'Xóa ảnh',
                        onPressed: onRemove,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: ServiceRatingColors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            key: const ValueKey('service-rating-add-photo'),
            onPressed: onPick,
            style: OutlinedButton.styleFrom(
              foregroundColor: ServiceRatingColors.red,
              backgroundColor: ServiceRatingColors.surface,
              side: const BorderSide(color: ServiceRatingColors.border),
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: picking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_a_photo_outlined, size: 20),
            label: Text(
              picking
                  ? 'Đang chọn ảnh…'
                  : photo == null
                  ? 'Thêm ảnh thực tế'
                  : 'Đổi ảnh thực tế',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            error!,
            style: const TextStyle(
              fontSize: 12,
              color: ServiceRatingColors.red,
            ),
          ),
        ),
    ],
  );
}
