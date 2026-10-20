import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/application/session_state.dart';
import '../data/vehicle_brands.dart';
import '../data/vehicle_repository.dart';
import '../models/vehicle.dart';
import '../models/vehicle_validation.dart';

final initialVehiclesProvider = Provider<List<Vehicle>>((ref) => const []);
final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => HttpVehicleRepository(ref.watch(jsonApiProvider)),
);
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

/// Local fixtures remain available in tests; production changes are persisted.
class VehicleController extends Notifier<List<Vehicle>> {
  int _sequence = 0;
  int _revision = 0;
  String? _loadedUserId;

  @override
  List<Vehicle> build() {
    if (ref.read(runtimeApiIntegrationProvider)) {
      ref.listen(sessionControllerProvider, (previous, next) {
        final userId = next is SessionSignedIn
            ? next.session.user.id.toString()
            : null;
        if (userId != _loadedUserId) clearSession();
      });
    }
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

  Future<void> refreshFromApi(String userId) async {
    if (!ref.read(runtimeApiIntegrationProvider)) return;
    final revision = ++_revision;
    if (_loadedUserId != userId) {
      _loadedUserId = userId;
      state = const [];
    }
    final vehicles = await ref.read(vehicleRepositoryProvider).list();
    if (ref.mounted && _loadedUserId == userId && _revision == revision) {
      state = List.unmodifiable(vehicles);
    }
  }

  Future<Vehicle> savePersisted({
    String? id,
    required String name,
    required String brand,
    required String licensePlate,
    required TireType tireType,
    required EngineType engineType,
    String color = '',
  }) async {
    if (!ref.read(runtimeApiIntegrationProvider)) {
      return save(
        id: id,
        name: name,
        brand: brand,
        licensePlate: licensePlate,
        tireType: tireType,
        engineType: engineType,
        color: color,
      );
    }
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
    if (id != null && !state.any((vehicle) => vehicle.id == id)) {
      throw const VehicleSaveException('Xe không còn trong danh sách.');
    }
    final draft = Vehicle(
      id: id ?? '',
      name: name.trim(),
      brand: brand.trim(),
      licensePlate: VehicleValidation.normalizePlate(licensePlate),
      tireType: tireType,
      engineType: engineType,
      color: color.trim(),
      isDefault: id == null
          ? state.isEmpty
          : state.firstWhere((v) => v.id == id).isDefault,
    );
    final userId = _loadedUserId;
    final saved = await ref
        .read(vehicleRepositoryProvider)
        .save(draft, create: id == null);
    if (ref.mounted && _loadedUserId == userId) {
      _revision++;
      state = List.unmodifiable([
        for (final vehicle in state)
          if (vehicle.id != saved.id) vehicle,
        saved,
      ]);
    }
    return saved;
  }

  Future<bool> setDefaultPersisted(String id) async {
    if (!ref.read(runtimeApiIntegrationProvider)) return setDefault(id);
    if (!state.any((vehicle) => vehicle.id == id)) return false;
    final userId = _loadedUserId;
    await ref.read(vehicleRepositoryProvider).setDefault(id);
    if (!ref.mounted || _loadedUserId != userId) return false;
    _revision++;
    return setDefault(id);
  }

  Future<bool> deletePersisted(String id) async {
    if (!ref.read(runtimeApiIntegrationProvider)) return delete(id);
    if (!state.any((vehicle) => vehicle.id == id)) return false;
    final userId = _loadedUserId;
    await ref.read(vehicleRepositoryProvider).delete(id);
    if (!ref.mounted || _loadedUserId != userId) return false;
    _revision++;
    return delete(id);
  }

  void clearSession() {
    _revision++;
    _loadedUserId = null;
    state = const [];
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

final vehicleBrandsProvider = Provider<List<String>>((ref) => vehicleBrands);
