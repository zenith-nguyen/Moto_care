import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vehicle.dart';
import '../models/vehicle_validation.dart';

final initialVehiclesProvider = Provider<List<Vehicle>>((ref) => const []);
final vehicleProvider = NotifierProvider<VehicleController, List<Vehicle>>(
  VehicleController.new,
);
final defaultVehicleProvider = Provider<Vehicle?>((ref) {
  for (final vehicle in ref.watch(vehicleProvider)) {
    if (vehicle.isDefault) return vehicle;
  }
  return null;
});

class VehicleSaveException implements Exception {
  const VehicleSaveException(this.message);
  final String message;
}

/// Session store. An authenticated repository can replace this boundary later.
class VehicleController extends Notifier<List<Vehicle>> {
  int _sequence = 0;

  @override
  List<Vehicle> build() {
    final vehicles = ref.watch(initialVehiclesProvider);
    if (vehicles.isEmpty) return const [];
    final defaultId = vehicles
        .firstWhere(
          (vehicle) => vehicle.isDefault,
          orElse: () => vehicles.first,
        )
        .id;
    return List.unmodifiable([
      for (final vehicle in vehicles)
        vehicle.copyWith(isDefault: vehicle.id == defaultId),
    ]);
  }

  String? duplicatePlateError(String plate, {String? excludingId}) {
    final key = VehicleValidation.plateKey(plate);
    return state.any(
          (vehicle) =>
              vehicle.id != excludingId &&
              VehicleValidation.plateKey(vehicle.licensePlate) == key,
        )
        ? 'Biển số này đã có trong danh sách xe.'
        : null;
  }

  Vehicle save({
    String? id,
    required String name,
    required String brand,
    required String licensePlate,
    required TireType tireType,
    required EngineType engineType,
    String color = '',
  }) {
    final error =
        VehicleValidation.name(name) ??
        VehicleValidation.licensePlate(licensePlate) ??
        duplicatePlateError(licensePlate, excludingId: id);
    if (error != null) throw VehicleSaveException(error);
    if (brand.trim().isEmpty ||
        brand.trim().length > 60 ||
        color.trim().length > 40) {
      throw const VehicleSaveException('Vui lòng kiểm tra hãng xe và màu xe.');
    }
    final index = id == null
        ? -1
        : state.indexWhere((vehicle) => vehicle.id == id);
    if (id != null && index == -1) {
      throw const VehicleSaveException('Xe không còn trong danh sách.');
    }
    final vehicle = Vehicle(
      id:
          id ??
          'vehicle-${DateTime.now().microsecondsSinceEpoch}-${++_sequence}',
      name: name.trim(),
      brand: brand.trim(),
      licensePlate: VehicleValidation.normalizePlate(licensePlate),
      tireType: tireType,
      engineType: engineType,
      isDefault: index == -1 ? state.isEmpty : state[index].isDefault,
      color: color.trim(),
    );
    state = List.unmodifiable(
      index == -1
          ? [...state, vehicle]
          : [
              for (final existing in state)
                existing.id == id ? vehicle : existing,
            ],
    );
    return vehicle;
  }

  bool setDefault(String id) {
    if (!state.any((vehicle) => vehicle.id == id)) return false;
    state = List.unmodifiable([
      for (final vehicle in state)
        vehicle.copyWith(isDefault: vehicle.id == id),
    ]);
    return true;
  }

  bool delete(String id) {
    if (!state.any((vehicle) => vehicle.id == id)) return false;
    final remaining = state.where((vehicle) => vehicle.id != id).toList();
    if (remaining.isNotEmpty &&
        !remaining.any((vehicle) => vehicle.isDefault)) {
      remaining[0] = remaining.first.copyWith(isDefault: true);
    }
    state = List.unmodifiable(remaining);
    return true;
  }
}
