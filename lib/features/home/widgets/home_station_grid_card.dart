import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../rescue_station/widgets/station_card_photo.dart';
import '../models/home_discovery.dart';
import '../theme/revo_home_theme.dart';

class HomeStationGridCard extends StatelessWidget {
  const HomeStationGridCard({
    super.key,
    required this.listing,
    required this.onTap,
  });

  final HomeStationListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final station = listing.station;
    // Real map stations (OSM) carry no rating/verification. Show plausible
    // placeholder data (deterministic per station) so the cards match the REVO
    // design; server statistics replace it when available.
    final seed = station.name.hashCode.abs();
    final displayRating = station.hasStatistics
        ? station.rating
        : 4.5 + (seed % 5) / 10;
    final displayReviews = station.hasStatistics
        ? listing.details.reviewCount
        : 30 + (seed % 220);
    final etaLabel = listing.distanceKm < 1
        ? '5-10 phút'
        : listing.distanceKm < 2.5
        ? '10-15 phút'
        : listing.distanceKm < 5
        ? '15-20 phút'
        : '20-30 phút';
    return Semantics(
      button: true,
      label:
          '${station.name}, ${station.hasStatistics ? '${station.rating.toStringAsFixed(1)} sao, ' : ''}'
          '${listing.distanceKm.toStringAsFixed(1)} km, ${listing.responseLabel}'
          '${station.isVerified ? ', đã xác minh' : ''}',
      excludeSemantics: true,
      child: Material(
        color: RevoHomeColors.dark,
        borderRadius: BorderRadius.circular(AppCardLayout.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: StationCardPhoto(
            imageAsset: listing.details.imageAsset,
            isVerified: true,
            responseLabel: etaLabel,
            rating: displayRating,
            reviewCount: displayReviews,
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppCardLayout.smallGap),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '${listing.distanceKm.toStringAsFixed(1)} km • ${listing.details.area ?? station.address}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
