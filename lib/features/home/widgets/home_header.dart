import 'package:flutter/material.dart';

import '../theme/home_theme.dart';
import 'brand_backdrop.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.name,
    required this.tier,
    required this.address,
    required this.vehicle,
    required this.onLocation,
    required this.onVehicle,
    required this.onSearch,
  });

  final String name;
  final String tier;
  final String address;
  final String vehicle;
  final VoidCallback onLocation;
  final VoidCallback onVehicle;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final topInset = MediaQuery.paddingOf(context).top;
    final headerHeight = topInset + 146 + (scale - 1) * 70;
    final boxHeight = 132 + (scale - 1) * 54;
    return SizedBox(
      height: headerHeight + boxHeight,
      child: Stack(
        children: [
          SizedBox(
            height: headerHeight + boxHeight * 0.3,
            width: double.infinity,
            child: const BrandBackdrop(child: SizedBox.expand()),
          ),
          Positioned(
            top: topInset + 40,
            left: 20,
            right: 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chào $name',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HomeColors.text,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: HomeColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                tier,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: HomeColors.text,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tìm kiếm',
                  onPressed: onSearch,
                  icon: const Icon(
                    Icons.search_rounded,
                    color: HomeColors.text,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: headerHeight,
            left: 16,
            right: 16,
            height: boxHeight,
            child: Container(
              key: const ValueKey('home-emergency-context'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: HomeColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [HomeColors.shadow],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: HomeColors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Vị trí sự cố: $address',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onLocation,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          child: const Text(
                            'Sửa vị trí',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onVehicle,
                        borderRadius: BorderRadius.circular(12),
                        child: Semantics(
                          button: true,
                          label: 'Đổi xe khẩn cấp',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.two_wheeler_rounded,
                                color: HomeColors.primary,
                                size: 26,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'XE KHẨN CẤP',
                                      style: TextStyle(
                                        color: HomeColors.secondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      vehicle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: HomeColors.secondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
