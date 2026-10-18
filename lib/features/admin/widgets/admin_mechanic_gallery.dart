import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/admin_tokens.dart';
import '../models/admin_models.dart';
import '../providers/admin_providers.dart';
import '../theme/admin_mechanic_theme.dart';

class AdminMechanicImage extends StatelessWidget {
  const AdminMechanicImage({
    super.key,
    required this.photo,
    this.fit = BoxFit.cover,
    this.emptyLabel = 'Chưa có ảnh',
    this.emptyIcon = Icons.image_outlined,
  });

  final AdminMechanicPhoto? photo;
  final BoxFit fit;
  final String emptyLabel;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => ColoredBox(
      color: const Color(0xFFEAF0F5),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emptyIcon, size: 23, color: AdminTokens.neutral),
              if (emptyLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  emptyLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AdminMechanicTheme.label.copyWith(fontSize: 9),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    final image = photo;
    if (image == null || image.location.trim().isEmpty) return placeholder();
    return image.isNetwork
        ? Image.network(
            image.location,
            fit: fit,
            semanticLabel: image.label,
            gaplessPlayback: true,
            errorBuilder: (_, error, stack) => placeholder(),
          )
        : Image.asset(
            image.location,
            fit: fit,
            semanticLabel: image.label,
            gaplessPlayback: true,
            errorBuilder: (_, error, stack) => placeholder(),
          );
  }
}

void showAdminMechanicGallery(
  BuildContext context,
  AdminProviderApplication application,
  AdminMechanicPhoto initial,
) {
  final photos =
      [
            application.workshopPhoto,
            application.identityFrontPhoto,
            application.identityBackPhoto,
            application.portraitPhoto,
            ...application.additionalPhotos,
          ]
          .whereType<AdminMechanicPhoto>()
          .where((photo) => photo.location.trim().isNotEmpty)
          .toList();
  final index = photos.indexOf(initial);
  if (index < 0) return;
  showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (_) => _MechanicPhotoViewer(photos: photos, initialIndex: index),
  );
}

class AdminMechanicGallery extends StatelessWidget {
  const AdminMechanicGallery({super.key, required this.application});
  final AdminProviderApplication application;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Padding(
      padding: const EdgeInsets.all(7),
      child: Row(
        children: [
          for (final (slot, label, photo, icon) in [
            (
              'workshop',
              'Tiệm sửa xe',
              application.workshopPhoto,
              Icons.storefront_outlined,
            ),
            (
              'front',
              'CCCD trước',
              application.identityFrontPhoto,
              Icons.badge_outlined,
            ),
            (
              'back',
              'CCCD sau',
              application.identityBackPhoto,
              Icons.badge_outlined,
            ),
            (
              'portrait',
              application.portraitPhoto == null ? 'Giấy tờ khác' : 'Chân dung',
              application.portraitPhoto ??
                  (application.additionalPhotos.isEmpty
                      ? null
                      : application.additionalPhotos.first),
              Icons.person_outline,
            ),
          ]) ...[
            if (slot != 'workshop') const SizedBox(width: 7),
            Expanded(
              child: Semantics(
                label: photo == null ? '$label: chưa có ảnh' : 'Xem $label',
                button: photo != null,
                child: InkWell(
                  key: ValueKey('admin-mechanic-thumbnail-$slot'),
                  onTap: photo == null
                      ? null
                      : () => showAdminMechanicGallery(
                          context,
                          application,
                          photo,
                        ),
                  borderRadius: BorderRadius.circular(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: MediaQuery.textScalerOf(context).scale(1) > 1.2
                          ? 88
                          : 62,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AdminMechanicImage(
                            photo: photo,
                            emptyLabel: label,
                            emptyIcon: icon,
                          ),
                          if (slot == 'portrait' &&
                              application.additionalPhotos.length >
                                  (application.portraitPhoto == null ? 1 : 0))
                            ColoredBox(
                              color: Colors.black45,
                              child: Center(
                                child: Text(
                                  '+${application.additionalPhotos.length - (application.portraitPhoto == null ? 1 : 0)}',
                                  style: AdminMechanicTheme.heading.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _MechanicPhotoViewer extends ConsumerStatefulWidget {
  const _MechanicPhotoViewer({
    required this.photos,
    required this.initialIndex,
  });
  final List<AdminMechanicPhoto> photos;
  final int initialIndex;

  @override
  ConsumerState<_MechanicPhotoViewer> createState() =>
      _MechanicPhotoViewerState();
}

class _MechanicPhotoViewerState extends ConsumerState<_MechanicPhotoViewer> {
  late final _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allowed = ref.watch(adminSessionProvider)?.isAdmin == true;
    return Dialog.fullscreen(
      key: const ValueKey('admin-mechanic-photo-viewer'),
      backgroundColor: AdminMechanicTheme.backdrop,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Đóng ảnh hồ sơ',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      allowed ? widget.photos[_index].label : 'Ảnh hồ sơ',
                      style: AdminMechanicTheme.heading.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (allowed)
                    Text(
                      '${_index + 1}/${widget.photos.length}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),
            Expanded(
              child: allowed
                  ? PageView.builder(
                      controller: _controller,
                      itemCount: widget.photos.length,
                      onPageChanged: (index) => setState(() => _index = index),
                      itemBuilder: (_, index) => InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: SizedBox.expand(
                          child: AdminMechanicImage(
                            photo: widget.photos[index],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: Text(
                        'Bạn không có quyền truy cập khu vực này',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ),
            if (allowed)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Vuốt để xem ảnh • Chụm hai ngón để phóng to',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
