import 'package:flutter/material.dart';

import '../models/station_model.dart';
import '../theme/station_detail_theme.dart';
import 'station_services_catalog.dart';

class StationServicesSection extends StatelessWidget {
  const StationServicesSection({super.key, required this.station});
  final StationModel station;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Giới thiệu',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: StationDetailColors.text,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        station.description,
        style: const TextStyle(
          fontSize: 13,
          height: 1.8,
          color: StationDetailColors.muted,
        ),
      ),
      const SizedBox(height: 28),
      StationServicesCatalog(services: station.serviceCatalog),
    ],
  );
}
