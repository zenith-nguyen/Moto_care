import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/service_catalog_item.dart';
import '../theme/service_catalog_theme.dart';

class ServicePhotoCard extends StatelessWidget {
  const ServicePhotoCard({super.key, required this.item, required this.onTap});
  final ServiceCatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    excludeSemantics: true,
    button: true,
    onTap: onTap,
    label: '${item.title}. ${item.description}. ${item.responseLabel}',
    child: Material(
      color: const Color(0xFF172435),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            item.imageAsset,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.car_repair, size: 56, color: Colors.white54),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .25, .55, 1],
                colors: [
                  Color(0x33000000),
                  Color(0x0D000000),
                  Color(0x99000000),
                  Color(0xF5000000),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: _badge(item.badge, blue: true),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _badge(item.responseLabel),
                  ],
                ),
                const Spacer(),
                Text(
                  item.title,
                  style: AppTextStyles.cardTitle.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              excludeFromSemantics: true,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _badge(String label, {bool blue = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: blue ? ServiceCatalogTheme.blue : const Color(0xA64D5159),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      label,
      style: AppTextStyles.caption.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.3,
      ),
    ),
  );
}
