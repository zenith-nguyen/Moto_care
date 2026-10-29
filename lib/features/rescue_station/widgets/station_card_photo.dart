import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/theme/revo_home_theme.dart';

/// The same photo treatment for Home tiles and the station directory.
class StationCardPhoto extends StatelessWidget {
  const StationCardPhoto({
    super.key,
    required this.imageAsset,
    required this.isVerified,
    required this.rating,
    this.responseLabel,
    this.reviewCount,
    this.distanceKm,
    this.showBadgeLabel = false,
    this.footer,
  });

  final String imageAsset;
  final bool isVerified;
  final double? rating;
  final String? responseLabel;
  final int? reviewCount;
  final double? distanceKm;
  final bool showBadgeLabel;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppCardLayout.radius),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imageAsset,
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.35),
          errorBuilder: (_, _, _) => const ColoredBox(
            color: RevoHomeColors.dark,
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 48,
                color: Colors.white54,
              ),
            ),
          ),
          excludeFromSemantics: true,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x14000000),
                Color(0x00000000),
                Color(0xCC000000),
                Color(0xFF111111),
              ],
              stops: [0, .35, .65, 1],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppCardLayout.photoPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: AppCardLayout.smallGap,
                  runSpacing: AppCardLayout.smallGap,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    if (isVerified)
                      if (showBadgeLabel)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: RevoHomeColors.verified,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Xác thực',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Icon(
                          Icons.verified_rounded,
                          color: RevoHomeColors.verified,
                          size: 21,
                        ),
                    if (responseLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC5E5E62),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          responseLabel!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: AppTextStyles.body.copyWith(
                              color: RevoHomeColors.ink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (reviewCount != null && showBadgeLabel) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '($reviewCount đánh giá)',
                                style: AppTextStyles.caption,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (reviewCount != null && !showBadgeLabel)
                    Text(
                      '($reviewCount)',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  if (distanceKm != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${distanceKm!.toStringAsFixed(1)} km',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              if (footer != null) ...[
                const SizedBox(height: AppCardLayout.smallGap),
                footer!,
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
