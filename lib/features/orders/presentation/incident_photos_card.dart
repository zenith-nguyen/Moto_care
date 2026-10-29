import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/revo_brand.dart';
import '../application/order_photos_provider.dart';

/// Shows the incident photos a customer attached to an order. Renders nothing
/// when there are no photos, so it is safe to drop into any order detail view.
class IncidentPhotosCard extends ConsumerWidget {
  const IncidentPhotosCard({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(orderIncidentPhotosProvider(orderId));
    return photos.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: RevoBrandColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: RevoBrandColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    size: 20,
                    color: RevoBrandColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ảnh sự cố (${items.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: RevoBrandColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final photo = items[index];
                    return _IncidentThumbnail(
                      orderId: orderId,
                      photoId: photo.id,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IncidentThumbnail extends ConsumerWidget {
  const _IncidentThumbnail({required this.orderId, required this.photoId});

  final int orderId;
  final int photoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (orderId: orderId, photoId: photoId);
    final bytes = ref.watch(orderIncidentPhotoBytesProvider(key));
    return bytes.when(
      loading: () => const _ThumbShell(
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => _ThumbShell(
        child: IconButton(
          onPressed: () => ref.invalidate(orderIncidentPhotoBytesProvider(key)),
          icon: const Icon(Icons.refresh_rounded, size: 20),
        ),
      ),
      data: (data) => GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: InteractiveViewer(
              child: Image.memory(data, fit: BoxFit.contain),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(data, width: 96, height: 96, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _ThumbShell extends StatelessWidget {
  const _ThumbShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: RevoBrandColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RevoBrandColors.border),
      ),
      child: child,
    );
  }
}
