import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/incidents/data/incident_types_repository.dart';

import '../../support/recording_json_api.dart';

void main() {
  test('loads active incident options with decimal base prices', () async {
    final api = RecordingJsonApi()
      ..listResponse = [
        {
          'id': 1,
          'code': 'FLAT_TIRE',
          'name': 'Xẹp lốp',
          'basePrice': '100000.00',
        },
      ];
    final repository = HttpIncidentTypesRepository(api);

    final items = await repository.listActive();

    expect(api.lastPath, '/incident-types');
    expect(items.single.code, 'FLAT_TIRE');
    expect(items.single.basePrice.value, '100000.00');
  });

  test('rejects floating-point money from the incident catalog', () async {
    final api = RecordingJsonApi()
      ..listResponse = [
        {
          'id': 1,
          'code': 'FLAT_TIRE',
          'name': 'Xẹp lốp',
          'basePrice': 100000.0,
        },
      ];

    await expectLater(
      HttpIncidentTypesRepository(api).listActive(),
      throwsFormatException,
    );
  });
}
