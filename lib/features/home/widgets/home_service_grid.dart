import 'package:flutter/material.dart';

import '../models/home_service.dart';
export '../models/home_service.dart';
import '../theme/home_theme.dart';

class HomeServiceGrid extends StatelessWidget {
  const HomeServiceGrid({super.key, required this.onSelected});
  final ValueChanged<HomeService> onSelected;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisSpacing: 8,
      mainAxisSpacing: 10,
      mainAxisExtent: 108 + (scale - 1) * 55,
      children: [
        for (final service in HomeService.homeItems)
          ServiceTile(
            key: ValueKey('home-service-${service.name}'),
            label: service.label,
            icon: service.icon,
            color: service.color,
            onTap: () => onSelected(service),
          ),
      ],
    );
  }
}

class ServiceTile extends StatelessWidget {
  const ServiceTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = HomeColors.red,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: HomeColors.surface,
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
