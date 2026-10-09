import '../../../core/network/json_api.dart';
import '../domain/incident_type.dart';

abstract interface class IncidentTypesRepository {
  Future<List<IncidentType>> listActive();
}

class HttpIncidentTypesRepository implements IncidentTypesRepository {
  const HttpIncidentTypesRepository(this._api);

  final JsonApi _api;

  @override
  Future<List<IncidentType>> listActive() async {
    final response = await _api.getList('/incident-types');
    return response.map(IncidentType.fromJson).toList(growable: false);
  }
}
