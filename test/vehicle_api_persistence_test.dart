import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/app_dependencies.dart';
import 'package:moto_care/features/auth/application/session_controller.dart';
import 'package:moto_care/features/auth/application/session_state.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';
import 'package:moto_care/features/auth/domain/auth_session.dart';
import 'package:moto_care/features/vehicle/data/vehicle_repository.dart';
import 'package:moto_care/features/vehicle/models/vehicle.dart';
import 'package:moto_care/features/vehicle/providers/vehicle_provider.dart';

import 'support/recording_json_api.dart';

const _vehicle = Vehicle(
  id: '1',
  name: 'Wave đi làm',
  brand: 'Honda',
  licensePlate: '59-X1 123.45',
  tireType: TireType.tubeless,
  engineType: EngineType.gas,
  isDefault: true,
);

class _CustomerSession extends SessionController {
  @override
  SessionState build() => SessionSignedIn(
    AuthSession(
      accessToken: 'test',
      user: const AppUser(
        id: 7,
        name: 'Customer',
        email: 'customer@example.test',
        phone: null,
        role: AppRole.customer,
        status: AppUserStatus.active,
      ),
    ),
  );
}

class _Vehicles implements VehicleRepository {
  final values = <Vehicle>[];
  bool failSave = false;

  @override
  Future<List<Vehicle>> list() async => List.of(values);

  @override
  Future<Vehicle> save(Vehicle vehicle, {bool create = false}) async {
    if (failSave) throw StateError('server unavailable');
    final result = create
        ? Vehicle(
            id: '${values.length + 1}',
            name: vehicle.name,
            brand: vehicle.brand,
            licensePlate: vehicle.licensePlate,
            tireType: vehicle.tireType,
            engineType: vehicle.engineType,
            isDefault: vehicle.isDefault,
            color: vehicle.color,
          )
        : vehicle;
    values.removeWhere((item) => item.id == result.id);
    values.add(result);
    return result;
  }

  @override
  Future<Vehicle> setDefault(String id) async {
    final result = values.firstWhere((vehicle) => vehicle.id == id);
    for (var index = 0; index < values.length; index++) {
      values[index] = values[index].copyWith(isDefault: values[index].id == id);
    }
    return result.copyWith(isDefault: true);
  }

  @override
  Future<void> delete(String id) async {
    values.removeWhere((item) => item.id == id);
  }
}

void main() {
  test('vehicle API keeps specifications and normalizes the plate', () async {
    final api = RecordingJsonApi()
      ..objectResponse = {
        'id': 1,
        'type': 'MOTORBIKE',
        'brand': 'Honda',
        'model': 'Wave đi làm',
        'licensePlate': '59-X1123.45',
        'color': null,
        'tireType': 'tubeless',
        'engineType': 'gas',
        'isDefault': true,
      };
    final repository = HttpVehicleRepository(api);
    final saved = await repository.save(_vehicle, create: true);
    expect(api.lastMethod, 'POST');
    expect(api.lastPath, '/users/me/vehicles');
    expect(
      (api.lastData as Map<String, dynamic>)['licensePlate'],
      '59-X1123.45',
    );
    expect((api.lastData as Map<String, dynamic>)['tireType'], 'tubeless');
    expect(saved.tireType, TireType.tubeless);
    expect(saved.isDefault, isTrue);
    await repository.save(saved);
    expect(api.lastMethod, 'PATCH');
    expect(api.lastPath, '/users/me/vehicles/1');
    expect((api.lastData as Map<String, dynamic>).containsKey('type'), isFalse);
  });

  test(
    'saved vehicles reload after a new app session; failed save is not shown',
    () async {
      final repository = _Vehicles();
      ProviderContainer container() => ProviderContainer(
        overrides: [
          runtimeApiIntegrationProvider.overrideWithValue(true),
          sessionControllerProvider.overrideWith(_CustomerSession.new),
          vehicleRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final first = container();
      await first.read(vehicleProvider.notifier).refreshFromApi('7');
      await first
          .read(vehicleProvider.notifier)
          .savePersisted(
            name: _vehicle.name,
            brand: _vehicle.brand,
            licensePlate: _vehicle.licensePlate,
            tireType: _vehicle.tireType,
            engineType: _vehicle.engineType,
          );
      expect(first.read(defaultVehicleProvider)?.name, _vehicle.name);
      first.dispose();

      final second = container();
      addTearDown(second.dispose);
      await second.read(vehicleProvider.notifier).refreshFromApi('7');
      expect(second.read(defaultVehicleProvider)?.tireType, TireType.tubeless);
      repository.failSave = true;
      await expectLater(
        second
            .read(vehicleProvider.notifier)
            .savePersisted(
              name: 'Feliz',
              brand: 'VinFast',
              licensePlate: '59-MD1 222.22',
              tireType: TireType.tubeless,
              engineType: EngineType.electric,
            ),
        throwsStateError,
      );
      expect(second.read(vehicleProvider), hasLength(1));
    },
  );
}
