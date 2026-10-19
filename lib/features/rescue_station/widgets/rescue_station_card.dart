import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/data/home_station_details.dart';
import '../../home/models/home_discovery.dart';
import '../../home/providers/home_discovery_provider.dart';
import '../../home/theme/revo_home_theme.dart';
import '../models/rescue_station.dart';
import '../providers/station_details_provider.dart';
import '../services/rescue_station_actions.dart';
import 'station_card_photo.dart';

class RescueStationCard extends ConsumerWidget {
  const RescueStationCard({super.key, required this.station});
  final RescueStation station;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details =
        ref.watch(homeStationDetailsProvider)[station.id] ??
        defaultHomeStationDetails;
    final listing = HomeStationListing(
      station: station,
      services: const [],
      details: details,
      distanceKm: station.distanceKm,
    );
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppCardLayout.radius),
        side: const BorderSide(color: RevoHomeColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppCardLayout.radius),
        onTap: () {
          final model = ref.read(stationModelProvider(station.id));
          if (model == null) return;
          context.push(
            '/stations/${Uri.encodeComponent(model.id)}',
            extra: model,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppCardLayout.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 180 + (scale - 1) * 80,
                width: double.infinity,
                child: station.isMapDirectory
                    ? _MapDirectoryVisual(station: station)
                    : StationCardPhoto(
                        imageAsset: details.imageAsset,
                        isVerified: station.isVerified,
                        responseLabel: station.isOpen
                            ? listing.responseLabel
                            : null,
                        rating: station.hasStatistics ? station.rating : null,
                        reviewCount: station.hasStatistics
                            ? details.reviewCount
                            : null,
                        distanceKm: station.distanceKm,
                        showBadgeLabel: true,
                      ),
              ),
              const SizedBox(height: AppCardLayout.gap),
              Text(station.name, style: AppTextStyles.cardTitle),
              const SizedBox(height: AppCardLayout.smallGap),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    station.isMapDirectory
                        ? 'Dữ liệu địa điểm OpenStreetMap'
                        : station.stationType.label,
                    style: AppTextStyles.caption,
                  ),
                  if (station.isVerified)
                    Text(
                      'Xác thực MotoCare',
                      style: AppTextStyles.caption.copyWith(
                        color: RevoHomeColors.verified,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (station.isMapDirectory && !station.isVerified)
                    Text(
                      'Chưa xác minh đối tác',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppCardLayout.smallGap),
              Text(station.address, style: AppTextStyles.body),
              const SizedBox(height: AppCardLayout.smallGap),
              if (station.hasOperationalData)
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 7,
                      color: station.isOpen
                          ? const Color(0xFF218653)
                          : Colors.black54,
                    ),
                    const SizedBox(width: AppCardLayout.smallGap),
                    Expanded(
                      child: Text(
                        station.isOpen
                            ? (station.isOpen24h ? 'Mở cửa • 24/7' : 'Mở cửa')
                            : 'Đóng cửa',
                        style: AppTextStyles.status.copyWith(
                          color: station.isOpen
                              ? const Color(0xFF218653)
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              if (station.hasOperationalData)
                const SizedBox(height: AppCardLayout.smallGap),
              if (station.hasStatistics)
                Text(
                  '${station.completedRescues} ca cứu hộ thành công',
                  style: AppTextStyles.caption,
                ),
              const SizedBox(height: AppCardLayout.gap),
              _actions(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) {
      final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      );
      final textStyle = AppTextStyles.body.copyWith(
        fontWeight: FontWeight.bold,
      );
      final buttons = [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: RevoHomeColors.ink,
            side: const BorderSide(color: RevoHomeColors.border),
            minimumSize: const Size(48, 48),
            shape: shape,
            textStyle: textStyle,
          ),
          onPressed: () =>
              RescueStationActions.directions(context, ref, station),
          icon: const Icon(Icons.directions_outlined, size: 18),
          label: const Text('Chỉ đường'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A1A),
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            elevation: 0,
            shape: shape,
            textStyle: textStyle,
          ),
          onPressed: station.phoneNumber.isEmpty
              ? null
              : () => RescueStationActions.call(context, ref, station),
          icon: const Icon(Icons.phone_outlined, size: 18),
          label: const Text('Gọi ngay'),
        ),
      ];
      if (constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(14) > 20) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [buttons[0], const SizedBox(height: 10), buttons[1]],
        );
      }
      return Row(
        children: [
          Expanded(child: buttons[0]),
          const SizedBox(width: AppCardLayout.gap),
          Expanded(child: buttons[1]),
        ],
      );
    },
  );
}

class _MapDirectoryVisual extends StatelessWidget {
  const _MapDirectoryVisual({required this.station});

  final RescueStation station;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F4),
      borderRadius: BorderRadius.circular(AppCardLayout.radius),
      border: Border.all(color: RevoHomeColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 52, color: Color(0xFF245B53)),
          const SizedBox(height: 12),
          Text(
            station.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 8),
          Text(
            '${station.distanceKm.toStringAsFixed(1)} km • Thông tin bản đồ',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    ),
  );
}
