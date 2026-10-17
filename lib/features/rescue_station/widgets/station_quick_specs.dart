import 'package:flutter/material.dart';

import '../models/station_model.dart';
import '../theme/station_detail_theme.dart';

class StationQuickSpecs extends StatelessWidget {
  const StationQuickSpecs({
    super.key,
    required this.station,
    required this.onReviews,
  });

  final StationModel station;
  final VoidCallback onReviews;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth < 320 ||
              MediaQuery.textScalerOf(context).scale(12) > 15
          ? 2
          : 4;
      final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
      final specs = [
        (
          Icons.star_rounded,
          StationDetailColors.yellow,
          station.station.hasStatistics
              ? '${station.rating.toStringAsFixed(1)}${station.reviewCount == null ? '' : ' (${station.reviewCount})'}'
              : 'Chưa có',
          'Đánh giá',
        ),
        (
          Icons.bolt_rounded,
          StationDetailColors.red,
          station.responseLabel,
          'Tốc độ',
        ),
        (
          Icons.handyman_outlined,
          StationDetailColors.text,
          station.mechanicCount == null
              ? 'Liên hệ'
              : '${station.mechanicCount} Thợ',
          'Đội ngũ',
        ),
        (
          Icons.verified_user_outlined,
          StationDetailColors.text,
          station.warrantyLabel ?? 'Liên hệ',
          'Cam kết',
        ),
      ];
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var index = 0; index < specs.length; index++)
            SizedBox(
              width: width,
              child: Material(
                color: StationDetailColors.surface,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: index == 0 ? const ValueKey('station-reviews') : null,
                  onTap: index == 0 && station.station.hasStatistics
                      ? onReviews
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 15,
                    ),
                    child: Column(
                      children: [
                        Icon(specs[index].$1, color: specs[index].$2, size: 23),
                        const SizedBox(height: 9),
                        Text(
                          specs[index].$3,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: StationDetailColors.text,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          specs[index].$4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            color: StationDetailColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
