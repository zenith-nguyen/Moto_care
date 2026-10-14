import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rescue_station/models/rescue_station.dart';
import '../models/rescue_location.dart';
import '../providers/home_provider.dart';
import '../theme/home_theme.dart';

class HomeNearbySection extends ConsumerWidget {
  const HomeNearbySection({
    super.key,
    required this.stations,
    required this.location,
    required this.onViewAll,
    required this.onStation,
  });
  final List<RescueStation> stations;
  final RescueLocation? location;
  final VoidCallback onViewAll;
  final ValueChanged<RescueStation> onStation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Cứu hộ nhanh gần đây',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text('Xem tất cả ›', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const Text(
          'Trạm tham khảo • Kiểm tra khả dụng trước khi gọi',
          style: TextStyle(color: HomeColors.secondary, fontSize: 11),
        ),
        const SizedBox(height: 12),
        if (stations.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HomeColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Chưa có trạm cứu hộ trong khu vực.',
              style: TextStyle(color: HomeColors.secondary),
            ),
          )
        else
          SizedBox(
            height: 198 + (scale - 1) * 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: stations.length,
              itemBuilder: (context, index) {
                final station = stations[index];
                final distance = ref.watch(stationDistanceProvider(station));
                return Container(
                  width: 232,
                  margin: const EdgeInsets.only(right: 12, bottom: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [HomeColors.shadow],
                  ),
                  child: Material(
                    color: HomeColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onStation(station),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: HomeColors.redSelected,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.home_repair_service_rounded,
                                    size: 24,
                                    color: HomeColors.red,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.star_rounded,
                                  color: HomeColors.red,
                                  size: 16,
                                ),
                                Text(
                                  ' ${station.rating.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              station.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${distance.toStringAsFixed(1)} km${location?.hasCoordinates == true ? ' • Đường chim bay' : ' • Tham khảo'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: HomeColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              station.isOpen24h
                                  ? 'Mở cửa 24/7'
                                  : station.isOpen
                                  ? 'Đang mở cửa'
                                  : 'Đang đóng cửa',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: station.isOpen
                                    ? HomeColors.red
                                    : HomeColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
