import 'package:flutter/material.dart';

import '../models/service_rating.dart';
import '../theme/service_rating_theme.dart';

class ServiceRatingSummaryCard extends StatelessWidget {
  const ServiceRatingSummaryCard({super.key, required this.summary});
  final ServiceRatingSummary summary;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ServiceRatingColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFE9EBEF),
              child: Text(
                summary.initials,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ServiceRatingColors.text,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.mechanicName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ServiceRatingColors.text,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    summary.shopName,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: ServiceRatingColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          summary.serviceAndPrice,
          key: const ValueKey('service-rating-summary'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: ServiceRatingColors.text,
          ),
        ),
      ],
    ),
  );
}
