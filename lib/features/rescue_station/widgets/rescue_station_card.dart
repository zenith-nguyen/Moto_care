import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/service_scaffold.dart';
import '../models/rescue_station.dart';
import '../services/rescue_station_actions.dart';

class RescueStationCard extends ConsumerWidget {
  const RescueStationCard({super.key, required this.station});
  final RescueStation station;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                station.stationType == StationType.mobileTeam
                    ? Icons.local_shipping_outlined
                    : Icons.garage_outlined,
                color: ServiceColors.orange,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  station.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            station.stationType.label,
            style: const TextStyle(color: ServiceColors.orange),
          ),
          const SizedBox(height: 6),
          Text(
            station.address,
            style: const TextStyle(color: ServiceColors.muted, height: 1.4),
          ),
          if (station.isVerified) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Color(0xFF218653), size: 18),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Xác thực MotoCare',
                      style: TextStyle(
                        color: Color(0xFF218653),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: ServiceColors.gold,
                    size: 22,
                  ),
                  const SizedBox(width: 4),
                  Text(station.rating.toStringAsFixed(1)),
                ],
              ),
              Text('${station.completedRescues} ca cứu hộ thành công'),
              Text('${station.distanceKm.toStringAsFixed(1)} km'),
              Text(
                station.isOpen
                    ? (station.isOpen24h ? 'Mở cửa • 24/7' : 'Mở cửa')
                    : 'Đóng cửa',
                style: TextStyle(
                  color: station.isOpen
                      ? const Color(0xFF218653)
                      : const Color(0xFFC53935),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final buttons = [
                OutlinedButton.icon(
                  onPressed: () =>
                      RescueStationActions.directions(context, ref, station),
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('Chỉ đường'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ServiceColors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () =>
                      RescueStationActions.call(context, ref, station),
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Gọi ngay'),
                ),
              ];
              if (constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buttons[0],
                    const SizedBox(height: 10),
                    buttons[1],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: buttons[0]),
                  const SizedBox(width: 12),
                  Expanded(child: buttons[1]),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
