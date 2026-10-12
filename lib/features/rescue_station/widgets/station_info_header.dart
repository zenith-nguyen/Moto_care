import 'package:flutter/material.dart';

import '../models/station_model.dart';
import '../theme/station_detail_theme.dart';

class StationInfoHeader extends StatelessWidget {
  const StationInfoHeader({
    super.key,
    required this.station,
    required this.onDirections,
  });

  final StationModel station;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          station.name,
          key: const ValueKey('station-name'),
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            height: 1.3,
            color: StationDetailColors.text,
          ),
        ),
        if (station.isVerified) ...[
          const SizedBox(height: 10),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_rounded,
                size: 17,
                color: StationDetailColors.verified,
              ),
              SizedBox(width: 5),
              Text(
                'Đã xác minh',
                style: TextStyle(
                  color: StationDetailColors.verified,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 7,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 7,
                  color: station.isOpen
                      ? StationDetailColors.green
                      : StationDetailColors.muted,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    station.openingLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: station.isOpen
                          ? StationDetailColors.green
                          : StationDetailColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '• Cách bạn ${station.distanceKm.toStringAsFixed(1)} km'
              '${station.isOpen && station.responseMinutes != null ? ' (${station.responseLabel})' : ''}',
              style: const TextStyle(
                fontSize: 11,
                color: StationDetailColors.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          key: const ValueKey('station-address'),
          onTap: onDirections,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: StationDetailColors.muted,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    station.address,
                    style: const TextStyle(
                      fontSize: 12,
                      color: StationDetailColors.muted,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.north_east_rounded,
                  color: StationDetailColors.muted,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
