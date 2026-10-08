import 'package:flutter/material.dart';

import '../../../core/widgets/service_scaffold.dart';
import '../models/vehicle.dart';

enum VehicleAction { setDefault, edit, delete }

class VehicleCard extends StatelessWidget {
  const VehicleCard({super.key, required this.vehicle, required this.onAction});
  final Vehicle vehicle;
  final ValueChanged<VehicleAction> onAction;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.two_wheeler_rounded,
                color: ServiceColors.orange,
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.brand,
                      style: const TextStyle(color: ServiceColors.muted),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<VehicleAction>(
                tooltip: 'Tùy chọn xe ${vehicle.name}',
                onSelected: onAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: VehicleAction.setDefault,
                    enabled: !vehicle.isDefault,
                    child: const Text('Đặt làm mặc định'),
                  ),
                  const PopupMenuItem(
                    value: VehicleAction.edit,
                    child: Text('Chỉnh sửa'),
                  ),
                  const PopupMenuItem(
                    value: VehicleAction.delete,
                    child: Text('Xóa'),
                  ),
                ],
              ),
            ],
          ),
          if (vehicle.isDefault) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: ServiceColors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Mặc định cứu hộ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Semantics(
            label: 'Biển số xe ${vehicle.licensePlate}',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                vehicle.licensePlate,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.tire_repair, size: 18),
                label: Text(vehicle.tireType.label),
              ),
              Chip(
                avatar: Icon(
                  vehicle.engineType == EngineType.electric
                      ? Icons.bolt
                      : Icons.local_gas_station_outlined,
                  size: 18,
                ),
                label: Text(vehicle.engineType.label),
              ),
            ],
          ),
          if (vehicle.color.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Màu: ${vehicle.color}',
                style: const TextStyle(color: ServiceColors.muted),
              ),
            ),
        ],
      ),
    ),
  );
}
