import 'package:flutter/material.dart';

import '../theme/revo_brand.dart';

class RevoLogo extends StatelessWidget {
  const RevoLogo({
    super.key,
    this.width = 150,
    this.color = RevoBrandColors.primary,
  });

  static const asset = 'assets/images/logo-revo.png';

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // The supplied 2000px PNG has transparent padding around the wordmark.
    // Crop that padding in the layout while keeping one original logo asset.
    final imageSize = width * 2000 / 840;
    return SizedBox(
      width: width,
      height: width * 460 / 840,
      child: ClipRect(
        child: Transform.translate(
          offset: Offset(0, width * 30 / 840),
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
