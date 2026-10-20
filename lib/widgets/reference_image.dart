import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Hiển thị riêng vùng artwork của ảnh người dùng cung cấp.
/// PNG gốc được giữ nguyên; không render chữ, khung máy hoặc nút trong ảnh.
class ReferenceImage extends StatefulWidget {
  const ReferenceImage({super.key, required this.asset, required this.crop});
  final String asset;
  final Rect crop;
  @override
  State<ReferenceImage> createState() => _ReferenceImageState();
}

class _ReferenceImageState extends State<ReferenceImage> {
  ImageStream? _stream;
  ImageInfo? _info;
  late final ImageStreamListener _listener = ImageStreamListener((info, _) {
    final previous = _info;
    if (mounted) setState(() => _info = info);
    previous?.dispose();
  });
  void _resolve() {
    _stream?.removeListener(_listener);
    _stream = AssetImage(widget.asset)
        .resolve(createLocalImageConfiguration(context));
    _stream!.addListener(_listener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(ReferenceImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _resolve();
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _ReferencePainter(_info?.image, widget.crop),
      size: Size.infinite);
}

class _ReferencePainter extends CustomPainter {
  const _ReferencePainter(this.image, this.crop);
  final ui.Image? image;
  final Rect crop;
  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;
    final fitted = applyBoxFit(BoxFit.cover, crop.size, size);
    final source = Alignment.center.inscribe(fitted.source, crop);
    final destination =
        Alignment.center.inscribe(fitted.destination, Offset.zero & size);
    canvas.drawImageRect(image!, source, destination,
        Paint()..filterQuality = FilterQuality.high);
  }

  @override
  bool shouldRepaint(_ReferencePainter old) =>
      old.image != image || old.crop != crop;
}
