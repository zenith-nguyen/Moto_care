import '../../../core/network/json_api.dart';
import '../models/vehicle.dart';
import '../models/vehicle_validation.dart';

abstract interface class VehicleRepository {
  Future<List<Vehicle>> list();
  Future<Vehicle> save(Vehicle vehicle, {bool create = false});
  Future<Vehicle> setDefault(String id);
  Future<void> delete(String id);
}

class HttpVehicleRepository implements VehicleRepository {
  const HttpVehicleRepository(this._api);

  final JsonApi _api;
  static const _path = '/users/me/vehicles';

  @override
  Future<List<Vehicle>> list() async => [
    for (final json in await _api.getList(_path)) Vehicle.fromApiJson(json),
  ];

  @override
  Future<Vehicle> save(Vehicle vehicle, {bool create = false}) async {
    final data = {
      if (create)
        'type': vehicle.engineType == EngineType.electric
            ? 'ELECTRIC_MOTORBIKE'
            : 'MOTORBIKE',
      'brand': vehicle.brand,
      'model': vehicle.name,
      'licensePlate': VehicleValidation.normalizePlateForApi(
        vehicle.licensePlate,
      ),
      'color': vehicle.color.isEmpty ? null : vehicle.color,
      'tireType': vehicle.tireType.value,
      'engineType': vehicle.engineType.value,
      if (create) 'isDefault': vehicle.isDefault,
    };
    final json = create
        ? await _api.postObject(_path, data: data)
        : await _api.patchObject('$_path/${vehicle.id}', data: data);
    return Vehicle.fromApiJson(json);
  }

  @override
  Future<Vehicle> setDefault(String id) async => Vehicle.fromApiJson(
    await _api.patchObject('$_path/$id', data: {'isDefault': true}),
  );

  @override
  Future<void> delete(String id) async {
    await _api.deleteObject('$_path/$id');
  }
}
