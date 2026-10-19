import 'package:flutter/material.dart';

class RevoLogo extends StatelessWidget {
  const RevoLogo({super.key, this.width = 150, this.color = Colors.black});

  static const asset = 'assets/images/REVO.png';
  // Visible wordmark bounds in the 2000px source, with 2% breathing room.
  static const _wordmarkBounds = Rect.fromLTRB(164, 802, 1822, 1204);

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scale = width / _wordmarkBounds.width;
    final imageSize = 2000 * scale;
    return SizedBox(
      width: width,
      // Preserve the existing header space around the wider wordmark.
      height: width * 460 / 840,
      child: ClipRect(
        child: Transform.translate(
          offset: Offset(
            (1000 - _wordmarkBounds.center.dx) * scale,
            (1000 - _wordmarkBounds.center.dy) * scale,
          ),
          child: OverflowBox(
            minWidth: imageSize,
            maxWidth: imageSize,
            minHeight: imageSize,
            maxHeight: imageSize,
            child: Image.asset(
              asset,
              width: imageSize,
              height: imageSize,
              color: color,
              semanticLabel: 'Logo Revo',
            ),
          ),
        ),
      ),
    );
  }
}
