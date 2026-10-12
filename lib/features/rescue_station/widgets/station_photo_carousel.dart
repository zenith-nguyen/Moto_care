import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../theme/station_detail_theme.dart';

class StationPhotoCarousel extends StatefulWidget {
  const StationPhotoCarousel({
    super.key,
    required this.images,
    required this.height,
    required this.favorite,
    required this.onBack,
    required this.onFavorite,
    required this.onShare,
  });

  final List<String> images;
  final double height;
  final bool favorite;
  final VoidCallback onBack;
  final VoidCallback onFavorite;
  final ValueChanged<BuildContext>? onShare;

  @override
  State<StationPhotoCarousel> createState() => _StationPhotoCarouselState();
}

class _StationPhotoCarouselState extends State<StationPhotoCarousel> {
  int _index = 0;

  @override
  void didUpdateWidget(StationPhotoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.images.length) _index = 0;
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (widget.images.isEmpty)
          const _MissingImage()
        else
          CarouselSlider.builder(
            key: const ValueKey('station-photo-carousel'),
            itemCount: widget.images.length,
            itemBuilder: (context, index, _) => Semantics(
              label: 'Ảnh trạm ${index + 1} trên ${widget.images.length}',
              image: true,
              child: Image.asset(
                widget.images[index],
                width: double.infinity,
                height: widget.height,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => const _MissingImage(),
              ),
            ),
            options: CarouselOptions(
              height: widget.height,
              viewportFraction: 1,
              enableInfiniteScroll: false,
              autoPlay: false,
              onPageChanged: (index, _) => setState(() => _index = index),
            ),
          ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x55000000),
                  Colors.transparent,
                  Color(0x33000000),
                ],
                stops: [0, .45, 1],
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          top: MediaQuery.paddingOf(context).top + 12,
          child: Row(
            children: [
              _PhotoAction(
                actionKey: const ValueKey('station-back'),
                label: 'Quay lại',
                icon: Icons.arrow_back_rounded,
                onPressed: widget.onBack,
              ),
              const Spacer(),
              Builder(
                builder: (buttonContext) => _PhotoAction(
                  actionKey: const ValueKey('station-share'),
                  label: 'Chia sẻ trạm',
                  icon: Icons.ios_share_rounded,
                  onPressed: widget.onShare == null
                      ? null
                      : () => widget.onShare!(buttonContext),
                ),
              ),
              const SizedBox(width: 10),
              Semantics(
                selected: widget.favorite,
                child: _PhotoAction(
                  actionKey: const ValueKey('station-favorite'),
                  label: widget.favorite ? 'Bỏ lưu trạm' : 'Lưu trạm',
                  icon: widget.favorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: widget.favorite ? StationDetailColors.red : null,
                  onPressed: widget.onFavorite,
                ),
              ),
            ],
          ),
        ),
        if (widget.images.isNotEmpty)
          Positioned(
            bottom: 40,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x88000000),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${_index + 1}/${widget.images.length}',
                    key: const ValueKey('station-photo-count'),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _PhotoAction extends StatelessWidget {
  const _PhotoAction({
    required this.actionKey,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final Key actionKey;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton.filled(
    key: actionKey,
    tooltip: label,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: const Color(0xDDEFEFF1),
      disabledBackgroundColor: const Color(0xBBEFEFF1),
      foregroundColor: color ?? StationDetailColors.text,
      fixedSize: const Size(48, 48),
    ),
    icon: Icon(icon, size: 21),
  );
}

class _MissingImage extends StatelessWidget {
  const _MissingImage();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: StationDetailColors.surface,
    child: Center(
      child: Icon(
        Icons.storefront_outlined,
        size: 64,
        color: StationDetailColors.muted,
      ),
    ),
  );
}
