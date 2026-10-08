import 'package:flutter/material.dart';

import '../../rescue_station/models/rescue_station.dart';
import '../models/rescue_location.dart';
import '../providers/home_provider.dart';
import '../theme/home_theme.dart';

class HomeClubCard extends StatelessWidget {
  const HomeClubCard({
    super.key,
    required this.points,
    required this.onPressed,
    this.tier = 'Quyền lợi ưu tiên cứu hộ đêm',
    this.actionLabel = 'Quyền lợi ›',
    this.accentColor = HomeColors.primary,
    this.gradientColors = const [HomeColors.tint, HomeColors.selected],
  });
  final int points;
  final VoidCallback onPressed;
  final String tier;
  final String actionLabel;
  final Color accentColor;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: gradientColors),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: accentColor.withValues(alpha: 0.18)),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'MotoCare Club',
                      style: TextStyle(
                        color: HomeColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, size: 18, color: accentColor),
                      const SizedBox(width: 5),
                      Text(
                        '$points xu',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tier,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    actionLabel,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

class HomeNearbySection extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                final distance = stationDistanceKm(station, location);
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

class HomeOffersSection extends StatelessWidget {
  const HomeOffersSection({
    super.key,
    required this.onVouchers,
    required this.onTips,
  });
  final VoidCallback onVouchers;
  final VoidCallback onTips;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onVouchers,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Mẹo hay & Ưu đãi hôm nay ›',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _OfferBanner(
                title: 'Giảm 30k\ncứu hộ đêm',
                caption: 'Ưu đãi mẫu • Xem điều kiện',
                icon: Icons.nights_stay_rounded,
                colors: const [HomeColors.tintStrong, HomeColors.tint],
                iconColor: HomeColors.red,
                height: 146 + (scale - 1) * 70,
                onPressed: onVouchers,
              ),
              const SizedBox(width: 12),
              _OfferBanner(
                title: 'Xe chết máy\nmùa mưa?',
                caption: 'Mẹo xử lý an toàn',
                icon: Icons.umbrella_rounded,
                colors: const [HomeColors.tintStrong, HomeColors.tint],
                iconColor: HomeColors.red,
                height: 146 + (scale - 1) * 70,
                onPressed: onTips,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OfferBanner extends StatelessWidget {
  const _OfferBanner({
    required this.title,
    required this.caption,
    required this.icon,
    required this.colors,
    required this.iconColor,
    required this.height,
    required this.onPressed,
  });
  final String title;
  final String caption;
  final IconData icon;
  final List<Color> colors;
  final Color iconColor;
  final double height;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    width: 270,
    height: height,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: colors),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(icon, size: 48, color: iconColor),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                caption,
                style: const TextStyle(
                  fontSize: 11,
                  color: HomeColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
