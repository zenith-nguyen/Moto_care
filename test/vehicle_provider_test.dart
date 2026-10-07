import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/vehicle/models/vehicle.dart';
import 'package:moto_care/features/vehicle/providers/vehicle_provider.dart';

const _seed = Vehicle(
  id: 'original',
  name: 'Wave đi làm',
  brand: 'Honda',
  licensePlate: '59-X1 123.45',
  tireType: TireType.tubed,
  engineType: EngineType.gas,
  isDefault: true,
  color: 'Đỏ',
);

ProviderContainer _container({List<Vehicle> seed = const []}) {
  final container = ProviderContainer(
    overrides: [initialVehiclesProvider.overrideWithValue(seed)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'Vehicle JSON preserves all fields and rejects unsupported specifications',
    () {
      final json = _seed.toJson();
      expect(json['tireType'], 'tubed');
      expect(json['engineType'], 'gas');
      expect(Vehicle.fromJson(json).toJson(), json);
      expect(_seed.copyWith(engineType: EngineType.electric).id, _seed.id);
      expect(
        () => Vehicle.fromJson({...json, 'tireType': 'unknown'}),
        throwsFormatException,
      );
      expect(
        () => Vehicle.fromJson({...json, 'engineType': 'diesel'}),
        throwsFormatException,
      );
    },
  );

  test(
    'First vehicle becomes default; edits preserve identity and default status',
    () {
      final container = _container();
      final controller = container.read(vehicleProvider.notifier);
      expect(container.read(defaultVehicleProvider), isNull);
      final first = controller.save(
        name: '  Wave đi làm  ',
        brand: 'Honda',
        licensePlate: ' 59-x1 123.45 ',
        tireType: TireType.tubed,
        engineType: EngineType.gas,
        color: ' Đỏ ',
      );
      final second = controller.save(
        name: 'Feliz',
        brand: 'VinFast',
        licensePlate: '59-MD1 222.22',
        tireType: TireType.tubeless,
        engineType: EngineType.electric,
      );
      expect(first.isDefault, isTrue);
      expect(second.isDefault, isFalse);
      expect(first.name, 'Wave đi làm');
      expect(first.licensePlate, '59-X1 123.45');
      expect(first.color, 'Đỏ');
      final updated = controller.save(
        id: first.id,
        name: 'Wave mới',
        brand: 'Honda',
        licensePlate: first.licensePlate,
        tireType: TireType.tubeless,
        engineType: EngineType.gas,
        color: 'Xanh',
      );
      expect(container.read(vehicleProvider), hasLength(2));
      expect(container.read(defaultVehicleProvider)!.id, first.id);
      expect(updated.isDefault, isTrue);
      expect(first.name, 'Wave đi làm');
    },
  );

  test('Duplicate plates and invalid edits leave the session unchanged', () {
    final container = _container(seed: [_seed]);
    final controller = container.read(vehicleProvider.notifier);
    final original = container.read(vehicleProvider);
    expect(
      () => controller.save(
        name: 'Xe trùng',
        brand: 'Honda',
        licensePlate: '59x112345',
        tireType: TireType.tubed,
        engineType: EngineType.gas,
      ),
      throwsA(isA<VehicleSaveException>()),
    );
    expect(
      () => controller.save(
        id: 'missing',
        name: 'Xe',
        brand: 'Honda',
        licensePlate: '59-X2 222.22',
        tireType: TireType.tubed,
        engineType: EngineType.gas,
      ),
      throwsA(isA<VehicleSaveException>()),
    );
    expect(
      () => controller.save(
        name: ' ',
        brand: 'Honda',
        licensePlate: '59-X2 222.22',
        tireType: TireType.tubed,
        engineType: EngineType.gas,
      ),
      throwsA(isA<VehicleSaveException>()),
    );
    expect(container.read(vehicleProvider), same(original));
  });

  test('Default switching and deleting always retain exactly one default until empty', () {
    final container = _container(seed: [_seed]);
    final controller = container.read(vehicleProvider.notifier);
    final second = controller.save(
      name: 'Feliz',
      brand: 'VinFast',
      licensePlate: '59-MD1 222.22',
      tireType: TireType.tubeless,
      engineType: EngineType.electric,
    );
    expect(controller.setDefault(second.id), isTrue);
    expect(
      container.read(vehicleProvider).where((v) => v.isDefault),
      hasLength(1),
    );
    expect(container.read(defaultVehicleProvider)!.id, second.id);
    expect(controller.delete(second.id), isTrue);
    expect(container.read(defaultVehicleProvider)!.id, _seed.id);
    expect(controller.setDefault('missing'), isFalse);
    expect(controller.delete('missing'), isFalse);
    expect(
      () => container.read(vehicleProvider).clear(),
      throwsUnsupportedError,
    );
    expect(controller.delete(_seed.id), isTrue);
    expect(container.read(vehicleProvider), isEmpty);
    expect(container.read(defaultVehicleProvider), isNull);
  });

  test('Seed normalization respects an existing default and leaves input immutable', () {
    final first = _seed.copyWith(isDefault: false);
    final second = Vehicle(
      id: 'second',
      name: 'Xe điện',
      brand: 'VinFast',
      licensePlate: '59-MD1 222.22',
      tireType: TireType.tubeless,
      engineType: EngineType.electric,
      isDefault: true,
    );
    final container = _container(seed: [first, second]);
    expect(container.read(defaultVehicleProvider)!.id, 'second');
    expect(first.isDefault, isFalse);
    expect(
      container.read(vehicleProvider).where((v) => v.isDefault),
      hasLength(1),
    );
  });
}
