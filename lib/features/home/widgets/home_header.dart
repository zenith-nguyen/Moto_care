import 'package:flutter/material.dart';

import '../theme/home_theme.dart';
import 'brand_backdrop.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.name,
    required this.address,
    required this.vehicle,
    required this.onLocation,
    required this.onVehicle,
  });

  final String name;
  final String address;
  final String vehicle;
  final VoidCallback onLocation;
  final VoidCallback onVehicle;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final topInset = MediaQuery.paddingOf(context).top;
    final headerHeight = topInset + 110 + (scale - 1) * 70;
    final boxHeight = 132 + (scale - 1) * 54;
    return SizedBox(
      height: headerHeight + boxHeight,
      child: Stack(
        children: [
          SizedBox(
            height: headerHeight + boxHeight,
            width: double.infinity,
            child: const BrandBackdrop(
              colors: [
                Color(0xFFF09A9E),
                Color(0xFFF8CFD1),
                HomeColors.background,
              ],
              child: SizedBox.expand(),
            ),
          ),
          Positioned(
            top: topInset + 40,
            left: 20,
            right: 20,
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
                    ],
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
                                color: HomeColors.red,
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
